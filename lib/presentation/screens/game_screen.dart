import 'package:flutter/material.dart';
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

class _GameScreenState extends State<GameScreen> {
  late List<WordToFind> wordsToFind;
  late DragSelection dragSelection;
  List<List<GridPosition>> foundWordPositions = [];

  @override
  void initState() {
    super.initState();
    wordsToFind = GameData.createWordsToFind(widget.level.words);
    dragSelection = DragSelection();
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
                    IconButton(
                      onPressed: () {
                        // Hint or help action
                      },
                      icon: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Word list to find
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: WordList(wordsToFind: wordsToFind),
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
