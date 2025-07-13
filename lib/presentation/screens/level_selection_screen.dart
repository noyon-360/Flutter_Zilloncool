import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:word_game/routes/generate_routes.dart';
import '../../data/game_data.dart';
import '../../models/game_models.dart';
import 'dart:math' as math;

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final double canvasHeight = 3000; // Height for 20 levels
  final int totalLevels = 20;

  @override
  void initState() {
    super.initState();
    // Start from bottom (reverse scroll)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final levels = _generateLevels(); // Generate 20 levels

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0), Color(0xFFB8D4F0)],
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
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Home action
                        },
                        icon: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Text(
                      'Select Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Settings action
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable level selection with wavy path
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  reverse: true, // Start from bottom
                  child: SizedBox(
                    height: canvasHeight,
                    width: size.width,
                    child: Stack(
                      children: [
                        // Background scenic image
                        Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/level_screen_bg.jpeg'),
                              fit: BoxFit.cover,
                              opacity: 0.3,
                            ),
                          ),
                        ),

                        // Wavy line path
                        CustomPaint(
                          size: Size(size.width, canvasHeight),
                          painter: LevelWavyLinePainter(totalLevels),
                        ),

                        // Level buttons positioned exactly on the wavy line
                        ...levels.asMap().entries.map((entry) {
                          int index = entry.key;
                          var level = entry.value;

                          // Calculate exact position on the wavy line
                          final position = _calculateExactLevelPosition(
                            index,
                            size.width,
                          );

                          return Positioned(
                            left: position.dx - 30, // Center the 60px button
                            top: position.dy - 30, // Center the 60px button
                            child: GestureDetector(
                              onTap: () {
                                if (level.level <= 5) {
                                  // Only first 5 levels have actual game data
                                  final gameLevel =
                                      GameData.getLevels()[level.level - 1];

                                  Go.sailTo(
                                    AppRoutes.game,
                                    arguments: {"level": gameLevel},
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Level ${level.level} coming soon!',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Transform.rotate(
                                angle: _degreesToRadians(-10),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: index == 1
                                        ? const Color(0xff007400)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: index == 1
                                          ? Colors.black54
                                          : Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == 1
                                          ? const Color(0xff007400)
                                          : Colors.white,
                                      border: Border.all(
                                        color: index == 1
                                            ? const Color(0xff007400)
                                            : Colors.white,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${totalLevels - index}', // Reversed numbering (bottom to top)
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: index == 1
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  // Generate 20 levels (using existing 5 levels + placeholders)
  List<GameLevel> _generateLevels() {
    final existingLevels = GameData.getLevels();
    List<GameLevel> allLevels = [];

    for (int i = 1; i <= totalLevels; i++) {
      if (i <= existingLevels.length) {
        allLevels.add(existingLevels[i - 1]);
      } else {
        // Create placeholder levels
        allLevels.add(
          GameLevel(
            level: i,
            words: ['PLACEHOLDER'],
            grid: List.generate(7, (i) => List.generate(7, (j) => 'A')),
            backgroundImage: 'assets/images/placeholder_bg.jpg',
          ),
        );
      }
    }

    return allLevels;
  }

  // Calculate EXACT position on the wavy line (matching the painter's path)
  Offset _calculateExactLevelPosition(int index, double screenWidth) {
    final waveHeight = canvasHeight / totalLevels;
    final amplitude = screenWidth / 7;
    final centerX = screenWidth / 2;

    // This matches EXACTLY with the LevelWavyLinePainter logic
    final y1 =
        waveHeight *
        (index + 0.5); // Control point Y (where the button should be)
    final x1 = index % 2 == 0
        ? centerX - amplitude
        : centerX + amplitude; // Control point X

    return Offset(x1, y1);
  }

  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

// Custom painter for wavy line using quadratic bezier curves
class LevelWavyLinePainter extends CustomPainter {
  final int levelCount;

  LevelWavyLinePainter(this.levelCount);

  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient paint
    final gradient = const LinearGradient(
      colors: [Color(0xff00FF90), Color(0xff009957)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveHeight = size.height / levelCount;
    final amplitude = size.width / 4;
    final centerX = size.width / 2;

    // Start from center top
    path.moveTo(centerX, 0);

    // Create wavy path using quadratic bezier curves
    for (int i = 0; i < levelCount; i++) {
      final y1 = waveHeight * (i + 0.5); // Control point Y
      final x1 = i % 2 == 0
          ? centerX - amplitude
          : centerX + amplitude; // Control point X
      final y2 = waveHeight * (i + 1); // End point Y
      final x2 = centerX; // End point X (always center)

      // Create smooth curve using quadratic bezier
      path.quadraticBezierTo(x1, y1, x2, y2);
    }

    canvas.drawPath(path, paint);

    // Add subtle glow effect
    final glowPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);

    // Add flowing dots at control points (where buttons will be)
    final dotPaint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < levelCount; i++) {
      final y = waveHeight * (i + 0.5);
      final x = i % 2 == 0 ? centerX - amplitude : centerX + amplitude;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
