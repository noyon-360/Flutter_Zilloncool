// settings_controller.dart
import 'package:flutter/material.dart';

class SettingsController {
  final ValueNotifier<bool> isMusicOn = ValueNotifier(true);
  final ValueNotifier<bool> isSoundOn = ValueNotifier(true);

  void toggleMusic() => isMusicOn.value = !isMusicOn.value;
  void toggleSound() => isSoundOn.value = !isSoundOn.value;

  void dispose() {
    isMusicOn.dispose();
    isSoundOn.dispose();
  }
}