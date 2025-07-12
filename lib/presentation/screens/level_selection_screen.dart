import 'package:flutter/material.dart';

import '../../data/game_data.dart';
import 'game_screen.dart';


class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = GameData.getLevels();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF7BB3F0),
              Color(0xFFB8D4F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with icons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Home action
                      },
                      icon: const Icon(Icons.home, color: Colors.white, size: 28),
                    ),
                    const Text(
                      'Select Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Settings action
                      },
                      icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              
              // Level selection path
              Expanded(
                child: Stack(
                  children: [
                    // Background scenic image (you can add your own image here)
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/scenic_bg.jpg'), // Add your background image
                          fit: BoxFit.cover,
                          opacity: 0.3,
                        ),
                      ),
                    ),
                    
                    // Level path
                    CustomPaint(
                      painter: LevelPathPainter(),
                      child: Container(),
                    ),
                    
                    // Level buttons
                    ...levels.asMap().entries.map((entry) {
                      int index = entry.key;
                      var level = entry.value;
                      
                      return Positioned(
                        left: _getLevelPosition(index)['x']! * MediaQuery.of(context).size.width,
                        top: _getLevelPosition(index)['y']! * MediaQuery.of(context).size.height * 0.7,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(level: level),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${level.level}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Define positions for level buttons (similar to your UI)
  Map<String, double> _getLevelPosition(int index) {
    List<Map<String, double>> positions = [
      {'x': 0.5, 'y': 0.9},   // Level 1 - bottom center
      {'x': 0.2, 'y': 0.8},   // Level 2 - bottom left
      {'x': 0.4, 'y': 0.65},  // Level 3 - middle left
      {'x': 0.6, 'y': 0.5},   // Level 4 - middle right
      {'x': 0.8, 'y': 0.35},  // Level 5 - top right
    ];
    
    if (index < positions.length) {
      return positions[index];
    }
    return {'x': 0.5, 'y': 0.5};
  }
}

// Custom painter for the connecting path between levels
class LevelPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw connecting path between levels (simplified version)
    path.moveTo(size.width * 0.5, size.height * 0.63);
    path.lineTo(size.width * 0.2, size.height * 0.56);
    path.lineTo(size.width * 0.4, size.height * 0.455);
    path.lineTo(size.width * 0.6, size.height * 0.35);
    path.lineTo(size.width * 0.8, size.height * 0.245);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}