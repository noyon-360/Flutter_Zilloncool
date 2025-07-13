import 'package:flutter/material.dart';

class CustomToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = value;
    
    return GestureDetector(
      onTap: () async {
        // The onChanged callback will handle the toggle logic
        // Sound will be played inside the controller's toggle methods
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isOn ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Align(
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isOn ? Colors.green : Colors.red.shade900,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
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
