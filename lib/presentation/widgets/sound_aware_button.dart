import 'package:flutter/material.dart';
import '../controllers/sound_controller.dart';

/// A wrapper widget that adds sound to any button
class SoundAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enableSound;

  const SoundAwareButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enableSound = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed != null ? () async {
        // Play sound first
        if (enableSound) {
          await SoundController().playButtonSound();
        }
        
        // Then execute the callback
        onPressed?.call();
      } : null,
      child: child,
    );
  }
}

/// Enhanced IconButton with sound
class SoundAwareIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final bool enableSound;
  final double? iconSize;
  final Color? color;

  const SoundAwareIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.enableSound = true,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      iconSize: iconSize,
      color: color,
      onPressed: onPressed != null ? () async {
        if (enableSound) {
          await SoundController().playButtonSound();
        }
        onPressed?.call();
      } : null,
    );
  }
}
