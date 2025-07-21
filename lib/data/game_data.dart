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

  // Word pools organized by difficulty and theme
  static const Map<String, List<String>> wordPools = {
    // Easy words (3-4 letters) - Levels 1-200
    'animals_easy': ['CAT', 'DOG', 'BIRD', 'FISH', 'BEAR', 'LION', 'FROG', 'DUCK'],
    'fruits_easy': ['APPLE', 'GRAPE', 'LEMON', 'PEACH', 'BERRY', 'PLUM', 'PEAR'],
    'colors_easy': ['RED', 'BLUE', 'GREEN', 'PINK', 'GOLD', 'GRAY', 'BROWN'],
    'home_easy': ['CHAIR', 'TABLE', 'DOOR', 'LAMP', 'SOFA', 'DESK', 'WALL'],
    
    // Medium words (4-6 letters) - Levels 201-600
    'animals_medium': ['TIGER', 'EAGLE', 'DOLPHIN', 'PENGUIN', 'GIRAFFE', 'RABBIT', 'MONKEY', 'TURTLE'],
    'nature_medium': ['FLOWER', 'FOREST', 'RIVER', 'MOUNTAIN', 'OCEAN', 'DESERT', 'VALLEY'],
    'food_medium': ['BREAD', 'CHEESE', 'BUTTER', 'HONEY', 'SUGAR', 'PEPPER', 'COOKIE'],
    'tech_medium': ['PHONE', 'LAPTOP', 'CAMERA', 'TABLET', 'SCREEN', 'MOUSE', 'KEYBOARD'],
    
    // Hard words (5-7 letters) - Levels 601-1000+
    'science_hard': ['PHYSICS', 'BIOLOGY', 'CHEMISTRY', 'GEOLOGY', 'ASTRONOMY', 'ECOLOGY'],
    'emotions_hard': ['HAPPINESS', 'SADNESS', 'EXCITEMENT', 'CALMNESS', 'BRAVERY', 'KINDNESS'],
    'actions_hard': ['RUNNING', 'JUMPING', 'SWIMMING', 'CLIMBING', 'DANCING', 'SINGING'],
    'abstract_hard': ['FREEDOM', 'JUSTICE', 'WISDOM', 'COURAGE', 'PATIENCE', 'STRENGTH'],
  };

  // Theme configurations for different level ranges
  static const Map<String, ThemeConfig> themeConfigs = {
    'Basic Animals': ThemeConfig(['animals_easy'], 'assets/images/animals_bg.jpg'),
    'Colorful World': ThemeConfig(['colors_easy'], 'assets/images/colors_bg.jpg'),
    'Home Sweet Home': ThemeConfig(['home_easy'], 'assets/images/home_bg.jpg'),
    'Fruit Garden': ThemeConfig(['fruits_easy'], 'assets/images/fruits_bg.jpg'),
    'Wild Kingdom': ThemeConfig(['animals_medium'], 'assets/images/wild_bg.jpg'),
    'Nature Explorer': ThemeConfig(['nature_medium'], 'assets/images/nature_bg.jpg'),
    'Food Lover': ThemeConfig(['food_medium'], 'assets/images/food_bg.jpg'),
    'Tech World': ThemeConfig(['tech_medium'], 'assets/images/tech_bg.jpg'),
    'Science Lab': ThemeConfig(['science_hard'], 'assets/images/science_bg.jpg'),
    'Emotion Journey': ThemeConfig(['emotions_hard'], 'assets/images/emotions_bg.jpg'),
    'Action Pack': ThemeConfig(['actions_hard'], 'assets/images/actions_bg.jpg'),
    'Abstract Thinking': ThemeConfig(['abstract_hard'], 'assets/images/abstract_bg.jpg'),
  };

  // Cache for generated levels (LRU cache with max 50 levels)
  static final Map<int, GameLevel> _levelCache = {};
  static final List<int> _cacheOrder = [];
  static const int _maxCacheSize = 50;

  /// Generate a specific level dynamically
  static GameLevel generateLevel(int levelNumber) {
    // Check cache first
    if (_levelCache.containsKey(levelNumber)) {
      _moveToFront(levelNumber);
      return _levelCache[levelNumber]!;
    }

    // Generate new level
    final level = _createLevel(levelNumber);
    
    // Add to cache with LRU management
    _addToCache(levelNumber, level);
    
    return level;
  }

  /// Create a level based on level number
  static GameLevel _createLevel(int levelNumber) {
    // Use level number as seed for consistent generation
    final random = Random(levelNumber);
    
    // Determine difficulty and theme based on level
    final difficulty = _getDifficultyForLevel(levelNumber);
    final theme = _getThemeForLevel(levelNumber, random);
    final wordCount = _getWordCountForLevel(levelNumber);
    
    // Get words for this level
    final words = _generateWordsForLevel(levelNumber, theme, wordCount, random);
    
    // Generate grid with words placed
    final grid = _generateOptimizedGrid(words, random);
    
    return GameLevel(
      level: levelNumber,
      words: words,
      grid: grid,
      backgroundImage: themeConfigs[theme]?.backgroundImage ?? 'assets/images/default_bg.jpg',
    );
  }

  /// Determine difficulty based on level number
  static String _getDifficultyForLevel(int levelNumber) {
    if (levelNumber <= 200) return 'easy';
    if (levelNumber <= 600) return 'medium';
    return 'hard';
  }

  /// Get theme for level with rotation
  static String _getThemeForLevel(int levelNumber, Random random) {
    final difficulty = _getDifficultyForLevel(levelNumber);
    final availableThemes = themeConfigs.entries
        .where((entry) => entry.value.wordPools.any((pool) => pool.contains(difficulty)))
        .map((entry) => entry.key)
        .toList();
    
    // Rotate themes based on level number to ensure variety
    final themeIndex = (levelNumber ~/ 10) % availableThemes.length;
    return availableThemes[themeIndex];
  }

  /// Get word count based on level (progressive difficulty)
  static int _getWordCountForLevel(int levelNumber) {
    if (levelNumber <= 50) return 4;
    if (levelNumber <= 150) return 5;
    if (levelNumber <= 300) return 6;
    if (levelNumber <= 500) return 7;
    if (levelNumber <= 750) return 8;
    return 9; // Maximum 9 words for highest levels
  }

  /// Generate words for a specific level
  static List<String> _generateWordsForLevel(int levelNumber, String theme, int wordCount, Random random) {
    final themeConfig = themeConfigs[theme]!;
    final allWords = <String>[];
    
    // Collect all words from theme's word pools
    for (final poolName in themeConfig.wordPools) {
      allWords.addAll(wordPools[poolName] ?? []);
    }
    
    // Shuffle with level-specific seed for consistency
    allWords.shuffle(random);
    
    // Select required number of words
    final selectedWords = allWords.take(wordCount).toList();
    
    // If not enough words, add from other pools of same difficulty
    if (selectedWords.length < wordCount) {
      final difficulty = _getDifficultyForLevel(levelNumber);
      final additionalWords = <String>[];
      
      for (final entry in wordPools.entries) {
        if (entry.key.contains(difficulty)) {
          additionalWords.addAll(entry.value);
        }
      }
      
      additionalWords.shuffle(random);
      
      for (final word in additionalWords) {
        if (!selectedWords.contains(word) && selectedWords.length < wordCount) {
          selectedWords.add(word);
        }
      }
    }
    
    return selectedWords;
  }

  /// Optimized grid generation with better word placement algorithm
  static List<List<String>> _generateOptimizedGrid(List<String> words, Random random) {
    List<List<String>> grid;
    bool allWordsPlaced = false;
    int maxAttempts = 20; // Reduced attempts for better performance
    int attempts = 0;

    do {
      grid = List.generate(7, (i) => List.generate(7, (j) => ''));
      List<String> placedWords = [];

      // Sort words by length (longer words first for better placement)
      final sortedWords = List<String>.from(words)..sort((a, b) => b.length.compareTo(a.length));

      for (String word in sortedWords) {
        bool placed = false;
        int wordAttempts = 0;
        
        // Try different strategies for word placement
        while (!placed && wordAttempts < 100) {
          // Strategy 1: Try corners and edges first for longer words
          if (word.length >= 6 && wordAttempts < 20) {
            placed = _tryPlaceInCornerOrEdge(grid, word, random);
          }
          
          // Strategy 2: Random placement
          if (!placed) {
            int direction = random.nextInt(8);
            int startRow = random.nextInt(7);
            int startCol = random.nextInt(7);
            
            if (_canPlaceWord(grid, word, startRow, startCol, direction)) {
              _placeWord(grid, word, startRow, startCol, direction);
              placed = true;
            }
          }
          
          wordAttempts++;
        }

        if (placed) {
          placedWords.add(word);
        } else {
          break; // Failed to place this word, try regenerating
        }
      }

      allWordsPlaced = placedWords.length == words.length;
      attempts++;
    } while (!allWordsPlaced && attempts < maxAttempts);

    // Fill empty cells with random letters
    _fillEmptyCells(grid, random);

    return grid;
  }

  /// Try to place word in corners or edges (better for longer words)
  static bool _tryPlaceInCornerOrEdge(List<List<String>> grid, String word, Random random) {
    final cornerPositions = [
      [0, 0], [0, 6], [6, 0], [6, 6], // Corners
      [0, 3], [3, 0], [3, 6], [6, 3], // Edge midpoints
    ];
    
    cornerPositions.shuffle(random);
    
    for (final pos in cornerPositions) {
      for (int direction = 0; direction < 8; direction++) {
        if (_canPlaceWord(grid, word, pos[0], pos[1], direction)) {
          _placeWord(grid, word, pos[0], pos[1], direction);
          return true;
        }
      }
    }
    
    return false;
  }

  /// Check if word can be placed at given position and direction
  static bool _canPlaceWord(List<List<String>> grid, String word, int row, int col, int direction) {
    final directions = [
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

  /// Place word in the grid
  static void _placeWord(List<List<String>> grid, String word, int row, int col, int direction) {
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1],
    ];

    int dr = directions[direction][0];
    int dc = directions[direction][1];

    for (int i = 0; i < word.length; i++) {
      int newRow = row + i * dr;
      int newCol = col + i * dc;
      grid[newRow][newCol] = word[i];
    }
  }

  /// Fill empty cells with random letters
  static void _fillEmptyCells(List<List<String>> grid, Random random) {
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = String.fromCharCode(65 + random.nextInt(26)); // A-Z
        }
      }
    }
  }

  /// Cache management methods
  static void _addToCache(int levelNumber, GameLevel level) {
    if (_levelCache.length >= _maxCacheSize) {
      // Remove least recently used level
      final lruLevel = _cacheOrder.removeAt(0);
      _levelCache.remove(lruLevel);
    }
    
    _levelCache[levelNumber] = level;
    _cacheOrder.add(levelNumber);
  }

  static void _moveToFront(int levelNumber) {
    _cacheOrder.remove(levelNumber);
    _cacheOrder.add(levelNumber);
  }

  /// Create WordToFind objects with colors
  static List<WordToFind> createWordsToFind(List<String> words) {
    List<WordToFind> wordsToFind = [];
    for (int i = 0; i < words.length; i++) {
      wordsToFind.add(
        WordToFind(
          word: words[i],
          color: wordColors[i % wordColors.length],
        ),
      );
    }
    return wordsToFind;
  }

  /// Generate new grid with same words but different positions (for refresh)
  static GameLevel refreshLevel(GameLevel currentLevel) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    
    return GameLevel(
      level: currentLevel.level,
      words: currentLevel.words,
      grid: _generateOptimizedGrid(currentLevel.words, random),
      backgroundImage: currentLevel.backgroundImage,
    );
  }

  /// Get level difficulty description
  static String getLevelDifficulty(int level) {
    if (level <= 200) return 'Easy';
    if (level <= 600) return 'Medium';
    return 'Hard';
  }

  /// Get level theme description
  static String getLevelTheme(int level) {
    final random = Random(level);
    final theme = _getThemeForLevel(level, random);
    return theme;
  }

  /// Preload next few levels for smoother experience
  static void preloadLevels(int currentLevel, {int preloadCount = 3}) {
    for (int i = 1; i <= preloadCount; i++) {
      final nextLevel = currentLevel + i;
      if (!_levelCache.containsKey(nextLevel)) {
        generateLevel(nextLevel);
      }
    }
  }

  /// Clear cache (useful for memory management)
  static void clearCache() {
    _levelCache.clear();
    _cacheOrder.clear();
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'cached_levels': _levelCache.length,
      'max_cache_size': _maxCacheSize,
    };
  }
}

/// Theme configuration class
class ThemeConfig {
  final List<String> wordPools;
  final String backgroundImage;

  const ThemeConfig(this.wordPools, this.backgroundImage);
}
