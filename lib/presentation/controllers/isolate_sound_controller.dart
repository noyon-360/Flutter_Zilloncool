import 'dart:isolate';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game/constants/key_constants.dart';
import 'package:flutter/material.dart';

// Sound command types for isolate communication
enum SoundCommand {
  initialize,
  playDragStart,
  playDragStep,
  playDragEnd,
  playWordFound,
  playWordMatch,
  playLevelComplete,
  playHintActivate,
  playHintReveal,
  playGameRefresh,
  playInvalidSelection,
  playButtonSound,
  toggleMusic,
  toggleSound,
  setMusicVolume,
  setSoundVolume,
  setDragSoundVolume,
  resumeMusic,
  pauseMusic,
  dispose,
}

// Message structure for isolate communication
class SoundMessage {
  final SoundCommand command;
  final Map<String, dynamic>? data;
  final String? responseId;

  SoundMessage({
    required this.command,
    this.data,
    this.responseId,
  });

  Map<String, dynamic> toJson() => {
    'command': command.index,
    'data': data,
    'responseId': responseId,
  };

  factory SoundMessage.fromJson(Map<String, dynamic> json) => SoundMessage(
    command: SoundCommand.values[json['command']],
    data: json['data'],
    responseId: json['responseId'],
  );
}

// Response from isolate
class SoundResponse {
  final String responseId;
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  SoundResponse({
    required this.responseId,
    required this.success,
    this.data,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'responseId': responseId,
    'success': success,
    'data': data,
    'error': error,
  };

  factory SoundResponse.fromJson(Map<String, dynamic> json) => SoundResponse(
    responseId: json['responseId'],
    success: json['success'],
    data: json['data'],
    error: json['error'],
  );
}

class OptimizedSoundController {
  static final OptimizedSoundController _instance = OptimizedSoundController._internal();
  factory OptimizedSoundController() => _instance;
  OptimizedSoundController._internal();

  // Isolate communication
  Isolate? _soundIsolate;
  SendPort? _soundSendPort;
  ReceivePort? _soundReceivePort;
  final Map<String, Completer<SoundResponse>> _pendingResponses = {};
  bool _isolateInitialized = false;
  bool _initializationInProgress = false;

  // Fallback audio players (used when isolate fails)
  AudioPlayer? _fallbackMusicPlayer;
  AudioPlayer? _fallbackSoundPlayer;
  bool _useFallback = false;

  // ValueNotifiers for reactive state management
  final ValueNotifier<bool> musicEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> soundEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> hapticEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> musicPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> initializedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> draggingNotifier = ValueNotifier(false);

  // Performance monitoring
  final ValueNotifier<int> soundQueueLength = ValueNotifier(0);
  final ValueNotifier<double> averageResponseTime = ValueNotifier(0.0);
  
  // Queue management for rapid sound events
  final List<SoundMessage> _soundQueue = [];
  Timer? _queueProcessor;
  bool _isProcessingQueue = false;

  // Volume settings
  double _musicVolume = 0.6;
  double _soundVolume = 0.8;
  double _dragSoundVolume = 0.4;

  // Drag state
  int _currentDragStep = 0;

  // Audio file paths
  static const String _backgroundMusicPath = 'background_music.wav';
  static const String _buttonSoundPath = 'button_click.wav';
  static const String _dragStartPath = 'match_success.wav';
  static const String _dragStepPath = 'match_success.wav';
  static const String _wordMatchPath = 'match_success.wav';
  static const String _levelCompletePath = 'match_success.wav';
  static const String _hintActivatePath = 'match_success.wav';
  static const String _hintRevealPath = 'match_success.wav';
  static const String _gameRefreshPath = 'match_success.wav';
  static const String _invalidSelectionPath = 'match_success.wav';

  // Getters
  bool get isMusicEnabled => musicEnabledNotifier.value;
  bool get isSoundEnabled => soundEnabledNotifier.value;
  bool get isHapticEnabled => hapticEnabledNotifier.value;
  bool get isMusicPlaying => musicPlayingNotifier.value;
  bool get isInitialized => initializedNotifier.value;
  bool get isDragging => draggingNotifier.value;

  /// Initialize the optimized sound controller
  Future<void> initialize() async {
    if (initializedNotifier.value || _initializationInProgress) return;
    
    _initializationInProgress = true;
    
    try {
      DPrint.log('🎵 Initializing OptimizedSoundController...');
      
      // Load preferences first
      await _loadPreferences();
      
      // Try to initialize with isolate, fallback to main thread if it fails
      bool isolateSuccess = await _tryInitializeWithIsolate();
      
      if (!isolateSuccess) {
        DPrint.log('🔄 Isolate initialization failed, using fallback...');
        await _initializeFallback();
      }

      // Start queue processor
      _startQueueProcessor();

      initializedNotifier.value = true;
      DPrint.log('✅ OptimizedSoundController initialized successfully');
      
    } catch (e) {
      DPrint.log('❌ Error initializing OptimizedSoundController: $e');
      // Ensure fallback is initialized
      await _initializeFallback();
      initializedNotifier.value = true;
    } finally {
      _initializationInProgress = false;
    }
  }

  /// Try to initialize with isolate
  Future<bool> _tryInitializeWithIsolate() async {
    try {
      await _startSoundIsolate();
      
      // Test the isolate with a simple command
      final response = await _sendCommand(SoundCommand.initialize, {
        'musicEnabled': musicEnabledNotifier.value,
        'soundEnabled': soundEnabledNotifier.value,
        'musicVolume': _musicVolume,
        'soundVolume': _soundVolume,
        'dragSoundVolume': _dragSoundVolume,
      }).timeout(const Duration(seconds: 3));
      
      if (response.success) {
        _isolateInitialized = true;
        DPrint.log('✅ Sound isolate initialized successfully');
        return true;
      } else {
        DPrint.log('❌ Sound isolate initialization failed: ${response.error}');
        return false;
      }
    } catch (e) {
      DPrint.log('❌ Error initializing sound isolate: $e');
      await _cleanupIsolate();
      return false;
    }
  }

  /// Start the sound isolate
  Future<void> _startSoundIsolate() async {
    _soundReceivePort = ReceivePort();
    
    // Listen for messages from isolate
    _soundReceivePort!.listen(_handleIsolateMessage);
    
    // Spawn the isolate
    _soundIsolate = await Isolate.spawn(
      soundIsolateEntryPoint, // Top-level function
      _soundReceivePort!.sendPort,
    );
    
    // Wait for isolate to send back its SendPort
    final Completer<SendPort> completer = Completer<SendPort>();
    late StreamSubscription subscription;
    
    subscription = _soundReceivePort!.listen((message) {
      if (message is SendPort) {
        _soundSendPort = message;
        completer.complete(message);
        subscription.cancel();
      }
    });
    
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('Isolate SendPort timeout'),
    );
  }

  /// Handle messages from the sound isolate
  void _handleIsolateMessage(dynamic message) {
    try {
      if (message is Map<String, dynamic>) {
        if (message.containsKey('responseId')) {
          // Handle command response
          final response = SoundResponse.fromJson(message);
          final completer = _pendingResponses.remove(response.responseId);
          completer?.complete(response);
          
          // Update state based on response
          if (response.data != null) {
            _updateStateFromResponse(response.data!);
          }
        } else if (message.containsKey('stateUpdate')) {
          // Handle state updates from isolate
          _updateStateFromResponse(message['stateUpdate']);
        }
      }
    } catch (e) {
      DPrint.log('Error handling isolate message: $e');
    }
  }

  /// Update local state from isolate response
  void _updateStateFromResponse(Map<String, dynamic> data) {
    if (data.containsKey('musicPlaying')) {
      musicPlayingNotifier.value = data['musicPlaying'];
    }
    if (data.containsKey('dragging')) {
      draggingNotifier.value = data['dragging'];
    }
  }

  /// Send command to sound isolate with response handling
  Future<SoundResponse> _sendCommand(
    SoundCommand command, [
    Map<String, dynamic>? data,
  ]) async {
    if (!_isolateInitialized || _soundSendPort == null) {
      throw StateError('Sound isolate not initialized');
    }

    final responseId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<SoundResponse>();
    _pendingResponses[responseId] = completer;

    final message = SoundMessage(
      command: command,
      data: data,
      responseId: responseId,
    );

    final startTime = DateTime.now();
    _soundSendPort!.send(message.toJson());

    try {
      final response = await completer.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => SoundResponse(
          responseId: responseId,
          success: false,
          error: 'Command timeout',
        ),
      );

      // Update performance metrics
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _updateAverageResponseTime(responseTime.toDouble());

      return response;
    } catch (e) {
      _pendingResponses.remove(responseId);
      rethrow;
    }
  }

  /// Initialize fallback audio system
  Future<void> _initializeFallback() async {
    try {
      _useFallback = true;
      
      _fallbackMusicPlayer = AudioPlayer();
      _fallbackSoundPlayer = AudioPlayer();
      
      await _fallbackMusicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _fallbackSoundPlayer!.setReleaseMode(ReleaseMode.stop);
      
      await _fallbackMusicPlayer!.setVolume(_musicVolume);
      await _fallbackSoundPlayer!.setVolume(_soundVolume);
      
      // Start background music if enabled
      if (musicEnabledNotifier.value) {
        await _startFallbackMusic();
      }
      
      DPrint.log('✅ Fallback audio system initialized');
    } catch (e) {
      DPrint.log('❌ Error initializing fallback audio: $e');
    }
  }

  /// Start background music (fallback)
  Future<void> _startFallbackMusic() async {
    if (_fallbackMusicPlayer == null || musicPlayingNotifier.value) return;
    
    try {
      await _fallbackMusicPlayer!.setSource(AssetSource(_backgroundMusicPath));
      await _fallbackMusicPlayer!.resume();
      musicPlayingNotifier.value = true;
    } catch (e) {
      DPrint.log('Error starting fallback music: $e');
    }
  }

  /// Stop background music (fallback)
  Future<void> _stopFallbackMusic() async {
    if (_fallbackMusicPlayer == null || !musicPlayingNotifier.value) return;
    
    try {
      await _fallbackMusicPlayer!.pause();
      musicPlayingNotifier.value = false;
    } catch (e) {
      DPrint.log('Error stopping fallback music: $e');
    }
  }

  /// Play sound with fallback
  Future<void> _playFallbackSound(String soundPath) async {
    if (_fallbackSoundPlayer == null || !soundEnabledNotifier.value) return;
    
    try {
      await _fallbackSoundPlayer!.setSource(AssetSource(soundPath));
      await _fallbackSoundPlayer!.resume();
    } catch (e) {
      DPrint.log('Error playing fallback sound: $e');
    }
  }

  /// Execute command with fallback support
  Future<void> _executeCommand(SoundCommand command, [Map<String, dynamic>? data]) async {
    if (_useFallback) {
      await _executeFallbackCommand(command, data);
    } else if (_isolateInitialized) {
      try {
        await _sendCommand(command, data);
      } catch (e) {
        DPrint.log('Isolate command failed, switching to fallback: $e');
        _useFallback = true;
        await _executeFallbackCommand(command, data);
      }
    } else {
      DPrint.log('Sound system not ready, ignoring command: $command');
    }
  }

  /// Execute command using fallback system
  Future<void> _executeFallbackCommand(SoundCommand command, Map<String, dynamic>? data) async {
    switch (command) {
      case SoundCommand.playDragStart:
        draggingNotifier.value = true;
        _currentDragStep = 0;
        await _playFallbackSound(_dragStartPath);
        break;
      case SoundCommand.playDragStep:
        if (draggingNotifier.value) {
          _currentDragStep = (_currentDragStep + 1) % 8;
          await _playFallbackSound(_dragStepPath);
        }
        break;
      case SoundCommand.playDragEnd:
        draggingNotifier.value = false;
        _currentDragStep = 0;
        if (data?['isValidWord'] == true) {
          await _playFallbackSound(_wordMatchPath);
        } else {
          await _playFallbackSound(_invalidSelectionPath);
        }
        break;
      case SoundCommand.playWordFound:
        await _playFallbackSound(_wordMatchPath);
        break;
      case SoundCommand.playWordMatch:
        await _playFallbackSound(_wordMatchPath);
        break;
      case SoundCommand.playLevelComplete:
        await _playFallbackSound(_levelCompletePath);
        break;
      case SoundCommand.playHintActivate:
        await _playFallbackSound(_hintActivatePath);
        break;
      case SoundCommand.playHintReveal:
        await _playFallbackSound(_hintRevealPath);
        break;
      case SoundCommand.playGameRefresh:
        await _playFallbackSound(_gameRefreshPath);
        break;
      case SoundCommand.playInvalidSelection:
        await _playFallbackSound(_invalidSelectionPath);
        break;
      case SoundCommand.playButtonSound:
        await _playFallbackSound(_buttonSoundPath);
        break;
      case SoundCommand.toggleMusic:
        if (data?['enabled'] == true) {
          await _startFallbackMusic();
        } else {
          await _stopFallbackMusic();
        }
        break;
      case SoundCommand.resumeMusic:
        if (musicEnabledNotifier.value) {
          await _startFallbackMusic();
        }
        break;
      case SoundCommand.pauseMusic:
        await _stopFallbackMusic();
        break;
      default:
        break;
    }
  }

  /// Queue management for rapid sound events
  void _queueSound(SoundCommand command, [Map<String, dynamic>? data]) {
    final message = SoundMessage(command: command, data: data);
    _soundQueue.add(message);
    soundQueueLength.value = _soundQueue.length;
    
    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  /// Process sound queue
  void _processQueue() async {
    if (_isProcessingQueue || _soundQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    while (_soundQueue.isNotEmpty) {
      final message = _soundQueue.removeAt(0);
      soundQueueLength.value = _soundQueue.length;
      
      try {
        await _executeCommand(message.command, message.data);
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        DPrint.log('Error processing queued sound: $e');
      }
    }
    
    _isProcessingQueue = false;
  }

  /// Start queue processor timer
  void _startQueueProcessor() {
    _queueProcessor = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isProcessingQueue && _soundQueue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  /// Update average response time
  void _updateAverageResponseTime(double newTime) {
    final current = averageResponseTime.value;
    averageResponseTime.value = (current * 0.8) + (newTime * 0.2);
  }

  // =============================================================================
  // GAME-SPECIFIC SOUND METHODS
  // =============================================================================

  Future<void> playDragStart() async {
    if (!initializedNotifier.value) await initialize();
    if (!soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playDragStart);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> playDragStep() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    _queueSound(SoundCommand.playDragStep);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> playDragEnd({bool isValidWord = false}) async {
    if (!initializedNotifier.value) await initialize();
    
    await _executeCommand(SoundCommand.playDragEnd, {'isValidWord': isValidWord});
  }

  Future<void> playWordFound() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playWordFound);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  Future<void> playWordMatch() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playWordMatch);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> playLevelComplete() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playLevelComplete);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  Future<void> playHintActivate() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playHintActivate);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> playHintReveal() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    _queueSound(SoundCommand.playHintReveal);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> playGameRefresh() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playGameRefresh);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> playInvalidSelection() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playInvalidSelection);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> playButtonSound() async {
    if (!initializedNotifier.value || !soundEnabledNotifier.value) return;
    
    await _executeCommand(SoundCommand.playButtonSound);
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.selectionClick();
    }
  }

  // =============================================================================
  // SETTINGS METHODS
  // =============================================================================

  Future<void> toggleMusic() async {
    if (!initializedNotifier.value) await initialize();
    
    musicEnabledNotifier.value = !musicEnabledNotifier.value;
    await _executeCommand(SoundCommand.toggleMusic, {
      'enabled': musicEnabledNotifier.value,
    });
    await _savePreferences();
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> toggleSound() async {
    if (!initializedNotifier.value) await initialize();
    
    if (soundEnabledNotifier.value) {
      await playButtonSound();
    }
    
    soundEnabledNotifier.value = !soundEnabledNotifier.value;
    await _savePreferences();
    
    if (soundEnabledNotifier.value) {
      await playButtonSound();
    }
  }

  Future<void> toggleHaptic() async {
    if (hapticEnabledNotifier.value) {
      HapticFeedback.lightImpact();
    }
    
    hapticEnabledNotifier.value = !hapticEnabledNotifier.value;
    await _savePreferences();
    
    if (hapticEnabledNotifier.value) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    if (!initializedNotifier.value) return;
    
    _musicVolume = volume.clamp(0.0, 1.0);
    await _executeCommand(SoundCommand.setMusicVolume, {'volume': _musicVolume});
    await _savePreferences();
  }

  Future<void> setSoundVolume(double volume) async {
    if (!initializedNotifier.value) return;
    
    _soundVolume = volume.clamp(0.0, 1.0);
    await _executeCommand(SoundCommand.setSoundVolume, {'volume': _soundVolume});
    await _savePreferences();
  }

  Future<void> setDragSoundVolume(double volume) async {
    if (!initializedNotifier.value) return;
    
    _dragSoundVolume = volume.clamp(0.0, 1.0);
    await _executeCommand(SoundCommand.setDragSoundVolume, {'volume': _dragSoundVolume});
    await _savePreferences();
  }

  Future<void> resumeMusic() async {
    if (musicEnabledNotifier.value && initializedNotifier.value) {
      await _executeCommand(SoundCommand.resumeMusic);
    }
  }

  Future<void> pauseMusic() async {
    if (initializedNotifier.value) {
      await _executeCommand(SoundCommand.pauseMusic);
    }
  }

  // =============================================================================
  // PREFERENCE MANAGEMENT
  // =============================================================================

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicEnabledNotifier.value = prefs.getBool('${KeyConstants.musicEnabled}_optimized') ?? true;
      soundEnabledNotifier.value = prefs.getBool('${KeyConstants.soundEnabled}_optimized') ?? true;
      hapticEnabledNotifier.value = prefs.getBool('haptic_enabled_optimized') ?? true;
      _musicVolume = prefs.getDouble('music_volume_optimized') ?? 0.6;
      _soundVolume = prefs.getDouble('sound_volume_optimized') ?? 0.8;
      _dragSoundVolume = prefs.getDouble('drag_sound_volume_optimized') ?? 0.4;
    } catch (e) {
      DPrint.log('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${KeyConstants.musicEnabled}_optimized', musicEnabledNotifier.value);
      await prefs.setBool('${KeyConstants.soundEnabled}_optimized', soundEnabledNotifier.value);
      await prefs.setBool('haptic_enabled_optimized', hapticEnabledNotifier.value);
      await prefs.setDouble('music_volume_optimized', _musicVolume);
      await prefs.setDouble('sound_volume_optimized', _soundVolume);
      await prefs.setDouble('drag_sound_volume_optimized', _dragSoundVolume);
    } catch (e) {
      DPrint.log('Error saving preferences: $e');
    }
  }

  /// Clean up isolate resources
  Future<void> _cleanupIsolate() async {
    try {
      _isolateInitialized = false;
      _soundIsolate?.kill(priority: Isolate.immediate);
      _soundReceivePort?.close();
      _soundSendPort = null;
      
      // Clear pending responses
      for (final completer in _pendingResponses.values) {
        if (!completer.isCompleted) {
          completer.complete(SoundResponse(
            responseId: '',
            success: false,
            error: 'Isolate cleaned up',
          ));
        }
      }
      _pendingResponses.clear();
    } catch (e) {
      DPrint.log('Error cleaning up isolate: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      _queueProcessor?.cancel();
      
      await _cleanupIsolate();
      
      // Dispose fallback players
      await _fallbackMusicPlayer?.dispose();
      await _fallbackSoundPlayer?.dispose();
      
      // Dispose ValueNotifiers
      musicEnabledNotifier.dispose();
      soundEnabledNotifier.dispose();
      hapticEnabledNotifier.dispose();
      musicPlayingNotifier.dispose();
      initializedNotifier.dispose();
      draggingNotifier.dispose();
      soundQueueLength.dispose();
      averageResponseTime.dispose();
      
      initializedNotifier.value = false;
      DPrint.log('✅ OptimizedSoundController disposed');
    } catch (e) {
      DPrint.log('❌ Error disposing OptimizedSoundController: $e');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'queueLength': soundQueueLength.value,
      'averageResponseTime': averageResponseTime.value,
      'isProcessingQueue': _isProcessingQueue,
      'pendingResponses': _pendingResponses.length,
      'isolateInitialized': _isolateInitialized,
      'useFallback': _useFallback,
    };
  }
}

// =============================================================================
// TOP-LEVEL ISOLATE ENTRY POINT (Required for isolates)
// =============================================================================

/// Entry point for the sound isolate - MUST be top-level function
void soundIsolateEntryPoint(SendPort mainSendPort) async {
  final isolateReceivePort = ReceivePort();
  
  // Send back the isolate's SendPort to main thread
  mainSendPort.send(isolateReceivePort.sendPort);
  
  // Initialize sound system in isolate
  final soundSystem = IsolateSoundSystem(mainSendPort);
  
  try {
    await soundSystem.initialize();
    
    // Listen for commands from main thread
    await for (final message in isolateReceivePort) {
      if (message is Map<String, dynamic>) {
        try {
          final soundMessage = SoundMessage.fromJson(message);
          await soundSystem.handleCommand(soundMessage);
        } catch (e) {
          print('Error in sound isolate: $e');
        }
      }
    }
  } catch (e) {
    print('Fatal error in sound isolate: $e');
    mainSendPort.send({
      'error': 'Isolate initialization failed: $e',
    });
  }
}

/// Sound system running in isolate
class IsolateSoundSystem {
  final SendPort mainSendPort;
  
  // Audio players
  AudioPlayer? _musicPlayer;
  AudioPlayer? _soundPlayer;
  AudioPlayer? _dragSoundPlayer;
  AudioPlayer? _feedbackPlayer;
  
  // State
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _musicPlaying = false;
  bool _dragging = false;
  
  // Volume control
  double _musicVolume = 0.6;
  double _soundVolume = 0.8;
  double _dragSoundVolume = 0.4;
  final double _duckingVolume = 0.2;
  
  // Drag sound management
  int _currentDragStep = 0;
  int _maxDragSteps = 8;
  
  // Audio file paths
  static const String _backgroundMusicPath = 'background_music.wav';
  static const String _buttonSoundPath = 'button_click.wav';
  static const String _dragStartPath = 'match_success.wav';
  static const String _dragStepPath = 'match_success.wav';
  static const String _wordMatchPath = 'match_success.wav';
  static const String _levelCompletePath = 'match_success.wav';
  static const String _hintActivatePath = 'match_success.wav';
  static const String _hintRevealPath = 'match_success.wav';
  static const String _gameRefreshPath = 'match_success.wav';
  static const String _invalidSelectionPath = 'match_success.wav';
  
  IsolateSoundSystem(this.mainSendPort);
  
  /// Initialize audio system in isolate
  Future<void> initialize() async {
    try {
      // Initialize audio players
      _musicPlayer = AudioPlayer();
      _soundPlayer = AudioPlayer();
      _dragSoundPlayer = AudioPlayer();
      _feedbackPlayer = AudioPlayer();
      
      // Configure players
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _soundPlayer!.setReleaseMode(ReleaseMode.stop);
      await _dragSoundPlayer!.setReleaseMode(ReleaseMode.stop);
      await _feedbackPlayer!.setReleaseMode(ReleaseMode.stop);
      
      // Set initial volumes
      await _musicPlayer!.setVolume(_musicVolume);
      await _soundPlayer!.setVolume(_soundVolume);
      await _dragSoundPlayer!.setVolume(_dragSoundVolume);
      await _feedbackPlayer!.setVolume(_soundVolume);
      
      // Setup completion handlers
      _dragSoundPlayer!.onPlayerComplete.listen((_) => _onDragSoundComplete());
      _soundPlayer!.onPlayerComplete.listen((_) => _onSoundComplete());
      _feedbackPlayer!.onPlayerComplete.listen((_) => _onSoundComplete());
      
      print('🎵 Sound isolate initialized successfully');
    } catch (e) {
      print('❌ Error initializing sound isolate: $e');
      throw e;
    }
  }
  
  /// Handle command from main thread
  Future<void> handleCommand(SoundMessage message) async {
    try {
      bool success = true;
      Map<String, dynamic>? responseData;
      String? error;
      
      switch (message.command) {
        case SoundCommand.initialize:
          await _handleInitialize(message.data ?? {});
          break;
        case SoundCommand.playDragStart:
          await _playDragStart();
          break;
        case SoundCommand.playDragStep:
          await _playDragStep();
          break;
        case SoundCommand.playDragEnd:
          await _playDragEnd(message.data?['isValidWord'] ?? false);
          break;
        case SoundCommand.playWordFound:
          await _playWordFound();
          break;
        case SoundCommand.playWordMatch:
          await _playWordMatch();
          break;
        case SoundCommand.playLevelComplete:
          await _playLevelComplete();
          break;
        case SoundCommand.playHintActivate:
          await _playHintActivate();
          break;
        case SoundCommand.playHintReveal:
          await _playHintReveal();
          break;
        case SoundCommand.playGameRefresh:
          await _playGameRefresh();
          break;
        case SoundCommand.playInvalidSelection:
          await _playInvalidSelection();
          break;
        case SoundCommand.playButtonSound:
          await _playButtonSound();
          break;
        case SoundCommand.toggleMusic:
          await _toggleMusic(message.data?['enabled'] ?? true);
          responseData = {'musicPlaying': _musicPlaying};
          break;
        case SoundCommand.toggleSound:
          _soundEnabled = message.data?['enabled'] ?? true;
          break;
        case SoundCommand.setMusicVolume:
          await _setMusicVolume(message.data?['volume'] ?? 0.6);
          break;
        case SoundCommand.setSoundVolume:
          await _setSoundVolume(message.data?['volume'] ?? 0.8);
          break;
        case SoundCommand.setDragSoundVolume:
          await _setDragSoundVolume(message.data?['volume'] ?? 0.4);
          break;
        case SoundCommand.resumeMusic:
          await _resumeMusic();
          responseData = {'musicPlaying': _musicPlaying};
          break;
        case SoundCommand.pauseMusic:
          await _pauseMusic();
          responseData = {'musicPlaying': _musicPlaying};
          break;
        case SoundCommand.dispose:
          await _dispose();
          break;
        default:
          success = false;
          error = 'Unknown command';
      }
      
      // Send response back to main thread
      if (message.responseId != null) {
        final response = SoundResponse(
          responseId: message.responseId!,
          success: success,
          data: responseData,
          error: error,
        );
        mainSendPort.send(response.toJson());
      }
      
    } catch (e) {
      // Send error response
      if (message.responseId != null) {
        final response = SoundResponse(
          responseId: message.responseId!,
          success: false,
          error: e.toString(),
        );
        mainSendPort.send(response.toJson());
      }
    }
  }
  
  // Implementation methods (similar to original but with null safety)
  
  Future<void> _handleInitialize(Map<String, dynamic> data) async {
    _musicEnabled = data['musicEnabled'] ?? true;
    _soundEnabled = data['soundEnabled'] ?? true;
    _musicVolume = data['musicVolume'] ?? 0.6;
    _soundVolume = data['soundVolume'] ?? 0.8;
    _dragSoundVolume = data['dragSoundVolume'] ?? 0.4;
    
    if (_musicEnabled) {
      await _startBackgroundMusic();
    }
  }
  
  Future<void> _startBackgroundMusic() async {
    if (!_musicEnabled || _musicPlaying || _musicPlayer == null) return;
    
    try {
      await _musicPlayer!.setSource(AssetSource(_backgroundMusicPath));
      await _musicPlayer!.resume();
      _musicPlaying = true;
      _sendStateUpdate({'musicPlaying': true});
    } catch (e) {
      print('Error starting background music: $e');
    }
  }
  
  Future<void> _stopBackgroundMusic() async {
    if (!_musicPlaying || _musicPlayer == null) return;
    
    try {
      await _musicPlayer!.pause();
      _musicPlaying = false;
      _sendStateUpdate({'musicPlaying': false});
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }
  
  Future<void> _duckMusic() async {
    if (_musicPlaying && _musicPlayer != null) {
      await _musicPlayer!.setVolume(_duckingVolume);
    }
  }
  
  Future<void> _restoreMusic() async {
    if (_musicPlaying && _musicPlayer != null) {
      await _musicPlayer!.setVolume(_musicVolume);
    }
  }
  
  void _onSoundComplete() => _restoreMusic();
  
  void _onDragSoundComplete() {
    if (!_dragging) {
      _restoreMusic();
    }
  }
  
  // Game sound methods with null safety
  
  Future<void> _playDragStart() async {
    if (!_soundEnabled || _dragSoundPlayer == null) return;
    
    _dragging = true;
    _currentDragStep = 0;
    _sendStateUpdate({'dragging': true});
    
    await _duckMusic();
    
    try {
      await _dragSoundPlayer!.setSource(AssetSource(_dragStartPath));
      await _dragSoundPlayer!.resume();
    } catch (e) {
      print('Error playing drag start sound: $e');
    }
  }
  
  Future<void> _playDragStep() async {
    if (!_soundEnabled || !_dragging || _dragSoundPlayer == null) return;
    
    _currentDragStep = (_currentDragStep + 1) % _maxDragSteps;
    
    try {
      await _dragSoundPlayer!.setSource(AssetSource(_dragStepPath));
      await _dragSoundPlayer!.resume();
    } catch (e) {
      print('Error playing drag step sound: $e');
    }
  }
  
  Future<void> _playDragEnd(bool isValidWord) async {
    _dragging = false;
    _currentDragStep = 0;
    _sendStateUpdate({'dragging': false});
    
    if (!_soundEnabled) {
      _restoreMusic();
      return;
    }
    
    if (isValidWord) {
      await _playWordFound();
    } else {
      await _playInvalidSelection();
    }
  }
  
  Future<void> _playWordFound() async {
    if (!_soundEnabled || _feedbackPlayer == null) return;
    
    await _duckMusic();
    
    try {
      await _feedbackPlayer!.setSource(AssetSource(_wordMatchPath));
      await _feedbackPlayer!.resume();
    } catch (e) {
      print('Error playing word found sound: $e');
    }
  }
  
  Future<void> _playWordMatch() async {
    if (!_soundEnabled || _soundPlayer == null) return;
    
    try {
      await _soundPlayer!.setSource(AssetSource(_wordMatchPath));
      await _soundPlayer!.resume();
    } catch (e) {
      print('Error playing word match sound: $e');
    }
  }
  
  Future<void> _playLevelComplete() async {
    if (!_soundEnabled || _feedbackPlayer == null) return;
    
    await _duckMusic();
    
    try {
      await _feedbackPlayer!.setSource(AssetSource(_levelCompletePath));
      await _feedbackPlayer!.resume();
    } catch (e) {
      print('Error playing level complete sound: $e');
    }
  }
  
  Future<void> _playHintActivate() async {
    if (!_soundEnabled || _soundPlayer == null) return;
    
    try {
      await _soundPlayer!.setSource(AssetSource(_hintActivatePath));
      await _soundPlayer!.resume();
    } catch (e) {
      print('Error playing hint activate sound: $e');
    }
  }
  
  Future<void> _playHintReveal() async {
    if (!_soundEnabled || _dragSoundPlayer == null) return;
    
    try {
      await _dragSoundPlayer!.setSource(AssetSource(_hintRevealPath));
      await _dragSoundPlayer!.resume();
    } catch (e) {
      print('Error playing hint reveal sound: $e');
    }
  }
  
  Future<void> _playGameRefresh() async {
    if (!_soundEnabled || _soundPlayer == null) return;
    
    try {
      await _soundPlayer!.setSource(AssetSource(_gameRefreshPath));
      await _soundPlayer!.resume();
    } catch (e) {
      print('Error playing game refresh sound: $e');
    }
  }
  
  Future<void> _playInvalidSelection() async {
    if (!_soundEnabled || _feedbackPlayer == null) return;
    
    try {
      await _feedbackPlayer!.setSource(AssetSource(_invalidSelectionPath));
      await _feedbackPlayer!.resume();
    } catch (e) {
      print('Error playing invalid selection sound: $e');
    }
    
    _restoreMusic();
  }
  
  Future<void> _playButtonSound() async {
    if (!_soundEnabled || _soundPlayer == null) return;
    
    await _duckMusic();
    
    try {
      await _soundPlayer!.setSource(AssetSource(_buttonSoundPath));
      await _soundPlayer!.resume();
    } catch (e) {
      print('Error playing button sound: $e');
    }
  }
  
  // Settings methods
  
  Future<void> _toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    
    if (_musicEnabled) {
      await _startBackgroundMusic();
    } else {
      await _stopBackgroundMusic();
    }
  }
  
  Future<void> _setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    if (!_dragging && _musicPlaying && _musicPlayer != null) {
      await _musicPlayer!.setVolume(_musicVolume);
    }
  }
  
  Future<void> _setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    if (_soundPlayer != null) await _soundPlayer!.setVolume(_soundVolume);
    if (_feedbackPlayer != null) await _feedbackPlayer!.setVolume(_soundVolume);
  }
  
  Future<void> _setDragSoundVolume(double volume) async {
    _dragSoundVolume = volume.clamp(0.0, 1.0);
    if (_dragSoundPlayer != null) await _dragSoundPlayer!.setVolume(_dragSoundVolume);
  }
  
  Future<void> _resumeMusic() async {
    if (_musicEnabled && !_musicPlaying) {
      await _startBackgroundMusic();
    }
  }
  
  Future<void> _pauseMusic() async {
    if (_musicPlaying && _musicPlayer != null) {
      await _musicPlayer!.pause();
      _musicPlaying = false;
      _sendStateUpdate({'musicPlaying': false});
    }
  }
  
  Future<void> _dispose() async {
    try {
      await _musicPlayer?.dispose();
      await _soundPlayer?.dispose();
      await _dragSoundPlayer?.dispose();
      await _feedbackPlayer?.dispose();
      print('🎵 Sound isolate disposed');
    } catch (e) {
      print('❌ Error disposing sound isolate: $e');
    }
  }
  
  /// Send state update to main thread
  void _sendStateUpdate(Map<String, dynamic> stateData) {
    mainSendPort.send({
      'stateUpdate': stateData,
    });
  }
}
