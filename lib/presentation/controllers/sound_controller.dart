import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_game/constants/key_constants.dart';
import 'package:flutter/material.dart';

class SoundController extends ChangeNotifier {
  static final SoundController _instance = SoundController._internal();
  factory SoundController() => _instance;
  SoundController._internal();

  // Audio players
  late AudioPlayer _musicPlayer;
  late AudioPlayer _soundPlayer;

  // State management
  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  bool _isMusicPlaying = false;
  bool _isInitialized = false;

  // Audio file paths
  static const String _backgroundMusicPath = 'background_music.wav';
  static const String _buttonSoundPath = 'sound_effect.wav';

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicPlaying => _isMusicPlaying;
  bool get isInitialized => _isInitialized;

  /// Initialize the sound controller
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize audio players
      _musicPlayer = AudioPlayer();
      _soundPlayer = AudioPlayer();

      // Configure music player for looping
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.7); // 70% volume for background music

      // Configure sound player
      await _soundPlayer.setReleaseMode(ReleaseMode.stop);
      await _soundPlayer.setVolume(1.0); // 100% volume for sound effects

      // Load saved preferences FIRST
      await _loadPreferences();

      // Preload audio files for better performance
      await _preloadAudio();

      _isInitialized = true;

      // Start background music if enabled
      if (_isMusicEnabled) {
        await _startBackgroundMusic();
      }

      DPrint.log('SoundController initialized successfully');
      
      // Notify listeners after initialization
      notifyListeners();
    } catch (e) {
      DPrint.log('Error initializing SoundController: $e');
    }
  }

  /// Preload audio files for better performance
  Future<void> _preloadAudio() async {
    try {
      // Preload background music
      await _musicPlayer.setSource(AssetSource(_backgroundMusicPath));

      // Preload button sound
      await _soundPlayer.setSource(AssetSource(_buttonSoundPath));

      DPrint.log('Audio files preloaded successfully');
    } catch (e) {
      DPrint.log('Error preloading audio: $e');
    }
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(KeyConstants.musicEnabled) ?? true;
      _isSoundEnabled = prefs.getBool(KeyConstants.soundEnabled) ?? true;
      DPrint.log('Loaded preferences - Music: $_isMusicEnabled, Sound: $_isSoundEnabled');
    } catch (e) {
      DPrint.log('Error loading preferences: $e');
    }
  }

  /// Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(KeyConstants.musicEnabled, _isMusicEnabled);
      await prefs.setBool(KeyConstants.soundEnabled, _isSoundEnabled);
      DPrint.log('Saved preferences - Music: $_isMusicEnabled, Sound: $_isSoundEnabled');
    } catch (e) {
      DPrint.log('Error saving preferences: $e');
    }
  }

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    if (!_isInitialized) await initialize();

    _isMusicEnabled = !_isMusicEnabled;
    
    DPrint.log('Toggling music to: $_isMusicEnabled');

    if (_isMusicEnabled) {
      await _startBackgroundMusic();
    } else {
      await _stopBackgroundMusic();
    }

    await _savePreferences();
    notifyListeners();

    // Haptic feedback only if sound is enabled
    if (_isSoundEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound() async {
    if (!_isInitialized) await initialize();

    // Play button sound BEFORE toggling if sound is currently enabled
    if (_isSoundEnabled) {
      await _playButtonSoundInternal();
    }

    _isSoundEnabled = !_isSoundEnabled;
    
    DPrint.log('Toggling sound to: $_isSoundEnabled');

    await _savePreferences();
    notifyListeners();

    // Play confirmation sound if sound was just enabled
    if (_isSoundEnabled) {
      await _playButtonSoundInternal();
    }
  }

  /// Start background music
  Future<void> _startBackgroundMusic() async {
    if (!_isMusicEnabled || _isMusicPlaying) return;

    try {
      await _musicPlayer.setSource(AssetSource(_backgroundMusicPath));
      await _musicPlayer.resume();
      _isMusicPlaying = true;
      DPrint.log('Background music started');
    } catch (e) {
      DPrint.log('Error starting background music: $e');
    }
  }

  /// Stop background music
  Future<void> _stopBackgroundMusic() async {
    if (!_isMusicPlaying) return;

    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
      DPrint.log('Background music stopped');
    } catch (e) {
      DPrint.log('Error stopping background music: $e');
    }
  }

  /// Internal method to play button sound without additional checks
  Future<void> _playButtonSoundInternal() async {
    try {
      // Stop any currently playing sound effect
      await _soundPlayer.stop();

      // Play button sound
      await _soundPlayer.setSource(AssetSource(_buttonSoundPath));
      await _soundPlayer.resume();

      // Add haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      DPrint.log('Error playing button sound: $e');
    }
  }

  /// Play button click sound (public method)
  Future<void> playButtonSound() async {
    if (!_isInitialized) await initialize();
    if (!_isSoundEnabled) return;

    await _playButtonSoundInternal();
  }

  /// Resume music when app comes to foreground
  Future<void> resumeMusic() async {
    if (_isMusicEnabled && !_isMusicPlaying) {
      await _startBackgroundMusic();
    }
  }

  /// Pause music when app goes to background
  Future<void> pauseMusic() async {
    if (_isMusicPlaying) {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
    }
  }

  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    if (!_isInitialized) return;
    await _musicPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set sound effects volume (0.0 to 1.0)
  Future<void> setSoundVolume(double volume) async {
    if (!_isInitialized) return;
    await _soundPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _soundPlayer.dispose();
      _isInitialized = false;
      DPrint.log('SoundController disposed');
    } catch (e) {
      DPrint.log('Error disposing SoundController: $e');
    }
    super.dispose();
  }
}
