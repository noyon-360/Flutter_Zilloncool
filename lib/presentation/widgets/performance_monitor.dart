import 'package:flutter/material.dart';

import '../controllers/sound_controller.dart';

/// Widget to monitor sound performance (for debugging)
class SoundPerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const SoundPerformanceMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<SoundPerformanceMonitor> createState() => _SoundPerformanceMonitorState();
}

class _SoundPerformanceMonitorState extends State<SoundPerformanceMonitor> {
  final SoundController _soundController = SoundController();

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 100,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sound Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<int>(
                  valueListenable: _soundController.soundQueueLength,
                  builder: (context, queueLength, child) {
                    return Text(
                      'Queue: $queueLength',
                      style: TextStyle(
                        color: queueLength > 5 ? Colors.red : Colors.green,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _soundController.averageResponseTime,
                  builder: (context, avgTime, child) {
                    return Text(
                      'Avg: ${avgTime.toStringAsFixed(1)}ms',
                      style: TextStyle(
                        color: avgTime > 100 ? Colors.red : Colors.green,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
