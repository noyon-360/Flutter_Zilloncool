import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'dart:math';

class GameData {
  // Define colors for different words
  static const List<Color> wordColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  // Level configurations
  static List<GameLevel> getLevels() {
    return [
      GameLevel(
        level: 1,
        words: ['CAT', 'DOG', 'BIRD', 'FISH'],
        grid: _generateGrid(['CAT', 'DOG', 'BIRD', 'FISH']),
        backgroundImage: 'assets/images/level1_bg.jpg',
      ),
      GameLevel(
        level: 2,
        words: ['APPLE', 'GRAPE', 'LEMON', 'PEACH', 'BERRY'],
        grid: _generateGrid(['APPLE', 'GRAPE', 'LEMON', 'PEACH', 'BERRY']),
        backgroundImage: 'assets/images/level2_bg.jpg',
      ),
      GameLevel(
        level: 3,
        words: ['HOUSE', 'CHAIR', 'TABLE', 'WINDOW', 'DOOR', 'LAMP'],
        grid: _generateGrid(['HOUSE', 'CHAIR', 'TABLE', 'WINDOW', 'DOOR', 'LAMP']),
        backgroundImage: 'assets/images/level3_bg.jpg',
      ),
      GameLevel(
        level: 4,
        words: ['COMPUTER', 'KEYBOARD', 'MOUSE', 'SCREEN', 'PHONE', 'TABLET'],
        grid: _generateGrid(['COMPUTER', 'KEYBOARD', 'MOUSE', 'SCREEN', 'PHONE', 'TABLET']),
        backgroundImage: 'assets/images/level4_bg.jpg',
      ),
      GameLevel(
        level: 5,
        words: ['BUTTERFLY', 'ELEPHANT', 'GIRAFFE', 'PENGUIN', 'DOLPHIN', 'TIGER', 'EAGLE'],
        grid: _generateGrid(['BUTTERFLY', 'ELEPHANT', 'GIRAFFE', 'PENGUIN', 'DOLPHIN', 'TIGER', 'EAGLE']),
        backgroundImage: 'assets/images/level5_bg.jpg',
      ),
    ];
  }

  // Generate 7x7 grid with words placed randomly
  static List<List<String>> _generateGrid(List<String> words) {
    List<List<String>> grid = List.generate(7, (i) => List.generate(7, (j) => ''));
    Random random = Random();

    // Place each word in the grid
    for (String word in words) {
      bool placed = false;
      int attempts = 0;
      
      while (!placed && attempts < 100) {
        int direction = random.nextInt(8); // 8 directions
        int startRow = random.nextInt(7);
        int startCol = random.nextInt(7);
        
        if (_canPlaceWord(grid, word, startRow, startCol, direction)) {
          _placeWord(grid, word, startRow, startCol, direction);
          placed = true;
        }
        attempts++;
      }
    }

    // Fill empty cells with random letters
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = String.fromCharCode(65 + random.nextInt(26)); // A-Z
        }
      }
    }

    return grid;
  }

  // Check if word can be placed at given position and direction
  static bool _canPlaceWord(List<List<String>> grid, String word, int row, int col, int direction) {
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1], // Up-left, Up, Up-right
      [0, -1],           [0, 1],  // Left, Right
      [1, -1],  [1, 0],  [1, 1]   // Down-left, Down, Down-right
    ];

    int dr = directions[direction][0];
    int dc = directions[direction][1];

    for (int i = 0; i < word.length; i++) {
      int newRow = row + i * dr;
      int newCol = col + i * dc;

      if (newRow < 0 || newRow >= 7 || newCol < 0 || newCol >= 7) {
        return false;
      }

      if (grid[newRow][newCol].isNotEmpty && grid[newRow][newCol] != word[i]) {
        return false;
      }
    }

    return true;
  }

  // Place word in the grid
  static void _placeWord(List<List<String>> grid, String word, int row, int col, int direction) {
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];

    int dr = directions[direction][0];
    int dc = directions[direction][1];

    for (int i = 0; i < word.length; i++) {
      int newRow = row + i * dr;
      int newCol = col + i * dc;
      grid[newRow][newCol] = word[i];
    }
  }

  // Create WordToFind objects with colors
  static List<WordToFind> createWordsToFind(List<String> words) {
    List<WordToFind> wordsToFind = [];
    for (int i = 0; i < words.length; i++) {
      wordsToFind.add(WordToFind(
        word: words[i],
        color: wordColors[i % wordColors.length],
      ));
    }
    return wordsToFind;
  }
}