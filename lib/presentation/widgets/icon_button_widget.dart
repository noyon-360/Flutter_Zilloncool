import 'package:flutter/material.dart';
import 'package:word_game/constants/app_colors.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color iconColor;
  final Color borderColor;
  final double iconSize;

  const IconButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.iconColor = Colors.white,
    this.borderColor = Colors.white,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.primaryBgColor,
          borderRadius: BorderRadius.circular(size),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
