import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';

class Rack extends StatelessWidget {
  const Rack({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double margin = 8;
        final totalWidth = constraints.maxWidth - 2*margin;
        final freeSpace = totalWidth/8;
        final padding = totalWidth/70;
        final tileSize = (totalWidth - 2*padding - freeSpace) / 7 / 1.05;
        
        return Consumer2<AppState, RackState>(
          builder: (context, appState, rackState, _) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            
            return GestureDetector(
              onTap: !appState.isGameMode 
                ? () => rackState.isSelected = true
                : null,
              child: SizedBox(
                height: tileSize + padding * 2 + margin * 2,
                child: Stack(
                  children: [
                    if (rackState.isSelected)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber[300]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber[100]!.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    DragTarget<DragData>(
                      onWillAccept: (data) => true,
                      onMove: (details) {
                        final localPosition = box.globalToLocal(details.offset);
                        final tileWidth = tileSize * 1.05;
                        double position = localPosition.dx - margin - padding + 0.5*tileWidth;
                        rackState.updateDragPosition(position, tileWidth, freeSpace);
                      },
                      onLeave: (_) => rackState.clearDragPosition(),
                      onAcceptWithDetails: (details) {
                        final localPosition = box.globalToLocal(details.offset);
                        final tileWidth = tileSize * 1.05;
                        double position = localPosition.dx - margin - padding + 0.5*tileWidth;
                        rackState.acceptDrop(position, tileWidth, freeSpace, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          margin: const EdgeInsets.all(margin),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.brown[400]!, Colors.brown[300]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: padding,
                            ),
                            child: Stack(
                              children: [
                                ...List.generate(rackState.letters.length, (index) {
                                  final position = rackState.getLetterPosition(
                                    index,
                                    tileSize * 1.05,
                                    freeSpace,
                                    totalWidth - 2 * padding
                                  );
                                  
                                  return AnimatedPositioned(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    left: position,
                                    child: _buildDraggableTile(
                                      context,
                                      rackState,
                                      index,
                                      tileSize,
                                      appState.isGameMode,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableTile(BuildContext context, RackState rackState, int index, double size, bool isGameMode) {
    return GestureDetector(
      onTap: isGameMode
        ? () => rackState.clickLetter(index)
        : () {
            rackState.isSelected = true;
            context.read<BoardState>().setSelectedIndex(null);
          },
      child: Draggable<DragData>(
        data: DragData(
          letter: rackState.letters[index],
          rackIndex: index,
        ),
        onDragStarted: () => rackState.startDragging(index),
        onDragEnd: (_) => rackState.endDragging(),
        feedback: Tile.buildTileWithShadow(rackState.letters[index], size),
        childWhenDragging: Container(),
        child: Tile.buildTile(rackState.letters[index], size),
      ),
    );
  }
}

class RackState extends ChangeNotifier {
  static const int maxLetters = 7;
  
  List<String> letters = [];
  int firstGroupLength = 0;
  bool _isSelected = true;
  int? _draggingIndex;
  double? _dragPosition;
  
  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    _isSelected = value;
    notifyListeners();
  }

  void startDragging(int index) {
    _draggingIndex = index;
    notifyListeners();
  }

  void endDragging() {
    _draggingIndex = null;
    _dragPosition = null;
    notifyListeners();
  }

  void updateDragPosition(double position, double tileWidth, double freeSpace) {
    _dragPosition = position;
    notifyListeners();
  }

  void clearDragPosition() {
    _dragPosition = null;
    notifyListeners();
  }

  double getLetterPosition(int index, double tileWidth, double freeSpace, double totalWidth) {
    if (_draggingIndex == index) return 0;
    
    final isLeftGroup = index < firstGroupLength;
    final isDraggingFromLeft = _draggingIndex != null && _draggingIndex! < firstGroupLength;
    
    double basePosition;
    if (isLeftGroup) {
      basePosition = index * tileWidth;
    } else {
      basePosition = (index - firstGroupLength) * tileWidth + freeSpace + firstGroupLength * tileWidth;
    }

    // Si on est en train de faire glisser une lettre
    if (_dragPosition != null && _draggingIndex != null) {
      final dragTargetIndex = _getDragTargetIndex(_dragPosition!, tileWidth, freeSpace);
      
      if (dragTargetIndex <= index && index < _draggingIndex! || 
          dragTargetIndex >= index && index > _draggingIndex!) {
        // Déplacer la lettre dans la direction opposée au mouvement
        return basePosition - tileWidth * (dragTargetIndex < _draggingIndex! ? -1 : 1);
      }
    }
    
    return basePosition;
  }

  int _getDragTargetIndex(double position, double tileWidth, double freeSpace) {
    if (position < firstGroupLength * tileWidth) {
      return max(0, (position / tileWidth).round());
    } else if (position - firstGroupLength * tileWidth < freeSpace) {
      return firstGroupLength;
    } else {
      final rightGroupPosition = position - firstGroupLength * tileWidth - freeSpace;
      return firstGroupLength + 
        min(letters.length - firstGroupLength, (rightGroupPosition / tileWidth).round());
    }
  }

  void acceptDrop(double position, double tileWidth, double freeSpace, DragData data) {
    final targetIndex = _getDragTargetIndex(position, tileWidth, freeSpace);
    
    if (data.rackIndex != null) {
      moveLetter(data.rackIndex!, targetIndex);
    } else if (data.boardIndex != null && letters.length < maxLetters) {
      insertLetter(data.letter, targetIndex);
    }
    
    _dragPosition = null;
    notifyListeners();
  }

  void moveLetter(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    
    final letter = letters[fromIndex];
    letters.removeAt(fromIndex);
    
    if (fromIndex < firstGroupLength) {
      firstGroupLength--;
    }
    
    if (toIndex <= firstGroupLength) {
      letters.insert(toIndex, letter);
      firstGroupLength++;
    } else {
      letters.insert(toIndex, letter);
    }
    
    notifyListeners();
  }

  // Les autres méthodes restent identiques...
  void removeLetter(int index) {
    if (index < letters.length) {
      letters.removeAt(index);
      if (index < firstGroupLength) {
        firstGroupLength--;
      }
    }
    notifyListeners();
  }

  void addLetter(String letter) {
    if (letters.length < maxLetters) {
      letters.add(letter);
      firstGroupLength++;
    }
    notifyListeners();
  }

  void clickLetter(int index) {
    final letter = letters[index];
    final isLeftGroup = index < firstGroupLength;
    letters.removeAt(index);

    if (isLeftGroup) {
      firstGroupLength--;
      letters.insert(firstGroupLength, letter);
    } else {
      letters.insert(firstGroupLength, letter);
      firstGroupLength++;
    }
    notifyListeners();
  }

  void insertLetter(String letter, int index) {
    if (letters.length < maxLetters) {
      letters.insert(index, letter);
      if (index <= firstGroupLength) {
        firstGroupLength++;
      }
      notifyListeners();
    }
  }
}

class DragData {
  final String letter;
  final int? rackIndex;
  final int? boardIndex;

  DragData({
    required this.letter,
    this.rackIndex,
    this.boardIndex,
  });
}