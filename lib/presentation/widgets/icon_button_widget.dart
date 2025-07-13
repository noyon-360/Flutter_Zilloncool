import 'package:flutter/material.dart';
import 'package:word_game/constants/app_colors.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap; // Changed to nullable
  final double size;
  final Color iconColor;
  final Color borderColor;
  final double iconSize;
  final Color disabledColor; // New parameter for disabled state

  const IconButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.iconColor = Colors.white,
    this.borderColor = Colors.white,
    this.iconSize = 28,
    this.disabledColor = Colors.grey, // Default disabled color
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.primaryBgColor,
          borderRadius: BorderRadius.circular(size),
          border: Border.all(
            color: isDisabled ? disabledColor : borderColor,
            width: isDisabled ? 0.5 : 1.0,
          ),
        ),
        child: Icon(
          icon,
          color: isDisabled ? disabledColor : iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
