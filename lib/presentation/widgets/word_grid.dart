import 'package:flutter/material.dart';

import '../../models/game_models.dart';

class WordGrid extends StatefulWidget {
  final List<List<String>> grid;
  final List<WordToFind> wordsToFind;
  final DragSelection dragSelection;
  final Function(WordToFind, List<GridPosition>) onWordFound;
  final List<List<GridPosition>> foundWordPositions;

  const WordGrid({
    super.key,
    required this.grid,
    required this.wordsToFind,
    required this.dragSelection,
    required this.onWordFound,
    required this.foundWordPositions,
  });

  @override
  State<WordGrid> createState() => _WordGridState();
}

class _WordGridState extends State<WordGrid> {
  // Current word being formed during drag
  WordToFind? _currentDragWord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: GridPainter(
              grid: widget.grid,
              dragSelection: widget.dragSelection,
              foundWordPositions: widget.foundWordPositions,
              wordsToFind: widget.wordsToFind,
              currentDragWord: _currentDragWord, // Pass current drag word
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final gridPosition = _getGridPosition(localPosition, renderBox.size);

    if (gridPosition != null) {
      setState(() {
        widget.dragSelection.reset();
        widget.dragSelection.startPosition = gridPosition;
        widget.dragSelection.selectedPositions = [gridPosition];
        widget.dragSelection.isActive = true;
        _currentDragWord = null; // Reset current drag word
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.dragSelection.isActive) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final gridPosition = _getGridPosition(localPosition, renderBox.size);

    if (gridPosition != null && widget.dragSelection.startPosition != null) {
      setState(() {
        widget.dragSelection.endPosition = gridPosition;
        widget.dragSelection.selectedPositions = _getPositionsBetween(
          widget.dragSelection.startPosition!,
          gridPosition,
        );
        
        // Check if current selection matches any word and update drag word color
        _currentDragWord = _getCurrentDragWord();
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.dragSelection.selectedPositions.isNotEmpty) {
      _checkForWord();
    }
    
    setState(() {
      widget.dragSelection.reset();
      _currentDragWord = null; // Reset drag word
    });
  }

  GridPosition? _getGridPosition(Offset localPosition, Size size) {
    final cellSize = size.width / 7;
    final row = (localPosition.dy / cellSize).floor();
    final col = (localPosition.dx / cellSize).floor();

    if (row >= 0 && row < 7 && col >= 0 && col < 7) {
      return GridPosition(row, col);
    }
    return null;
  }

  List<GridPosition> _getPositionsBetween(GridPosition start, GridPosition end) {
    List<GridPosition> positions = [];
    
    int deltaRow = end.row - start.row;
    int deltaCol = end.col - start.col;
    
    // Determine if it's a valid direction (horizontal, vertical, or diagonal)
    if (deltaRow == 0 || deltaCol == 0 || deltaRow.abs() == deltaCol.abs()) {
      int stepRow = deltaRow == 0 ? 0 : (deltaRow > 0 ? 1 : -1);
      int stepCol = deltaCol == 0 ? 0 : (deltaCol > 0 ? 1 : -1);
      
      int currentRow = start.row;
      int currentCol = start.col;
      
      while (true) {
        positions.add(GridPosition(currentRow, currentCol));
        
        if (currentRow == end.row && currentCol == end.col) break;
        
        currentRow += stepRow;
        currentCol += stepCol;
        
        // Safety check to prevent infinite loop
        if (currentRow < 0 || currentRow >= 7 || currentCol < 0 || currentCol >= 7) {
          break;
        }
      }
    }
    
    return positions;
  }

  // NEW METHOD: Check if current drag selection matches any word
  WordToFind? _getCurrentDragWord() {
    if (widget.dragSelection.selectedPositions.isEmpty) return null;
    
    String selectedWord = '';
    for (GridPosition pos in widget.dragSelection.selectedPositions) {
      selectedWord += widget.grid[pos.row][pos.col];
    }

    // Check if current selection matches any unfound word (forward or backward)
    for (WordToFind wordToFind in widget.wordsToFind) {
      if (!wordToFind.isFound && 
          (selectedWord == wordToFind.word || 
           selectedWord == wordToFind.word.split('').reversed.join())) {
        return wordToFind;
      }
    }
    
    return null;
  }

  void _checkForWord() {
    String selectedWord = '';
    for (GridPosition pos in widget.dragSelection.selectedPositions) {
      selectedWord += widget.grid[pos.row][pos.col];
    }

    // Check forward and backward
    for (WordToFind wordToFind in widget.wordsToFind) {
      if (!wordToFind.isFound && 
          (selectedWord == wordToFind.word || 
           selectedWord == wordToFind.word.split('').reversed.join())) {
        widget.onWordFound(wordToFind, List.from(widget.dragSelection.selectedPositions));
        break;
      }
    }
  }
}

class GridPainter extends CustomPainter {
  final List<List<String>> grid;
  final DragSelection dragSelection;
  final List<List<GridPosition>> foundWordPositions;
  final List<WordToFind> wordsToFind;
  final WordToFind? currentDragWord; // NEW: Current word being dragged

  GridPainter({
    required this.grid,
    required this.dragSelection,
    required this.foundWordPositions,
    required this.wordsToFind,
    this.currentDragWord, // NEW: Optional current drag word
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 7;
    
    // Draw found words first (background)
    for (int i = 0; i < foundWordPositions.length; i++) {
      final positions = foundWordPositions[i];
      final wordToFind = wordsToFind.firstWhere((w) => w.foundPositions == positions);
      _drawWordLine(canvas, positions, cellSize, wordToFind.color.withOpacity(0.6));
    }
    
    // Draw current selection with appropriate color
    if (dragSelection.isActive && dragSelection.selectedPositions.isNotEmpty) {
      Color dragColor;
      double opacity;
      
      if (currentDragWord != null) {
        // If dragging matches a word, use that word's color with higher opacity
        dragColor = currentDragWord!.color;
        opacity = 0.7;
      } else {
        // If dragging doesn't match any word, use blue with lower opacity
        dragColor = Colors.blue;
        opacity = 0.3;
      }
      
      _drawWordLine(canvas, dragSelection.selectedPositions, cellSize, dragColor.withOpacity(opacity));
    }
    
    // Draw grid and letters
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );
        
        // Check if this cell is part of current drag selection
        bool isInCurrentDrag = dragSelection.isActive && 
            dragSelection.selectedPositions.any((pos) => pos.row == row && pos.col == col);
        
        // Draw cell background for current selection
        if (isInCurrentDrag) {
          Color cellColor;
          if (currentDragWord != null) {
            cellColor = currentDragWord!.color.withOpacity(0.2);
          } else {
            cellColor = Colors.blue.withOpacity(0.1);
          }
          
          canvas.drawRect(
            rect,
            Paint()..color = cellColor,
          );
        }
        
        // Draw cell border
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        
        // Draw letter with enhanced style for current selection
        TextStyle letterStyle = TextStyle(
          fontSize: isInCurrentDrag ? 22 : 20, // Slightly larger for selected
          fontWeight: FontWeight.bold,
          color: isInCurrentDrag && currentDragWord != null 
              ? currentDragWord!.color.withOpacity(0.9)
              : Colors.black87,
        );
        
        textPainter.text = TextSpan(
          text: grid[row][col],
          style: letterStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            rect.center.dx - textPainter.width / 2,
            rect.center.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawWordLine(Canvas canvas, List<GridPosition> positions, double cellSize, Color color) {
    if (positions.length < 2) {
      // For single letter selection, draw a circle
      if (positions.length == 1) {
        final pos = positions[0];
        final center = Offset(
          pos.col * cellSize + cellSize / 2,
          pos.row * cellSize + cellSize / 2,
        );
        
        canvas.drawCircle(
          center,
          cellSize * 0.3,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
      return;
    }
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = cellSize * 0.6 // Slightly thinner for better visibility
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final center = Offset(
        pos.col * cellSize + cellSize / 2,
        pos.row * cellSize + cellSize / 2,
      );
      
      if (i == 0) {
        path.moveTo(center.dx, center.dy);
      } else {
        path.lineTo(center.dx, center.dy);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw circles at start and end points for better visual feedback
    if (positions.isNotEmpty) {
      final startPos = positions.first;
      final endPos = positions.last;
      
      final startCenter = Offset(
        startPos.col * cellSize + cellSize / 2,
        startPos.row * cellSize + cellSize / 2,
      );
      
      final endCenter = Offset(
        endPos.col * cellSize + cellSize / 2,
        endPos.row * cellSize + cellSize / 2,
      );
      
      // Draw start point
      canvas.drawCircle(
        startCenter,
        cellSize * 0.15,
        Paint()
          ..color = color.withOpacity(0.8)
          ..style = PaintingStyle.fill,
      );
      
      // Draw end point (only if different from start)
      if (positions.length > 1) {
        canvas.drawCircle(
          endCenter,
          cellSize * 0.15,
          Paint()
            ..color = color.withOpacity(0.8)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}