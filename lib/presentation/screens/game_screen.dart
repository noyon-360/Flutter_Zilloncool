import 'package:flutter/material.dart';
import 'package:flutx_core/core/routes/services/go_next_navigation.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:word_game/constants/app_colors.dart';
import 'package:word_game/presentation/controllers/level_progress_controller.dart';
import 'package:word_game/presentation/widgets/icon_button_widget.dart';
import 'package:word_game/routes/generate_routes.dart';
import '../../data/game_data.dart';
import '../../models/game_models.dart';
import '../controllers/sound_controller.dart';
import '../drawer/custom_drawer.dart';
import '../widgets/word_grid.dart';
import '../widgets/word_list.dart';

class GameScreen extends StatefulWidget {
  final GameLevel level;
  // final GlobalKey<ScaffoldState> scaffoldKey;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameLevel currentLevel;
  late List<WordToFind> wordsToFind;
  late DragSelection dragSelection;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Value Notifiers for state management
  final ValueNotifier<List<List<GridPosition>>> foundWordPositionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> isCompleteNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isHintActiveNotifier = ValueNotifier(false);
  final ValueNotifier<WordToFind?> currentHintWordNotifier = ValueNotifier(
    null,
  );
  final ValueNotifier<List<GridPosition>> hintPositionsNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<int> hintStepNotifier = ValueNotifier(0);
  final ValueNotifier<int> currentHintLetterIndexNotifier = ValueNotifier(0);
  final ValueNotifier<List<String>> foundWordsNotifier = ValueNotifier([]);

  // Add ValueNotifier for grid to make it reactive
  final ValueNotifier<List<List<String>>> gridNotifier = ValueNotifier([]);

  // Enhanced sound controller
  final SoundController _soundController = SoundController();

  // Animation controllers
  late AnimationController _hintAnimationController;
  late AnimationController _flashAnimationController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    _initializeGame();
    _initializeAnimations();
    _initializeSound();
  }

  void _initializeAnimations() {
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _initializeSound() async {
    await _soundController.initialize();
  }

  void _initializeGame() {
    wordsToFind = GameData.createWordsToFind(currentLevel.words);
    dragSelection = DragSelection();
    foundWordPositionsNotifier.value = [];
    isCompleteNotifier.value = false;
    foundWordsNotifier.value = [];

    // Update grid notifier with new grid data - this triggers the rebuild
    gridNotifier.value = List.from(
      currentLevel.grid.map((row) => List<String>.from(row)),
    );

    // Reset hint system
    isHintActiveNotifier.value = false;
    currentHintWordNotifier.value = null;
    hintPositionsNotifier.value = [];
    hintStepNotifier.value = 0;
    currentHintLetterIndexNotifier.value = 0;
  }

  void _refreshGame() async {
    await _soundController.playGameRefresh();

    // Get new level with refreshed grid
    currentLevel = GameData.refreshLevel(currentLevel);

    // Reinitialize game with new data
    _initializeGame();

    print('🎮 Game refreshed! New word positions generated.');
  }

  @override
  void dispose() {
    foundWordPositionsNotifier.dispose();
    isCompleteNotifier.dispose();
    isHintActiveNotifier.dispose();
    currentHintWordNotifier.dispose();
    hintPositionsNotifier.dispose();
    hintStepNotifier.dispose();
    currentHintLetterIndexNotifier.dispose();
    foundWordsNotifier.dispose();
    gridNotifier.dispose(); // Don't forget to dispose the new notifier
    _hintAnimationController.dispose();
    _flashAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/game_screen_bg.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0), Color(0xFFB8D4F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButtonWidget(
                      icon: Icons.arrow_back,
                      onTap: () async {
                        await _soundController.playButtonSound();
                        Go.freshStartTo(AppRoutes.lavel);
                      },
                    ),
                    Container(
                      padding: AppSizes.paddingXl.symmetric(
                        horizontal: 46.5,
                        vertical: 8.5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.primaryBgColor,
                      ),
                      child: Text(
                        'Level ${currentLevel.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButtonWidget(
                      icon: Icons.settings,
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      // {
                      //   // await _soundController.playButtonSound();
                      //   // Go.backtrack();
                      //   // Open the settings drawer from right to left

                      // },
                    ),
                  ],
                ),
              ),
              Gap.bottomBarGap,
              // Word list or completion message
              ValueListenableBuilder<bool>(
                valueListenable: isCompleteNotifier,
                builder: (context, isComplete, child) {
                  return SizedBox(
                    child: isComplete
                        ? _buildCompletionWidget()
                        : _buildWordListWidget(),
                  );
                },
              ),
              // Enhanced Game grid with ValueListenableBuilder for reactive updates
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.6 * 255).toInt()),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<List<List<String>>>(
                  valueListenable: gridNotifier,
                  builder: (context, grid, child) {
                    return WordGrid(
                      grid: grid, // Use the reactive grid data
                      wordsToFind: wordsToFind,
                      dragSelection: dragSelection,
                      onWordFound: _onWordFound,
                      foundWordPositionsNotifier: foundWordPositionsNotifier,
                      soundController: _soundController,
                      // Hint data
                      isHintActiveNotifier: isHintActiveNotifier,
                      currentHintWordNotifier: currentHintWordNotifier,
                      hintPositionsNotifier: hintPositionsNotifier,
                      hintStepNotifier: hintStepNotifier,
                      currentHintLetterIndexNotifier:
                          currentHintLetterIndexNotifier,
                      hintAnimationController: _hintAnimationController,
                      flashAnimationController: _flashAnimationController,
                    );
                  },
                ),
              ),
              // Control buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isCompleteNotifier,
                  builder: (context, isComplete, child) {
                    return isComplete
                        ? _buildNextLevelButton()
                        : _buildControlButtons();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionWidget() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_celebrationController.value * 0.1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Image.asset("assets/congratulations.png"),
          ),
        );
      },
    );
  }

  Widget _buildWordListWidget() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            gradient: LinearGradient(
              stops: [0.1, 0.2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryGradient, AppColors.primary],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Center(
            child: Padding(
              padding: AppSizes.paddingSm.vertical,
              child: Text(
                "WRITTEN",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha((0.2 * 255).toInt()),
                      offset: Offset(1, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.6 * 255).toInt()),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: WordList(
            wordsToFind: wordsToFind,
            foundWordsNotifier: foundWordsNotifier,
          ),
        ),
      ],
    );
  }

  // Also update the _buildNextLevelButton method:
  Widget _buildNextLevelButton() {
    return InkWell(
      onTap: () async {
        await _soundController.playButtonSound();

        if (!mounted) return;

        // Get next level number
        final nextLevelNumber = currentLevel.level + 1;

        // Check if next level exists in game data
        if (nextLevelNumber <= GameData.getLevels().length) {
          final nextLevel = GameData.getLevels()[nextLevelNumber - 1];
          Go.swapTo(AppRoutes.game, arguments: {"level": nextLevel});
        } else {
          // No more levels available, go back to level selection
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Congratulations! You completed all available levels!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Go.backtrack();
        }
      },
      child: SizedBox(
        height: 34,
        width: 116,
        child: Image.asset("assets/next_level_button.png"),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: isHintActiveNotifier,
          builder: (context, isHintActive, child) {
            return IconButtonWidget(
              icon: isHintActive
                  ? Icons.hourglass_top
                  : Icons.lightbulb_outline,
              onTap: isHintActive ? null : _showHint,
              iconColor: isHintActive ? Colors.grey : Colors.white,
            );
          },
        ),
        Gap.w16,
        // Add visual feedback for refresh button
        ValueListenableBuilder<bool>(
          valueListenable: isHintActiveNotifier,
          builder: (context, isHintActive, child) {
            return IconButtonWidget(
              icon: Icons.refresh,
              onTap: isHintActive ? null : _refreshGame, // Disable during hint
              iconColor: isHintActive ? Colors.grey : Colors.white,
            );
          },
        ),
      ],
    );
  }

  void _onWordFound(WordToFind word, List<GridPosition> positions) async {
    await _soundController.playWordFound();
    word.isFound = true;
    word.foundPositions = positions;

    final currentFoundPositions = List<List<GridPosition>>.from(
      foundWordPositionsNotifier.value,
    );
    currentFoundPositions.add(positions);
    foundWordPositionsNotifier.value = currentFoundPositions;

    // Update found words list
    final currentFoundWords = List<String>.from(foundWordsNotifier.value);
    currentFoundWords.add(word.word);
    foundWordsNotifier.value = currentFoundWords;

    // Check if all words are found
    if (wordsToFind.every((w) => w.isFound)) {
      isCompleteNotifier.value = true;
      await _soundController.playLevelComplete();
      _celebrationController.forward();

      // 🔥 NEW: Save level completion progress
      await LevelProgressController.completeLevel(currentLevel.level);

      print('🎉 Level ${currentLevel.level} completed and saved!');
    } else {
      await _soundController.playWordMatch();
    }
  }

  void _showHint() async {
    await _soundController.playHintActivate();
    List<WordToFind> unMatchedWords = wordsToFind
        .where((w) => !w.isFound)
        .toList();
    if (unMatchedWords.isEmpty) return;

    unMatchedWords.shuffle();
    WordToFind selectedWord = unMatchedWords.first;
    List<GridPosition> wordPositions = _findWordInGrid(selectedWord.word);
    if (wordPositions.isEmpty) return;

    isHintActiveNotifier.value = true;
    currentHintWordNotifier.value = selectedWord;
    hintPositionsNotifier.value = wordPositions;
    hintStepNotifier.value = 1;
    currentHintLetterIndexNotifier.value = 0;

    await _animateLetterByLetter();
    await _flashAllLetters();

    isHintActiveNotifier.value = false;
    currentHintWordNotifier.value = null;
    hintPositionsNotifier.value = [];
    hintStepNotifier.value = 0;
    currentHintLetterIndexNotifier.value = 0;
  }

  Future<void> _animateLetterByLetter() async {
    final positions = hintPositionsNotifier.value;
    for (int i = 0; i < positions.length; i++) {
      currentHintLetterIndexNotifier.value = i;
      await _soundController.playHintReveal();
      _hintAnimationController.reset();
      await _hintAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _flashAllLetters() async {
    hintStepNotifier.value = 2;
    for (int i = 0; i < 3; i++) {
      _flashAnimationController.reset();
      await _flashAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  List<GridPosition> _findWordInGrid(String word) {
    List<List<int>> directions = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];

    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        for (List<int> direction in directions) {
          List<GridPosition> positions = _checkWordAtPosition(
            word,
            row,
            col,
            direction[0],
            direction[1],
          );
          if (positions.isNotEmpty) {
            return positions;
          }
        }
      }
    }
    return [];
  }

  List<GridPosition> _checkWordAtPosition(
    String word,
    int startRow,
    int startCol,
    int deltaRow,
    int deltaCol,
  ) {
    List<GridPosition> positions = [];
    for (int i = 0; i < word.length; i++) {
      int row = startRow + i * deltaRow;
      int col = startCol + i * deltaCol;
      if (row < 0 || row >= 7 || col < 0 || col >= 7) {
        return [];
      }
      if (currentLevel.grid[row][col] != word[i]) {
        return [];
      }
      positions.add(GridPosition(row, col));
    }
    return positions;
  }
}
