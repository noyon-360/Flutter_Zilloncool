import 'package:flutter/material.dart';

// Model for individual words to find
class WordToFind {
  final String word;
  final Color color;
  bool isFound;
  List<GridPosition>? foundPositions;

  WordToFind({
    required this.word,
    required this.color,
    this.isFound = false,
    this.foundPositions,
  });
}

// Model for grid positions
class GridPosition {
  final int row;
  final int col;

  GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPosition && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

// Model for game levels
class GameLevel {
  final int level;
  final List<String> words;
  final List<List<String>> grid;
  final String backgroundImage;

  GameLevel({
    required this.level,
    required this.words,
    required this.grid,
    required this.backgroundImage,
  });
}

// Model for drag selection
class DragSelection {
  GridPosition? startPosition;
  GridPosition? endPosition;
  List<GridPosition> selectedPositions = [];
  bool isActive = false;

  void reset() {
    startPosition = null;
    endPosition = null;
    selectedPositions.clear();
    isActive = false;
  }
}