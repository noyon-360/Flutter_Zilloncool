import 'package:flutter/material.dart';
import 'package:flutx_core/core/screen/app_sizes.dart';
import 'package:flutx_core/core/theme/extensions/text_extension.dart';
import 'package:word_game/constants/app_colors.dart';
import '../../data/game_data.dart';
import '../../models/game_models.dart';
import '../widgets/word_grid.dart';
import '../widgets/word_list.dart';

class GameScreen extends StatefulWidget {
  final GameLevel level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<WordToFind> wordsToFind;
  late DragSelection dragSelection;
  List<List<GridPosition>> foundWordPositions = [];

  // Hint system variables
  bool isHintActive = false;
  WordToFind? currentHintWord;
  List<GridPosition> hintPositions = [];
  int hintStep = 0; // 0: not active, 1: letter by letter, 2: all letters flash
  int currentHintLetterIndex = 0;
  late AnimationController _hintAnimationController;
  late AnimationController _flashAnimationController;

  @override
  void initState() {
    super.initState();
    wordsToFind = GameData.createWordsToFind(widget.level.words);
    dragSelection = DragSelection();

    // Initialize hint animation controllers
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
    _flashAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Text(
                      'Level ${widget.level.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Hint button
                    IconButton(
                      onPressed: isHintActive ? null : _showHint,
                      icon: Icon(
                        Icons.lightbulb_outline,
                        color: isHintActive ? Colors.grey : Colors.yellow,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Word list to find
              SizedBox(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      // height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        gradient: LinearGradient(
                          stops: [0.1, 0.2],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryGradient,
                            AppColors.primary,
                          ],
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
                                  color: Colors.black.withAlpha(
                                    (0.2 * 255).toInt(),
                                  ),
                                  // blurRadius: ,
                                  offset: Offset(1, 5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Container(
                      // width: 400,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        // borderRadius: BorderRadius.only(
                        //   bottomLeft: Radius.circular(10),
                        //   bottomRight: Radius.circular(10),
                        // ),
                      ),
                      child: WordList(wordsToFind: wordsToFind),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: WordGrid(
                    grid: widget.level.grid,
                    wordsToFind: wordsToFind,
                    dragSelection: dragSelection,
                    onWordFound: _onWordFound,
                    foundWordPositions: foundWordPositions,
                    // Pass hint data to grid
                    isHintActive: isHintActive,
                    currentHintWord: currentHintWord,
                    hintPositions: hintPositions,
                    hintStep: hintStep,
                    currentHintLetterIndex: currentHintLetterIndex,
                    hintAnimationController: _hintAnimationController,
                    flashAnimationController: _flashAnimationController,
                  ),
                ),
              ),

              // Progress indicator
              Container(
                margin: const EdgeInsets.all(16),
                child: Text(
                  'Found: ${wordsToFind.where((w) => w.isFound).length}/${wordsToFind.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onWordFound(WordToFind word, List<GridPosition> positions) {
    setState(() {
      word.isFound = true;
      word.foundPositions = positions;
      foundWordPositions.add(positions);
    });

    // Check if all words are found
    if (wordsToFind.every((w) => w.isFound)) {
      _showCompletionDialog();
    }
  }

  // NEW: Show hint functionality
  void _showHint() async {
    // Get all unmatched words
    List<WordToFind> unMatchedWords = wordsToFind
        .where((w) => !w.isFound)
        .toList();

    if (unMatchedWords.isEmpty) return;

    // Randomly select a word to hint
    unMatchedWords.shuffle();
    WordToFind selectedWord = unMatchedWords.first;

    // Find the word positions in the grid
    List<GridPosition> wordPositions = _findWordInGrid(selectedWord.word);

    if (wordPositions.isEmpty) return;

    setState(() {
      isHintActive = true;
      currentHintWord = selectedWord;
      hintPositions = wordPositions;
      hintStep = 1;
      currentHintLetterIndex = 0;
    });

    // Step 1: Show letters one by one
    await _animateLetterByLetter();

    // Step 2: Flash all letters
    await _flashAllLetters();

    // Reset hint
    setState(() {
      isHintActive = false;
      currentHintWord = null;
      hintPositions = [];
      hintStep = 0;
      currentHintLetterIndex = 0;
    });
  }

  // Animate letters appearing one by one
  Future<void> _animateLetterByLetter() async {
    for (int i = 0; i < hintPositions.length; i++) {
      setState(() {
        currentHintLetterIndex = i;
      });

      _hintAnimationController.reset();
      await _hintAnimationController.forward();

      // Wait a bit before showing next letter
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Keep all letters visible for a moment
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Flash all letters at once
  Future<void> _flashAllLetters() async {
    setState(() {
      hintStep = 2;
    });

    // Flash 3 times
    for (int i = 0; i < 3; i++) {
      _flashAnimationController.reset();
      await _flashAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Keep visible for a moment before hiding
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  // Find word positions in the grid
  List<GridPosition> _findWordInGrid(String word) {
    // Search in all 8 directions
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1], // Up-left, Up, Up-right
      [0, -1], [0, 1], // Left, Right
      [1, -1], [1, 0], [1, 1], // Down-left, Down, Down-right
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

  // Check if word exists at specific position and direction
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

      if (widget.level.grid[row][col] != word[i]) {
        return [];
      }

      positions.add(GridPosition(row, col));
    }

    return positions;
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You completed Level ${widget.level.level}!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to level selection
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}
