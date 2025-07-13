import 'package:flutter/material.dart';
import '../../models/game_models.dart';

class WordGrid extends StatefulWidget {
  final List<List<String>> grid;
  final List<WordToFind> wordsToFind;
  final DragSelection dragSelection;
  final Function(WordToFind, List<GridPosition>) onWordFound;
  final List<List<GridPosition>> foundWordPositions;

  // Hint system properties
  final bool isHintActive;
  final WordToFind? currentHintWord;
  final List<GridPosition> hintPositions;
  final int hintStep;
  final int currentHintLetterIndex;
  final AnimationController hintAnimationController;
  final AnimationController flashAnimationController;

  const WordGrid({
    super.key,
    required this.grid,
    required this.wordsToFind,
    required this.dragSelection,
    required this.onWordFound,
    required this.foundWordPositions,
    required this.isHintActive,
    required this.currentHintWord,
    required this.hintPositions,
    required this.hintStep,
    required this.currentHintLetterIndex,
    required this.hintAnimationController,
    required this.flashAnimationController,
  });

  @override
  State<WordGrid> createState() => _WordGridState();
}

class _WordGridState extends State<WordGrid> {
  WordToFind? _currentDragWord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GestureDetector(
          onPanStart: widget.isHintActive ? null : _onPanStart,
          onPanUpdate: widget.isHintActive ? null : _onPanUpdate,
          onPanEnd: widget.isHintActive ? null : _onPanEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.hintAnimationController,
              widget.flashAnimationController,
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: GridPainter(
                  grid: widget.grid,
                  dragSelection: widget.dragSelection,
                  foundWordPositions: widget.foundWordPositions,
                  wordsToFind: widget.wordsToFind,
                  currentDragWord: _currentDragWord,
                  // Hint properties
                  isHintActive: widget.isHintActive,
                  currentHintWord: widget.currentHintWord,
                  hintPositions: widget.hintPositions,
                  hintStep: widget.hintStep,
                  currentHintLetterIndex: widget.currentHintLetterIndex,
                  hintAnimation: widget.hintAnimationController.value,
                  flashAnimation: widget.flashAnimationController.value,
                ),
                child: Container(),
              );
            },
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
        _currentDragWord = null;
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
      _currentDragWord = null;
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

        if (currentRow < 0 || currentRow >= 7 || currentCol < 0 || currentCol >= 7) {
          break;
        }
      }
    }

    return positions;
  }

  WordToFind? _getCurrentDragWord() {
    if (widget.dragSelection.selectedPositions.isEmpty) return null;

    String selectedWord = '';
    for (GridPosition pos in widget.dragSelection.selectedPositions) {
      selectedWord += widget.grid[pos.row][pos.col];
    }

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
  final WordToFind? currentDragWord;

  // Hint properties
  final bool isHintActive;
  final WordToFind? currentHintWord;
  final List<GridPosition> hintPositions;
  final int hintStep;
  final int currentHintLetterIndex;
  final double hintAnimation;
  final double flashAnimation;

  GridPainter({
    required this.grid,
    required this.dragSelection,
    required this.foundWordPositions,
    required this.wordsToFind,
    this.currentDragWord,
    required this.isHintActive,
    required this.currentHintWord,
    required this.hintPositions,
    required this.hintStep,
    required this.currentHintLetterIndex,
    required this.hintAnimation,
    required this.flashAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 7;

    // Draw current selection during drag (only if not hinting)
    if (!isHintActive && dragSelection.isActive && dragSelection.selectedPositions.isNotEmpty) {
      Color dragColor;
      double opacity;

      if (currentDragWord != null) {
        dragColor = currentDragWord!.color;
        opacity = 0.7;
      } else {
        dragColor = Colors.blue;
        opacity = 0.3;
      }

      _drawDragSelection(canvas, dragSelection.selectedPositions, cellSize, dragColor.withOpacity(opacity));
    }

    // Draw hint if active
    if (isHintActive && currentHintWord != null) {
      _drawHint(canvas, cellSize);
    }

    // Draw grid letters (NO CELL BORDERS - REMOVED)
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

        // Check various states for this cell
        bool isInCurrentDrag = !isHintActive && dragSelection.isActive &&
            dragSelection.selectedPositions.any((pos) => pos.row == row && pos.col == col);
        bool isHintCell = _isHintCell(row, col);
        bool isFoundWordLetter = _isFoundWordLetter(row, col);

        // Draw cell backgrounds for current drag
        if (isInCurrentDrag) {
          Color cellColor = currentDragWord != null
              ? currentDragWord!.color.withOpacity(0.2)
              : Colors.blue.withOpacity(0.1);
          canvas.drawRect(rect, Paint()..color = cellColor);
        }

        if (isHintCell) {
          _drawHintCellBackground(canvas, rect, row, col);
        }

        // ❌ REMOVED: Cell border drawing
        // NO MORE GRID LINES/BOXES AROUND LETTERS

        // Determine letter style
        TextStyle letterStyle = const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );

        if (isInCurrentDrag && currentDragWord != null) {
          letterStyle = TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: currentDragWord!.color.withOpacity(0.9),
          );
        } else if (isHintCell) {
          letterStyle = _getHintLetterStyle(row, col);
        } else if (isFoundWordLetter) {
          letterStyle = const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          );
        }

        textPainter.text = TextSpan(text: grid[row][col], style: letterStyle);
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

    // Draw found words LINES (bottom layer)
    for (int i = 0; i < foundWordPositions.length; i++) {
      final positions = foundWordPositions[i];
      final wordToFind = wordsToFind.firstWhere((w) => w.foundPositions == positions);
      _drawFoundWordStraightLine(canvas, positions, cellSize, wordToFind.color);
    }

    // Draw WHITE LETTERS ON TOP of the lines for found words
    for (int i = 0; i < foundWordPositions.length; i++) {
      final positions = foundWordPositions[i];
      _drawWhiteLettersOnTop(canvas, positions, cellSize);
    }
  }

  // Draw white letters on top of found word lines
  void _drawWhiteLettersOnTop(Canvas canvas, List<GridPosition> positions, double cellSize) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (GridPosition pos in positions) {
      final rect = Rect.fromLTWH(
        pos.col * cellSize,
        pos.row * cellSize,
        cellSize,
        cellSize,
      );

      const whiteLetterStyle = TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      );

      textPainter.text = TextSpan(
        text: grid[pos.row][pos.col],
        style: whiteLetterStyle,
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

  // Check if cell is part of any found word
  bool _isFoundWordLetter(int row, int col) {
    for (List<GridPosition> positions in foundWordPositions) {
      if (positions.any((pos) => pos.row == row && pos.col == col)) {
        return true;
      }
    }
    return false;
  }

  // Draw found word straight line with white border
  void _drawFoundWordStraightLine(Canvas canvas, List<GridPosition> positions, double cellSize, Color color) {
    if (positions.length < 2) return;

    final firstPos = positions.first;
    final lastPos = positions.last;

    final firstCenter = Offset(
      firstPos.col * cellSize + cellSize / 2,
      firstPos.row * cellSize + cellSize / 2,
    );

    final lastCenter = Offset(
      lastPos.col * cellSize + cellSize / 2,
      lastPos.row * cellSize + cellSize / 2,
    );

    // Draw WHITE BORDER STROKE (bottom layer - wider)
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 43.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(firstCenter, lastCenter, borderPaint);

    // Draw the main colored line (top layer)
    final linePaint = Paint()
      ..color = color.withAlpha((0.9 * 255).toInt())
      ..strokeWidth = 37.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(firstCenter, lastCenter, linePaint);

    // Small circles at endpoints
    final endpointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(firstCenter, 4.0, endpointPaint);
    canvas.drawCircle(lastCenter, 4.0, endpointPaint);
  }

  // Draw hint visualization
  void _drawHint(Canvas canvas, double cellSize) {
    if (currentHintWord == null || hintPositions.isEmpty) return;

    if (hintStep == 1) {
      // Step 1: Show letters one by one
      for (int i = 0; i <= currentHintLetterIndex; i++) {
        if (i < hintPositions.length) {
          final pos = hintPositions[i];
          final center = Offset(
            pos.col * cellSize + cellSize / 2,
            pos.row * cellSize + cellSize / 2,
          );

          double opacity = i == currentHintLetterIndex ? hintAnimation : 1.0;

          canvas.drawCircle(
            center,
            cellSize * 0.25,
            Paint()
              ..color = currentHintWord!.color.withOpacity(opacity * 0.8)
              ..style = PaintingStyle.fill,
          );

          canvas.drawCircle(
            center,
            cellSize * 0.25,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    } else if (hintStep == 2) {
      // Step 2: Flash all letters with straight line
      double opacity = 0.5 + (flashAnimation * 0.5);

      // Draw straight connecting line
      if (hintPositions.length > 1) {
        final firstCenter = Offset(
          hintPositions.first.col * cellSize + cellSize / 2,
          hintPositions.first.row * cellSize + cellSize / 2,
        );

        final lastCenter = Offset(
          hintPositions.last.col * cellSize + cellSize / 2,
          hintPositions.last.row * cellSize + cellSize / 2,
        );

        canvas.drawLine(
          firstCenter,
          lastCenter,
          Paint()
            ..color = currentHintWord!.color.withOpacity(opacity)
            ..strokeWidth = 8.0
            ..strokeCap = StrokeCap.round,
        );
      }

      // Draw all letter circles
      for (GridPosition pos in hintPositions) {
        final center = Offset(
          pos.col * cellSize + cellSize / 2,
          pos.row * cellSize + cellSize / 2,
        );

        canvas.drawCircle(
          center,
          cellSize * 0.25,
          Paint()
            ..color = currentHintWord!.color.withOpacity(opacity)
            ..style = PaintingStyle.fill,
        );

        canvas.drawCircle(
          center,
          cellSize * 0.25,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  // Draw current drag selection
  void _drawDragSelection(Canvas canvas, List<GridPosition> positions, double cellSize, Color color) {
    if (positions.isEmpty) return;

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
    } else {
      final paint = Paint()
        ..color = color
        ..strokeWidth = cellSize * 0.6
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
    }
  }

  // Check if cell is part of hint
  bool _isHintCell(int row, int col) {
    if (!isHintActive || hintPositions.isEmpty) return false;

    if (hintStep == 1) {
      for (int i = 0; i <= currentHintLetterIndex; i++) {
        if (i < hintPositions.length) {
          final pos = hintPositions[i];
          if (pos.row == row && pos.col == col) return true;
        }
      }
    } else if (hintStep == 2) {
      return hintPositions.any((pos) => pos.row == row && pos.col == col);
    }

    return false;
  }

  // Draw hint cell background
  void _drawHintCellBackground(Canvas canvas, Rect rect, int row, int col) {
    if (currentHintWord == null) return;

    double opacity = hintStep == 2 ? 0.3 + (flashAnimation * 0.3) : 0.3;

    canvas.drawRect(
      rect,
      Paint()..color = currentHintWord!.color.withOpacity(opacity),
    );
  }

  // Get hint letter style
  TextStyle _getHintLetterStyle(int row, int col) {
    if (currentHintWord == null) {
      return const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    }

    double opacity = hintStep == 2 ? 0.7 + (flashAnimation * 0.3) : 0.9;

    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: currentHintWord!.color.withOpacity(opacity),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
