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

  // Dynamic level management
  int _currentMaxLevel = 100; // Start with 100 levels visible
  final int _levelIncrement = 50; // Load 50 more levels when needed
  final int _maxTotalLevels = 1000; // Maximum levels available

  // Performance optimization
  final double _itemHeight = 150.0; // Height per level item
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLevelProgress();
    _setupScrollListener();

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
    if (mounted) setState(() {});
  }

  /// Setup scroll listener for infinite loading
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more levels when user scrolls near the top
      if (_scrollController.position.pixels <=
          _scrollController.position.maxScrollExtent * 0.1) {
        _loadMoreLevels();
      }
    });
  }

  /// Load more levels dynamically
  void _loadMoreLevels() {
    if (_isLoading || _currentMaxLevel >= _maxTotalLevels) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay for smooth UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentMaxLevel = math.min(
            _currentMaxLevel + _levelIncrement,
            _maxTotalLevels,
          );
          _isLoading = false;
        });

        // Preload some levels for better performance
        _preloadLevels();
      }
    });
  }

  /// Preload levels for smoother experience
  void _preloadLevels() {
    final currentLevel = LevelProgressController.getCurrentLevel();
    GameData.preloadLevels(currentLevel);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
              // Optimized scrollable level selection
              CustomScrollView(
                controller: _scrollController,
                reverse: true,
                slivers: [
                  // Loading indicator at top
                  if (_isLoading)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Level grid with optimized rendering
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final levelNumber = _currentMaxLevel - index;
                      if (levelNumber <= 0) return null;

                      return _buildOptimizedLevelButton(levelNumber);
                    }, childCount: _currentMaxLevel),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
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
                        icon: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Level progress indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Level ${LevelProgressController.getCurrentLevel()} / $_maxTotalLevels',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                          _scaffoldKey.currentState?.openEndDrawer();
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
            ],
          ),
        ),
      ),
    );
  }

  /// Build optimized level button with lazy loading
  Widget _buildOptimizedLevelButton(int levelNumber) {
    final levelStatus = LevelProgressController.getLevelStatus(levelNumber);

    return GestureDetector(
      onTap: () => _handleLevelTap(levelNumber, levelStatus),
      child: Transform.rotate(
        angle: _degreesToRadians(
          -5 + (levelNumber % 3) * 5,
        ), // Slight rotation variation
        child: Container(
          decoration: BoxDecoration(
            color: _getButtonColor(levelStatus),
            shape: BoxShape.circle,
            border: Border.all(color: _getBorderColor(levelStatus), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: _getButtonContent(levelNumber, levelStatus)),
        ),
      ),
    );
  }

  /// Handle level button tap
  void _handleLevelTap(int levelNumber, LevelStatus status) {
    switch (status) {
      case LevelStatus.locked:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Complete previous levels to unlock Level $levelNumber',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        break;

      case LevelStatus.completed:
      case LevelStatus.current:
      case LevelStatus.unlocked:
        // Generate level dynamically
        final gameLevel = GameData.generateLevel(levelNumber);
        Go.sailTo(
          AppRoutes.game,
          arguments: {"level": gameLevel, "scaffoldKey": _scaffoldKey},
        );
        break;
    }
  }

  /// Get button color based on status
  Color _getButtonColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xff00AA00);
      case LevelStatus.current:
        return const Color(0xff007400);
      case LevelStatus.unlocked:
        return Colors.white;
      case LevelStatus.locked:
        return Colors.grey.shade400;
    }
  }

  /// Get border color based on status
  Color _getBorderColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xff008800);
      case LevelStatus.current:
        return Colors.black54;
      case LevelStatus.unlocked:
        return const Color(0xff007400);
      case LevelStatus.locked:
        return Colors.grey.shade600;
    }
  }

  /// Get button content based on status
  Widget _getButtonContent(int levelNumber, LevelStatus status) {
    final textColor = status == LevelStatus.unlocked
        ? Colors.black
        : Colors.white;

    switch (status) {
      case LevelStatus.completed:
        return const Icon(Icons.check, color: Colors.white, size: 20);
      case LevelStatus.locked:
        return Icon(Icons.lock, color: Colors.grey.shade700, size: 20);
      default:
        return Text(
          '$levelNumber',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        );
    }
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
