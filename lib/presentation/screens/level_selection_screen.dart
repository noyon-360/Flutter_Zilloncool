import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:word_game/presentation/controllers/level_progress_controller.dart';
import 'package:word_game/presentation/drawer/custom_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final double canvasHeight = 3000; // Height for 20 levels
  final int totalLevels = 20;

  @override
  void initState() {
    super.initState();
    // Initialize level progress manager
    _initializeLevelProgress();
    
    // Start from bottom (reverse scroll)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Initialize level progress system
  Future<void> _initializeLevelProgress() async {
    await LevelProgressController.initialize();
    // Refresh UI after initialization
    if (mounted) setState(() {});
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
      key: _scaffoldKey,
      endDrawer: CustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/level_screen_bg.jpeg'),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable level selection with wavy path
              SingleChildScrollView(
                controller: _scrollController,
                reverse: true, // Start from bottom
                child: SizedBox(
                  height: canvasHeight,
                  width: size.width,
                  child: Stack(
                    children: [
                      // Wavy line path
                      CustomPaint(
                        size: Size(size.width, canvasHeight),
                        painter: LevelWavyLinePainter(totalLevels),
                      ),
                      // Level buttons positioned exactly on the wavy line
                      ...levels.asMap().entries.map((entry) {
                        int index = entry.key;
                        
                        // Calculate the DISPLAYED level number (what user sees)
                        int displayedLevelNumber = totalLevels - index;
                        
                        // Get level status for styling
                        LevelStatus levelStatus = LevelProgressController.getLevelStatus(displayedLevelNumber);
                        
                        // Calculate exact position on the wavy line
                        final position = _calculateExactLevelPosition(
                          index,
                          size.width,
                        );

                        return Positioned(
                          left: position.dx - 30, // Center the 60px button
                          top: position.dy - 30, // Center the 60px button
                          child: GestureDetector(
                            onTap: () => _handleLevelTap(displayedLevelNumber, levelStatus),
                            child: Transform.rotate(
                              angle: _degreesToRadians(-10),
                              child: _buildLevelButton(displayedLevelNumber, levelStatus),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
              ),
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
                        onPressed: () => Go.freshStartTo(AppRoutes.start),
                        icon: const Icon(Icons.home,
                          color: Colors.white,
                          size: 24,
                        ),
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
                          // Open the settings drawer from right to left
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        icon: const Icon(Icons.settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle level button tap based on level status
  void _handleLevelTap(int levelNumber, LevelStatus status) {
    switch (status) {
      case LevelStatus.locked:
        // Show locked message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete previous levels to unlock Level $levelNumber'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
        
      case LevelStatus.completed:
      case LevelStatus.current:
      case LevelStatus.unlocked:
        // Navigate to game - now supports all 20 levels
        if (levelNumber <= GameData.getLevels().length) {
          // Use actual game data for available levels
          final gameLevel = GameData.getLevels()[levelNumber - 1];
          Go.sailTo(AppRoutes.game, arguments: {
            "level": gameLevel, 
            "scaffoldKey": _scaffoldKey
          });
        } else {
          // Show coming soon for levels beyond available game data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Level $levelNumber coming soon!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        break;
    }
  }

  /// Build level button with appropriate styling based on status
  Widget _buildLevelButton(int levelNumber, LevelStatus status) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Widget? statusIcon;

    switch (status) {
      case LevelStatus.completed:
        backgroundColor = const Color(0xff00AA00); // Green for completed
        borderColor = const Color(0xff008800);
        textColor = Colors.white;
        statusIcon = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
        
      case LevelStatus.current:
        backgroundColor = const Color(0xff007400); // Primary color for current level
        borderColor = Colors.black54;
        textColor = Colors.white;
        break;
        
      case LevelStatus.unlocked:
        backgroundColor = Colors.white; // White for unlocked
        borderColor = const Color(0xff007400);
        textColor = Colors.black;
        break;
        
      case LevelStatus.locked:
        backgroundColor = Colors.grey.shade400; // Grey for locked
        borderColor = Colors.grey.shade600;
        textColor = Colors.grey.shade700;
        statusIcon = Icon(Icons.lock, color: Colors.grey.shade700, size: 16);
        break;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
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
          color: backgroundColor,
          border: Border.all(
            color: backgroundColor,
          ),
        ),
        child: Center(
          child: statusIcon ?? Text(
            '$levelNumber',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // Generate 20 levels (using existing game levels + placeholders)
  List<GameLevel> _generateLevels() {
    final existingLevels = GameData.getLevels();
    List<GameLevel> allLevels = [];

    for (int i = 1; i <= totalLevels; i++) {
      if (i <= existingLevels.length) {
        allLevels.add(existingLevels[i - 1]);
      } else {
        // Create placeholder levels for future content
        allLevels.add(GameLevel(
          level: i,
          words: ['PLACEHOLDER'],
          grid: List.generate(7, (i) => List.generate(7, (j) => 'A')),
          backgroundImage: 'assets/images/placeholder_bg.jpg',
        ));
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
    final y1 = waveHeight * (index + 0.5); // Control point Y (where the button should be)
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

// Custom painter remains the same
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