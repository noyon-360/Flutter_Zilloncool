import 'package:flutter/material.dart';
import 'isolate_sound_controller.dart';

/// Adapter to maintain backward compatibility with existing code
class SoundController {
  static final SoundController _instance = SoundController._internal();
  factory SoundController() => _instance;
  SoundController._internal();

  final OptimizedSoundController _optimizedController = OptimizedSoundController();

  // Delegate all calls to the optimized controller
  ValueNotifier<bool> get musicEnabledNotifier => _optimizedController.musicEnabledNotifier;
  ValueNotifier<bool> get soundEnabledNotifier => _optimizedController.soundEnabledNotifier;
  ValueNotifier<bool> get hapticEnabledNotifier => _optimizedController.hapticEnabledNotifier;
  ValueNotifier<bool> get musicPlayingNotifier => _optimizedController.musicPlayingNotifier;
  ValueNotifier<bool> get initializedNotifier => _optimizedController.initializedNotifier;
  ValueNotifier<bool> get draggingNotifier => _optimizedController.draggingNotifier;

  bool get isMusicEnabled => _optimizedController.isMusicEnabled;
  bool get isSoundEnabled => _optimizedController.isSoundEnabled;
  bool get isHapticEnabled => _optimizedController.isHapticEnabled;
  bool get isMusicPlaying => _optimizedController.isMusicPlaying;
  bool get isInitialized => _optimizedController.isInitialized;
  bool get isDragging => _optimizedController.isDragging;

  Future<void> initialize() => _optimizedController.initialize();
  Future<void> playDragStart() => _optimizedController.playDragStart();
  Future<void> playDragStep() => _optimizedController.playDragStep();
  Future<void> playDragEnd({bool isValidWord = false}) => _optimizedController.playDragEnd(isValidWord: isValidWord);
  Future<void> playWordFound() => _optimizedController.playWordFound();
  Future<void> playWordMatch() => _optimizedController.playWordMatch();
  Future<void> playLevelComplete() => _optimizedController.playLevelComplete();
  Future<void> playHintActivate() => _optimizedController.playHintActivate();
  Future<void> playHintReveal() => _optimizedController.playHintReveal();
  Future<void> playGameRefresh() => _optimizedController.playGameRefresh();
  Future<void> playInvalidSelection() => _optimizedController.playInvalidSelection();
  Future<void> playButtonSound() => _optimizedController.playButtonSound();
  Future<void> toggleMusic() => _optimizedController.toggleMusic();
  Future<void> toggleSound() => _optimizedController.toggleSound();
  Future<void> toggleHaptic() => _optimizedController.toggleHaptic();
  Future<void> setMusicVolume(double volume) => _optimizedController.setMusicVolume(volume);
  Future<void> setSoundVolume(double volume) => _optimizedController.setSoundVolume(volume);
  Future<void> setDragSoundVolume(double volume) => _optimizedController.setDragSoundVolume(volume);
  Future<void> resumeMusic() => _optimizedController.resumeMusic();
  Future<void> pauseMusic() => _optimizedController.pauseMusic();
  Future<void> dispose() => _optimizedController.dispose();

  // Additional performance monitoring methods
  Map<String, dynamic> getPerformanceMetrics() => _optimizedController.getPerformanceMetrics();
  ValueNotifier<int> get soundQueueLength => _optimizedController.soundQueueLength;
  ValueNotifier<double> get averageResponseTime => _optimizedController.averageResponseTime;
}
