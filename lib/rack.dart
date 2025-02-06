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
        final tileWidth = (totalWidth - 2*padding - freeSpace) / 7;
        final tileSize = tileWidth / 1.05; // 0.05 de marge pour chaque tuile
        
        return Consumer3<AppState, RackState, BoardState>(
          builder: (context, appState, rackState, boardState, _) {
            return GestureDetector(
              onTap: appState.isSearchMode
                ? () {
                  boardState.selectedIndex = null;
                  rackState.isSelected = true;
                }
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
                      onWillAcceptWithDetails: (details) => true,
                      onMove: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(details.offset);
                        double position = localPosition.dx - margin - padding + 0.5*tileWidth;
                        rackState._updateHoverIndex(position, tileWidth, totalWidth - 2*padding, details.data.boardIndex != null);
                      },
                      onLeave: (_) => rackState._clearHoverIndex(),
                      onAcceptWithDetails: (details) => rackState._acceptDrop(details.data),
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
                            padding: EdgeInsets.all(padding),
                            child: Stack(
                              children: [
                                ...List.generate(rackState.letters.length, (index) {
                                  final position = rackState._getLetterPosition(
                                    index,
                                    tileWidth,
                                    totalWidth - 2 * padding,
                                  );
                                  
                                  return AnimatedPositioned(
                                    key: ValueKey(rackState.keys[index]),
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    left: position,
                                    child: _buildDraggableTile(
                                      rackState,
                                      boardState,
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

  Widget _buildDraggableTile(RackState rackState, BoardState boardState, int index, double size, bool isGameMode) {
    return GestureDetector(
      onTap: isGameMode
        ? () => rackState._clickLetter(index)
        : () {
            rackState.isSelected = true;
            boardState.selectedIndex = null;
          },
      child: Draggable<DragData>(
        data: DragData(
          letter: rackState.letters[index],
          rackIndex: index,
        ),
        onDragStarted: () => rackState._startDragging(index),
        onDragEnd: (_) => rackState._endDragging(),
        feedback: Material(
          color: Colors.transparent,
          child: Tile.buildTileWithShadow(rackState.letters[index], size, boardState.letterPoints)
        ),
        childWhenDragging: Container(),
        child: Tile.buildTile(rackState.letters[index], size, boardState.letterPoints, horizontalMargin: size * 0.025, withBorder: true),
      ),
    );
  }
}

class RackState extends ChangeNotifier {
  static const int maxLetters = 7;
  List<String> letters = [];
  List<int> keys = [];
  int _leftGroupLength = 0;
  bool _isSelected = true;
  int? _draggingIndex;
  int? _hoverIndex;
  int _leftGroupShift = 0; // lorsqu'on survole le centre du rack avec une lettre, on peut la déposer sur le côté gauche ou droit
  
  RackState();

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    _isSelected = value;
    notifyListeners();
  }

  void shuffle() {
    letters.shuffle();
    notifyListeners();
  }

  void _startDragging(int index) {
    _draggingIndex = index;
    notifyListeners();
  }

  void _endDragging() {
    _draggingIndex = null;
    _hoverIndex = null;
    _leftGroupShift = 0;
    notifyListeners();
  }

  void _updateHoverIndex(double position, double tileWidth, double width, bool fromBoard) {
    if (fromBoard) {
      final index = _getDragTargetIndex(position, tileWidth, width);
      if (index != _hoverIndex) {
        _hoverIndex = index;
        notifyListeners();
      }
    } else if (_draggingIndex != null) { // Null au démarrage
      final previousShift = _leftGroupShift;
      final index = _getDragTargetIndex(position, tileWidth, width);
      if (index != _hoverIndex || _leftGroupShift != previousShift) {
        _hoverIndex = index;
        notifyListeners();
      }
    }
  }

  void _clearHoverIndex() {
    _hoverIndex = null;
    _leftGroupShift = 0;
    notifyListeners();
  }

  double _getLetterPosition(int index, double tileWidth, double width) {
    final formBoard = _draggingIndex == null && _hoverIndex != null;

    // Emplacement de la tuile en cours de déplacement, invisible tant qu'elle n'est pas lâchée.
    // On la place à l'emplacement final pour éviter une animation de déplacement depuis son emplacement d'origine.
    if(!formBoard && _hoverIndex != null && index == _draggingIndex!) {
      return _hoverIndex! < _leftGroupLength || 
        (_hoverIndex! == _leftGroupLength && _draggingIndex! >= _leftGroupLength && _leftGroupShift > 0)
        ? _hoverIndex! * tileWidth
        : width - tileWidth - tileWidth * (letters.length - 1 - _hoverIndex!);
    }

    final isLeftGroup = index < _leftGroupLength;
    double basePosition;
    if (isLeftGroup) {
      basePosition = index * tileWidth;
    } else {
      basePosition = width - tileWidth - tileWidth * (letters.length - 1 - index);
    }

    // Si on est en train de faire glisser une lettre
    if (formBoard) {
      if (isLeftGroup && _hoverIndex! <= index) {
        return basePosition + tileWidth;
      } else if (!isLeftGroup && _hoverIndex! > index) {
        return basePosition - tileWidth;
      }
    } else
    if (_draggingIndex != null) {
      if (_hoverIndex == null) {
        if (isLeftGroup && index > _draggingIndex!) {
          return basePosition - tileWidth;
        } else if (!isLeftGroup && index < _draggingIndex!) {
          return basePosition + tileWidth;
        }
      } else {
        if (_hoverIndex! <= index && index < _draggingIndex!) {
          return basePosition + tileWidth;
        } else if (_hoverIndex! >= index && index > _draggingIndex!) {
          return basePosition - tileWidth;
        }
      }
    }
    
    return basePosition;
  }

  int _getDragTargetIndex(double position, double tileWidth, double width) { // position du centre de la lettre
    final fromBoard = _draggingIndex == null;
    final isLeftGroup = !fromBoard ? _draggingIndex! < _leftGroupLength : null;
    final leftGroupLength = _leftGroupLength - (isLeftGroup != null && isLeftGroup ? 1 : 0);
    final letterCount = fromBoard ? letters.length : letters.length - 1;

    // Côté gauche
    if (position < leftGroupLength * tileWidth) {
      _leftGroupShift = fromBoard || !isLeftGroup! ? 1 : 0;
      return max(0, (position / tileWidth).round());
    }
    
    // Côté droit
    if (position > width - (letters.length-1 - leftGroupLength) * tileWidth) {
        _leftGroupShift = !fromBoard && isLeftGroup! ? -1 : 0;
        return min(letterCount, letterCount - ((width - position) / tileWidth).round());
    }
    
    // Centre
    final middlePosition = (width - tileWidth * letterCount) / 2;
    if (position - leftGroupLength * tileWidth < middlePosition) {
      _leftGroupShift = fromBoard || !isLeftGroup! ? 1 : 0;
    } else {
      _leftGroupShift = !fromBoard && isLeftGroup! ? -1 : 0;
    }
    return leftGroupLength;
  }

  void _acceptDrop(DragData data) {
    _leftGroupLength += _leftGroupShift;  
    if (data.rackIndex != null) {
      final fromIndex = data.rackIndex!;
      final toIndex = _hoverIndex!;
      final letter = letters[fromIndex];
      letters.removeAt(fromIndex);
      letters.insert(toIndex, letter);

      int key = keys[fromIndex];
      if (fromIndex < toIndex) {
        for (int i = fromIndex; i < toIndex; i++) {
        keys[i] = keys[i + 1];
        }
      } else {
        for (int i = fromIndex; i > toIndex; i--) {
        keys[i] = keys[i - 1];
        }
      }
      keys[toIndex] = key;
    } else {
      letters.insert(_hoverIndex!, data.letter);
      keys.insert(_hoverIndex!, _newKey());
    }
    _hoverIndex = null;
    notifyListeners();
  }

  void _clickLetter(int index) {
    final isLeftGroup = index < _leftGroupLength;
    final letter = letters[index];
    final key = keys[index];
    letters.removeAt(index);
    keys.removeAt(index);

    if (isLeftGroup) {
      _leftGroupLength--;
      letters.insert(_leftGroupLength, letter);
      keys.insert(_leftGroupLength, key);
    } else {
      letters.insert(_leftGroupLength, letter);
      keys.insert(_leftGroupLength, key);
      _leftGroupLength++;
    }
    notifyListeners();
  }

  int _newKey() {
    int i = 0;
    while (keys.contains(i)) {
      i++;
    }
    return i;
  }

  void addLetter(String letter) {
    if (letters.length < maxLetters) {
      keys.add(letters.length);
      letters.add(letter);
      _leftGroupLength++;
    }
    notifyListeners();
  }

  void removeLetter(int index) {
    if (index < letters.length) {
      letters.removeAt(index);
      if (index < _leftGroupLength) {
        _leftGroupLength--;
      }
      keys.remove(letters.length);
    }
    notifyListeners();
  }

  void removeLast() {
    letters.removeLast();
    notifyListeners();
  }

  // Sauvegarde et restauration de l'état
  Map<String, dynamic> toJson() {
    return {
      'letters': letters,
      'leftGroupLength': _leftGroupLength,
    };
  }

  RackState.fromJson(Map<String, dynamic> json)
    : letters = List<String>.from(json['letters']) {
      keys = List.generate(letters.length, (index) => index);
      _leftGroupLength = json['leftGroupLength'];
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