import 'package:flutter/material.dart';

import '../../models/game_models.dart';

class WordList extends StatelessWidget {
  final List<WordToFind> wordsToFind;

  const WordList({super.key, required this.wordsToFind});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wordsToFind.map((wordToFind) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          // decoration: BoxDecoration(
          //   color: wordToFind.isFound
          //       ? wordToFind.color.withOpacity(0.8)
          //       : Colors.grey.withOpacity(0.2),
          //   borderRadius: BorderRadius.circular(20),
          //   border: Border.all(color: wordToFind.color, width: 2),
          // ),
          child: Text(
            wordToFind.word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: wordToFind.isFound ? Colors.white : Colors.black87,
              decoration: wordToFind.isFound
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        );
      }).toList(),
    );
  }
}
