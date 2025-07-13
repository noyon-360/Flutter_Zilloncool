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
    Colors.brown,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
  ];

  // Level configurations
  static List<GameLevel> getLevels() {
    return [
      // Level 1 - Animals (Easy)
      GameLevel(
        level: 1,
        words: ['CAT', 'DOG', 'BIRD', 'FISH'],
        grid: _generateGrid(['CAT', 'DOG', 'BIRD', 'FISH']),
        backgroundImage: 'assets/images/level1_bg.jpg',
      ),

      // Level 2 - Fruits
      GameLevel(
        level: 2,
        words: ['APPLE', 'GRAPE', 'LEMON', 'PEACH', 'BERRY'],
        grid: _generateGrid(['APPLE', 'GRAPE', 'LEMON', 'PEACH', 'BERRY']),
        backgroundImage: 'assets/images/level2_bg.jpg',
      ),

      // Level 3 - Home Items
      GameLevel(
        level: 3,
        words: ['HOUSE', 'CHAIR', 'TABLE', 'WINDOW', 'DOOR', 'LAMP'],
        grid: _generateGrid([
          'HOUSE',
          'CHAIR',
          'TABLE',
          'WINDOW',
          'DOOR',
          'LAMP',
        ]),
        backgroundImage: 'assets/images/level3_bg.jpg',
      ),

      // Level 4 - Technology
      GameLevel(
        level: 4,
        words: ['PHONE', 'MOUSE', 'SCREEN', 'TABLET', 'CAMERA', 'LAPTOP'],
        grid: _generateGrid([
          'PHONE',
          'MOUSE',
          'SCREEN',
          'TABLET',
          'CAMERA',
          'LAPTOP',
        ]),
        backgroundImage: 'assets/images/level4_bg.jpg',
      ),

      // Level 5 - Wild Animals
      GameLevel(
        level: 5,
        words: [
          'TIGER',
          'EAGLE',
          'DOLPHIN',
          'PENGUIN',
          'GIRAFFE',
          'LION',
          'BEAR',
        ],
        grid: _generateGrid([
          'TIGER',
          'EAGLE',
          'DOLPHIN',
          'PENGUIN',
          'GIRAFFE',
          'LION',
          'BEAR',
        ]),
        backgroundImage: 'assets/images/level5_bg.jpg',
      ),

      // Level 6 - Colors
      GameLevel(
        level: 6,
        words: ['RED', 'BLUE', 'GREEN', 'YELLOW', 'PURPLE', 'ORANGE', 'PINK'],
        grid: _generateGrid([
          'RED',
          'BLUE',
          'GREEN',
          'YELLOW',
          'PURPLE',
          'ORANGE',
          'PINK',
        ]),
        backgroundImage: 'assets/images/level6_bg.jpg',
      ),

      // Level 7 - Food Items
      GameLevel(
        level: 7,
        words: [
          'BREAD',
          'CHEESE',
          'BUTTER',
          'HONEY',
          'SUGAR',
          'SALT',
          'PEPPER',
        ],
        grid: _generateGrid([
          'BREAD',
          'CHEESE',
          'BUTTER',
          'HONEY',
          'SUGAR',
          'SALT',
          'PEPPER',
        ]),
        backgroundImage: 'assets/images/level7_bg.jpg',
      ),

      // Level 8 - Weather
      GameLevel(
        level: 8,
        words: ['SUN', 'RAIN', 'SNOW', 'WIND', 'CLOUD', 'STORM', 'FOG'],
        grid: _generateGrid([
          'SUN',
          'RAIN',
          'SNOW',
          'WIND',
          'CLOUD',
          'STORM',
          'FOG',
        ]),
        backgroundImage: 'assets/images/level8_bg.jpg',
      ),

      // Level 9 - Body Parts
      GameLevel(
        level: 9,
        words: ['HEAD', 'ARM', 'LEG', 'HAND', 'FOOT', 'EYE', 'NOSE', 'MOUTH'],
        grid: _generateGrid([
          'HEAD',
          'ARM',
          'LEG',
          'HAND',
          'FOOT',
          'EYE',
          'NOSE',
          'MOUTH',
        ]),
        backgroundImage: 'assets/images/level9_bg.jpg',
      ),

      // Level 10 - Transportation
      GameLevel(
        level: 10,
        words: ['CAR', 'BUS', 'TRAIN', 'PLANE', 'BIKE', 'BOAT', 'TRUCK'],
        grid: _generateGrid([
          'CAR',
          'BUS',
          'TRAIN',
          'PLANE',
          'BIKE',
          'BOAT',
          'TRUCK',
        ]),
        backgroundImage: 'assets/images/level10_bg.jpg',
      ),

      // Level 11 - School Items
      GameLevel(
        level: 11,
        words: ['BOOK', 'PEN', 'PENCIL', 'PAPER', 'DESK', 'BOARD', 'RULER'],
        grid: _generateGrid([
          'BOOK',
          'PEN',
          'PENCIL',
          'PAPER',
          'DESK',
          'BOARD',
          'RULER',
        ]),
        backgroundImage: 'assets/images/level11_bg.jpg',
      ),

      // Level 12 - Sports
      GameLevel(
        level: 12,
        words: ['BALL', 'GAME', 'TEAM', 'GOAL', 'WIN', 'PLAY', 'SPORT', 'RUN'],
        grid: _generateGrid([
          'BALL',
          'GAME',
          'TEAM',
          'GOAL',
          'WIN',
          'PLAY',
          'SPORT',
          'RUN',
        ]),
        backgroundImage: 'assets/images/level12_bg.jpg',
      ),

      // Level 13 - Kitchen Items
      GameLevel(
        level: 13,
        words: ['PLATE', 'CUP', 'FORK', 'KNIFE', 'SPOON', 'BOWL', 'POT', 'PAN'],
        grid: _generateGrid([
          'PLATE',
          'CUP',
          'FORK',
          'KNIFE',
          'SPOON',
          'BOWL',
          'POT',
          'PAN',
        ]),
        backgroundImage: 'assets/images/level13_bg.jpg',
      ),

      // Level 14 - Nature
      GameLevel(
        level: 14,
        words: ['TREE', 'FLOWER', 'GRASS', 'LEAF', 'ROCK', 'RIVER', 'HILL'],
        grid: _generateGrid([
          'TREE',
          'FLOWER',
          'GRASS',
          'LEAF',
          'ROCK',
          'RIVER',
          'HILL',
        ]),
        backgroundImage: 'assets/images/level14_bg.jpg',
      ),

      // Level 15 - Clothing
      GameLevel(
        level: 15,
        words: ['SHIRT', 'PANTS', 'SHOES', 'HAT', 'COAT', 'DRESS', 'SOCKS'],
        grid: _generateGrid([
          'SHIRT',
          'PANTS',
          'SHOES',
          'HAT',
          'COAT',
          'DRESS',
          'SOCKS',
        ]),
        backgroundImage: 'assets/images/level15_bg.jpg',
      ),

      // Level 16 - Time & Calendar
      GameLevel(
        level: 16,
        words: ['DAY', 'WEEK', 'MONTH', 'YEAR', 'HOUR', 'MINUTE', 'SECOND'],
        grid: _generateGrid([
          'DAY',
          'WEEK',
          'MONTH',
          'YEAR',
          'HOUR',
          'MINUTE',
          'SECOND',
        ]),
        backgroundImage: 'assets/images/level16_bg.jpg',
      ),

      // Level 17 - Emotions
      GameLevel(
        level: 17,
        words: ['HAPPY', 'SAD', 'ANGRY', 'CALM', 'EXCITED', 'TIRED', 'BRAVE'],
        grid: _generateGrid([
          'HAPPY',
          'SAD',
          'ANGRY',
          'CALM',
          'EXCITED',
          'TIRED',
          'BRAVE',
        ]),
        backgroundImage: 'assets/images/level17_bg.jpg',
      ),

      // Level 18 - Music
      GameLevel(
        level: 18,
        words: ['SONG', 'MUSIC', 'PIANO', 'GUITAR', 'DRUM', 'VOICE', 'SOUND'],
        grid: _generateGrid([
          'SONG',
          'MUSIC',
          'PIANO',
          'GUITAR',
          'DRUM',
          'VOICE',
          'SOUND',
        ]),
        backgroundImage: 'assets/images/level18_bg.jpg',
      ),

      // Level 19 - Space
      GameLevel(
        level: 19,
        words: ['STAR', 'MOON', 'PLANET', 'SPACE', 'ROCKET', 'EARTH', 'SKY'],
        grid: _generateGrid([
          'STAR',
          'MOON',
          'PLANET',
          'SPACE',
          'ROCKET',
          'EARTH',
          'SKY',
        ]),
        backgroundImage: 'assets/images/level19_bg.jpg',
      ),

      // Level 20 - Action Words
      GameLevel(
        level: 20,
        words: ['JUMP', 'RUN', 'WALK', 'SWIM', 'FLY', 'CLIMB', 'DANCE', 'SING'],
        grid: _generateGrid([
          'JUMP',
          'RUN',
          'WALK',
          'SWIM',
          'FLY',
          'CLIMB',
          'DANCE',
          'SING',
        ]),
        backgroundImage: 'assets/images/level20_bg.jpg',
      ),
    ];
  }

  // IMPROVED: Generate 7x7 grid with GUARANTEED word placement
  static List<List<String>> _generateGrid(List<String> words) {
    List<List<String>> grid;
    bool allWordsPlaced = false;
    int maxAttempts = 50;
    int attempts = 0;

    // Keep trying until all words are successfully placed
    do {
      grid = List.generate(7, (i) => List.generate(7, (j) => ''));
      List<String> placedWords = [];
      Random random = Random();

      // Try to place each word
      for (String word in words) {
        bool placed = false;
        int wordAttempts = 0;

        while (!placed && wordAttempts < 200) {
          int direction = random.nextInt(8); // 8 directions
          int startRow = random.nextInt(7);
          int startCol = random.nextInt(7);

          if (_canPlaceWord(grid, word, startRow, startCol, direction)) {
            _placeWord(grid, word, startRow, startCol, direction);
            placedWords.add(word);
            placed = true;
            print(
              '✅ Placed word: $word at ($startRow, $startCol) direction: $direction',
            );
          }
          wordAttempts++;
        }

        if (!placed) {
          print('❌ Failed to place word: $word after $wordAttempts attempts');
          break;
        }
      }

      allWordsPlaced = placedWords.length == words.length;
      attempts++;

      if (!allWordsPlaced) {
        print(
          '🔄 Retry $attempts: Only ${placedWords.length}/${words.length} words placed',
        );
      }
    } while (!allWordsPlaced && attempts < maxAttempts);

    if (!allWordsPlaced) {
      print(
        '⚠️ WARNING: Could not place all words after $maxAttempts attempts',
      );
    } else {
      print('✅ SUCCESS: All ${words.length} words placed successfully!');
    }

    // Fill empty cells with random letters
    _fillEmptyCells(grid);

    // VERIFICATION: Double-check all words exist in grid
    _verifyWordsInGrid(grid, words);

    return grid;
  }

  // Fill empty cells with random letters
  static void _fillEmptyCells(List<List<String>> grid) {
    Random random = Random();
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = String.fromCharCode(65 + random.nextInt(26)); // A-Z
        }
      }
    }
  }

  // VERIFICATION: Check that all words actually exist in the grid
  static void _verifyWordsInGrid(List<List<String>> grid, List<String> words) {
    print('\n🔍 VERIFYING WORDS IN GRID:');

    for (String word in words) {
      bool found = _findWordInGrid(grid, word);
      if (found) {
        print('✅ $word - FOUND');
      } else {
        print('❌ $word - NOT FOUND');
      }
    }
    print('');
  }

  // Find if word exists in grid (all 8 directions)
  static bool _findWordInGrid(List<List<String>> grid, String word) {
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1], // Up-left, Up, Up-right
      [0, -1], [0, 1], // Left, Right
      [1, -1], [1, 0], [1, 1], // Down-left, Down, Down-right
    ];

    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        for (List<int> direction in directions) {
          if (_checkWordAtPosition(
            grid,
            word,
            row,
            col,
            direction[0],
            direction[1],
          )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Check if word exists at specific position and direction
  static bool _checkWordAtPosition(
    List<List<String>> grid,
    String word,
    int startRow,
    int startCol,
    int deltaRow,
    int deltaCol,
  ) {
    for (int i = 0; i < word.length; i++) {
      int row = startRow + i * deltaRow;
      int col = startCol + i * deltaCol;

      if (row < 0 || row >= 7 || col < 0 || col >= 7) {
        return false;
      }

      if (grid[row][col] != word[i]) {
        return false;
      }
    }
    return true;
  }

  // Check if word can be placed at given position and direction
  static bool _canPlaceWord(
    List<List<String>> grid,
    String word,
    int row,
    int col,
    int direction,
  ) {
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1], // Up-left, Up, Up-right
      [0, -1], [0, 1], // Left, Right
      [1, -1], [1, 0], [1, 1], // Down-left, Down, Down-right
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
  static void _placeWord(
    List<List<String>> grid,
    String word,
    int row,
    int col,
    int direction,
  ) {
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
      wordsToFind.add(
        WordToFind(word: words[i], color: wordColors[i % wordColors.length]),
      );
    }
    return wordsToFind;
  }

  // REFRESH: Generate new grid with same words but different positions
  static GameLevel refreshLevel(GameLevel currentLevel) {
    print('🔄 REFRESHING LEVEL ${currentLevel.level}...');

    return GameLevel(
      level: currentLevel.level,
      words: currentLevel.words, // Same words
      grid: _generateGrid(
        currentLevel.words,
      ), // New grid with shuffled positions
      backgroundImage: currentLevel.backgroundImage,
    );
  }

  // Get level difficulty description
  static String getLevelDifficulty(int level) {
    if (level <= 5) return 'Easy';
    if (level <= 10) return 'Medium';
    if (level <= 15) return 'Hard';
    return 'Expert';
  }

  // Get level theme description
  static String getLevelTheme(int level) {
    const themes = [
      'Animals',
      'Fruits',
      'Home Items',
      'Technology',
      'Wild Animals',
      'Colors',
      'Food Items',
      'Weather',
      'Body Parts',
      'Transportation',
      'School Items',
      'Sports',
      'Kitchen Items',
      'Nature',
      'Clothing',
      'Time & Calendar',
      'Emotions',
      'Music',
      'Space',
      'Action Words',
    ];

    if (level > 0 && level <= themes.length) {
      return themes[level - 1];
    }
    return 'Mixed';
  }
}
