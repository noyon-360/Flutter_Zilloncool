import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../controllers/sound_controller.dart';

class WordGrid extends StatefulWidget {
  final List<List<String>> grid;
  final List<WordToFind> wordsToFind;
  final DragSelection dragSelection;
  final Function(WordToFind, List<GridPosition>) onWordFound;
  final ValueNotifier<List<List<GridPosition>>> foundWordPositionsNotifier;
  final SoundController soundController;

  // Hint system properties using ValueNotifiers
  final ValueNotifier<bool> isHintActiveNotifier;
  final ValueNotifier<WordToFind?> currentHintWordNotifier;
  final ValueNotifier<List<GridPosition>> hintPositionsNotifier;
  final ValueNotifier<int> hintStepNotifier;
  final ValueNotifier<int> currentHintLetterIndexNotifier;
  final AnimationController hintAnimationController;
  final AnimationController flashAnimationController;

  const WordGrid({
    super.key,
    required this.grid,
    required this.wordsToFind,
    required this.dragSelection,
    required this.onWordFound,
    required this.foundWordPositionsNotifier,
    required this.soundController,
    required this.isHintActiveNotifier,
    required this.currentHintWordNotifier,
    required this.hintPositionsNotifier,
    required this.hintStepNotifier,
    required this.currentHintLetterIndexNotifier,
    required this.hintAnimationController,
    required this.flashAnimationController,
  });

  @override
  State<WordGrid> createState() => _WordGridState();
}

class _WordGridState extends State<WordGrid> {
  final ValueNotifier<WordToFind?> _currentDragWordNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier(false);
  final ValueNotifier<List<GridPosition>> _selectedPositionsNotifier = ValueNotifier([]);

  @override
  void dispose() {
    _currentDragWordNotifier.dispose();
    _isDraggingNotifier.dispose();
    _selectedPositionsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.isHintActiveNotifier,
          builder: (context, isHintActive, child) {
            return GestureDetector(
              onPanStart: isHintActive ? null : _onPanStart,
              onPanUpdate: isHintActive ? null : _onPanUpdate,
              onPanEnd: isHintActive ? null : _onPanEnd,
              child: ValueListenableBuilder<List<List<GridPosition>>>(
                valueListenable: widget.foundWordPositionsNotifier,
                builder: (context, foundWordPositions, child) {
                  return ValueListenableBuilder<List<GridPosition>>(
                    valueListenable: _selectedPositionsNotifier,
                    builder: (context, selectedPositions, child) {
                      return ValueListenableBuilder<WordToFind?>(
                        valueListenable: _currentDragWordNotifier,
                        builder: (context, currentDragWord, child) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _isDraggingNotifier,
                            builder: (context, isDragging, child) {
                              return AnimatedBuilder(
                                animation: Listenable.merge([
                                  widget.hintAnimationController,
                                  widget.flashAnimationController,
                                ]),
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: EnhancedGridPainter(
                                      grid: widget.grid,
                                      selectedPositions: selectedPositions,
                                      foundWordPositions: foundWordPositions,
                                      wordsToFind: widget.wordsToFind,
                                      currentDragWord: currentDragWord,
                                      isDragging: isDragging,
                                      // Hint properties
                                      isHintActive: isHintActive,
                                      currentHintWord: widget.currentHintWordNotifier.value,
                                      hintPositions: widget.hintPositionsNotifier.value,
                                      hintStep: widget.hintStepNotifier.value,
                                      currentHintLetterIndex: widget.currentHintLetterIndexNotifier.value,
                                      hintAnimation: widget.hintAnimationController.value,
                                      flashAnimation: widget.flashAnimationController.value,
                                    ),
                                    child: Container(),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final gridPosition = _getGridPosition(localPosition, renderBox.size);

    if (gridPosition != null) {
      _isDraggingNotifier.value = true;
      await widget.soundController.playDragStart();
      
      widget.dragSelection.reset();
      widget.dragSelection.startPosition = gridPosition;
      widget.dragSelection.selectedPositions = [gridPosition];
      widget.dragSelection.isActive = true;
      
      _selectedPositionsNotifier.value = [gridPosition];
      _currentDragWordNotifier.value = null;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) async {
    if (!widget.dragSelection.isActive) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final gridPosition = _getGridPosition(localPosition, renderBox.size);

    if (gridPosition != null && widget.dragSelection.startPosition != null) {
      final newPositions = _getPositionsBetween(
        widget.dragSelection.startPosition!,
        gridPosition,
      );

      // Only update if positions changed
      if (newPositions.length != _selectedPositionsNotifier.value.length) {
        await widget.soundController.playDragStep();
        
        widget.dragSelection.endPosition = gridPosition;
        widget.dragSelection.selectedPositions = newPositions;
        
        _selectedPositionsNotifier.value = newPositions;
        _currentDragWordNotifier.value = _getCurrentDragWord(newPositions);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) async {
    _isDraggingNotifier.value = false;
    bool isValidWord = false;

    if (_selectedPositionsNotifier.value.isNotEmpty) {
      isValidWord = _checkForWord(_selectedPositionsNotifier.value);
    }

    await widget.soundController.playDragEnd(isValidWord: isValidWord);
    
    widget.dragSelection.reset();
    _selectedPositionsNotifier.value = [];
    _currentDragWordNotifier.value = null;
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

  WordToFind? _getCurrentDragWord(List<GridPosition> positions) {
    if (positions.isEmpty) return null;

    String selectedWord = '';
    for (GridPosition pos in positions) {
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

  bool _checkForWord(List<GridPosition> positions) {
    String selectedWord = '';
    for (GridPosition pos in positions) {
      selectedWord += widget.grid[pos.row][pos.col];
    }

    for (WordToFind wordToFind in widget.wordsToFind) {
      if (!wordToFind.isFound &&
          (selectedWord == wordToFind.word ||
              selectedWord == wordToFind.word.split('').reversed.join())) {
        widget.onWordFound(wordToFind, List.from(positions));
        return true;
      }
    }
    return false;
  }
}

class EnhancedGridPainter extends CustomPainter {
  final List<List<String>> grid;
  final List<GridPosition> selectedPositions;
  final List<List<GridPosition>> foundWordPositions;
  final List<WordToFind> wordsToFind;
  final WordToFind? currentDragWord;
  final bool isDragging;

  // Hint properties
  final bool isHintActive;
  final WordToFind? currentHintWord;
  final List<GridPosition> hintPositions;
  final int hintStep;
  final int currentHintLetterIndex;
  final double hintAnimation;
  final double flashAnimation;

  EnhancedGridPainter({
    required this.grid,
    required this.selectedPositions,
    required this.foundWordPositions,
    required this.wordsToFind,
    this.currentDragWord,
    required this.isDragging,
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

    // Draw current selection during drag with enhanced visual feedback
    if (!isHintActive && selectedPositions.isNotEmpty) {
      Color dragColor;
      double opacity;
      if (currentDragWord != null) {
        dragColor = currentDragWord!.color;
        opacity = 0.8;
      } else {
        dragColor = Colors.blue;
        opacity = 0.4;
      }
      _drawEnhancedDragSelection(canvas, selectedPositions, cellSize, dragColor.withOpacity(opacity));
    }

    // Draw hint if active
    if (isHintActive && currentHintWord != null) {
      _drawHint(canvas, cellSize);
    }

    // Draw grid letters
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
        bool isInCurrentDrag = !isHintActive && 
            selectedPositions.any((pos) => pos.row == row && pos.col == col);
        bool isHintCell = _isHintCell(row, col);
        bool isFoundWordLetter = _isFoundWordLetter(row, col);

        // Draw enhanced cell backgrounds
        if (isInCurrentDrag) {
          Color cellColor = currentDragWord != null
              ? currentDragWord!.color.withOpacity(0.3)
              : Colors.blue.withOpacity(0.2);

          // Add pulsing effect for valid words
          if (currentDragWord != null) {
            double pulseScale = 1.0 + (0.05 * (1.0 + 0.5 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000));
            canvas.save();
            canvas.translate(rect.center.dx, rect.center.dy);
            canvas.scale(pulseScale);
            canvas.translate(-rect.center.dx, -rect.center.dy);
          }

          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            Paint()..color = cellColor,
          );

          if (currentDragWord != null) {
            canvas.restore();
          }
        }

        if (isHintCell) {
          _drawHintCellBackground(canvas, rect, row, col);
        }

        // Determine letter style with enhanced effects
        TextStyle letterStyle = const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );

        if (isInCurrentDrag && currentDragWord != null) {
          letterStyle = TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: currentDragWord!.color,
            shadows: [
              Shadow(
                color: Colors.white,
                blurRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
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

    // Draw found words with enhanced lines
    for (int i = 0; i < foundWordPositions.length; i++) {
      final positions = foundWordPositions[i];
      final wordToFind = wordsToFind.firstWhere((w) => w.foundPositions == positions);
      _drawEnhancedFoundWordLine(canvas, positions, cellSize, wordToFind.color);
    }

    // Draw white letters on top of found word lines
    for (int i = 0; i < foundWordPositions.length; i++) {
      final positions = foundWordPositions[i];
      _drawWhiteLettersOnTop(canvas, positions, cellSize);
    }
  }

  void _drawEnhancedDragSelection(Canvas canvas, List<GridPosition> positions, double cellSize, Color color) {
    if (positions.isEmpty) return;

    if (positions.length == 1) {
      final pos = positions[0];
      final center = Offset(
        pos.col * cellSize + cellSize / 2,
        pos.row * cellSize + cellSize / 2,
      );

      // Draw pulsing circle for single selection
      canvas.drawCircle(
        center,
        cellSize * 0.35,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        cellSize * 0.35,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else {
      // Enhanced line drawing with glow effect
      final paint = Paint()
        ..color = color
        ..strokeWidth = cellSize * 0.7
        ..strokeCap = StrokeCap.round;

      // Draw glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = cellSize * 0.9
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final path = Path();
      final glowPath = Path();

      for (int i = 0; i < positions.length; i++) {
        final pos = positions[i];
        final center = Offset(
          pos.col * cellSize + cellSize / 2,
          pos.row * cellSize + cellSize / 2,
        );

        if (i == 0) {
          path.moveTo(center.dx, center.dy);
          glowPath.moveTo(center.dx, center.dy);
        } else {
          path.lineTo(center.dx, center.dy);
          glowPath.lineTo(center.dx, center.dy);
        }
      }

      canvas.drawPath(glowPath, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  void _drawEnhancedFoundWordLine(Canvas canvas, List<GridPosition> positions, double cellSize, Color color) {
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

    // Draw enhanced border with gradient
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, Colors.white.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(firstCenter, lastCenter))
      ..strokeWidth = 45.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(firstCenter, lastCenter, borderPaint);

    // Draw main colored line with subtle gradient
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(firstCenter, lastCenter))
      ..strokeWidth = 39.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(firstCenter, lastCenter, linePaint);

    // Enhanced endpoints with glow
    final endpointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final endpointGlowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(firstCenter, 6.0, endpointGlowPaint);
    canvas.drawCircle(lastCenter, 6.0, endpointGlowPaint);
    canvas.drawCircle(firstCenter, 4.0, endpointPaint);
    canvas.drawCircle(lastCenter, 4.0, endpointPaint);
  }

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
            color: Colors.black38,
            blurRadius: 3,
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

  bool _isFoundWordLetter(int row, int col) {
    for (List<GridPosition> positions in foundWordPositions) {
      if (positions.any((pos) => pos.row == row && pos.col == col)) {
        return true;
      }
    }
    return false;
  }

  void _drawHint(Canvas canvas, double cellSize) {
    if (currentHintWord == null || hintPositions.isEmpty) return;

    if (hintStep == 1) {
      // Step 1: Show letters one by one with enhanced animation
      for (int i = 0; i <= currentHintLetterIndex; i++) {
        if (i < hintPositions.length) {
          final pos = hintPositions[i];
          final center = Offset(
            pos.col * cellSize + cellSize / 2,
            pos.row * cellSize + cellSize / 2,
          );

          double opacity = i == currentHintLetterIndex ? hintAnimation : 1.0;
          double scale = i == currentHintLetterIndex ? (1.0 + hintAnimation * 0.3) : 1.0;

          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.scale(scale);
          canvas.translate(-center.dx, -center.dy);

          // Glow effect
          canvas.drawCircle(
            center,
            cellSize * 0.3,
            Paint()
              ..color = currentHintWord!.color.withOpacity(opacity * 0.3)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );

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
              ..strokeWidth = 3,
          );

          canvas.restore();
        }
      }
    } else if (hintStep == 2) {
      // Step 2: Flash all letters with enhanced effects
      double opacity = 0.6 + (flashAnimation * 0.4);
      double glowIntensity = flashAnimation;

      // Draw connecting line with glow
      if (hintPositions.length > 1) {
        final firstCenter = Offset(
          hintPositions.first.col * cellSize + cellSize / 2,
          hintPositions.first.row * cellSize + cellSize / 2,
        );
        final lastCenter = Offset(
          hintPositions.last.col * cellSize + cellSize / 2,
          hintPositions.last.row * cellSize + cellSize / 2,
        );

        // Glow line
        canvas.drawLine(
          firstCenter,
          lastCenter,
          Paint()
            ..color = currentHintWord!.color.withOpacity(glowIntensity * 0.5)
            ..strokeWidth = 12.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );

        // Main line
        canvas.drawLine(
          firstCenter,
          lastCenter,
          Paint()
            ..color = currentHintWord!.color.withOpacity(opacity)
            ..strokeWidth = 8.0
            ..strokeCap = StrokeCap.round,
        );
      }

      // Draw all letter circles with enhanced effects
      for (GridPosition pos in hintPositions) {
        final center = Offset(
          pos.col * cellSize + cellSize / 2,
          pos.row * cellSize + cellSize / 2,
        );

        // Glow effect
        canvas.drawCircle(
          center,
          cellSize * 0.35,
          Paint()
            ..color = currentHintWord!.color.withOpacity(glowIntensity * 0.4)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
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
            ..strokeWidth = 3,
        );
      }
    }
  }

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

  void _drawHintCellBackground(Canvas canvas, Rect rect, int row, int col) {
    if (currentHintWord == null) return;

    double opacity = hintStep == 2 ? 0.4 + (flashAnimation * 0.4) : 0.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = currentHintWord!.color.withOpacity(opacity),
    );
  }

  TextStyle _getHintLetterStyle(int row, int col) {
    if (currentHintWord == null) {
      return const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    }

    double opacity = hintStep == 2 ? 0.8 + (flashAnimation * 0.2) : 0.9;
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: currentHintWord!.color.withOpacity(opacity),
      shadows: [
        Shadow(
          color: Colors.white,
          blurRadius: 2,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! EnhancedGridPainter ||
        oldDelegate.selectedPositions != selectedPositions ||
        oldDelegate.foundWordPositions != foundWordPositions ||
        oldDelegate.currentDragWord != currentDragWord ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.isHintActive != isHintActive ||
        oldDelegate.hintStep != hintStep ||
        oldDelegate.currentHintLetterIndex != currentHintLetterIndex ||
        oldDelegate.hintAnimation != hintAnimation ||
        oldDelegate.flashAnimation != flashAnimation;
  }
}
