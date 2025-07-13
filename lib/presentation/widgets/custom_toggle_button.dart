import 'package:flutter/material.dart';

class CustomToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomToggleButton({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = value;
    final isInteractive = onChanged != null;
    
    return GestureDetector(
      onTap: isInteractive
          ? () {
              onChanged!(!value);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isOn 
              ? Colors.green.withOpacity(isInteractive ? 0.3 : 0.1)
              : Colors.red.withOpacity(isInteractive ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Align(
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isOn 
                  ? Colors.green.withOpacity(isInteractive ? 1.0 : 0.5)
                  : Colors.red.withOpacity(isInteractive ? 1.0 : 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOn ? Icons.check : Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}