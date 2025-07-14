import 'package:flutter/material.dart';
import '../../models/game_models.dart';

class WordList extends StatelessWidget {
  final List<WordToFind> wordsToFind;
  final ValueNotifier<List<String>> foundWordsNotifier;

  const WordList({
    super.key, 
    required this.wordsToFind,
    required this.foundWordsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: foundWordsNotifier,
      builder: (context, foundWords, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: wordsToFind.map((wordToFind) {
            final isFound = foundWords.contains(wordToFind.word);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isFound
                    ? wordToFind.color.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFound ? wordToFind.color : Colors.grey.withOpacity(0.5), 
                  width: 2
                ),
                boxShadow: isFound ? [
                  BoxShadow(
                    color: wordToFind.color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isFound ? Colors.white : Colors.black87,
                  decoration: isFound
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white,
                  decorationThickness: 2,
                ),
                child: Text(wordToFind.word),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
