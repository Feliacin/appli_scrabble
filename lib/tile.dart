import 'package:flutter/material.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/rack.dart';

class Tile extends StatelessWidget {
  final String propriete;
  final int index;

  const Tile({super.key, required this.propriete, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Board.selectedIndex.value == index) {
          Board.isVertical.value = !Board.isVertical.value;
        } else {
          Board.selectedIndex.value = index;
          Rack.isSelected.value = false;
        }
      },
      child: ValueListenableBuilder<_TileState>(
        valueListenable: _CombinedTileNotifier(
          selectedIndex: Board.selectedIndex,
          letters: Board.letters,
          isVertical: Board.isVertical,
          blanks: Board.blanks,
          index: index,
        ),
        builder: (context, state, _) {
          final letter = state.letter;
          
          // Déterminer la décoration de la case
          final baseColor = letter != null 
            ? (state.isBlank ? Colors.pink[50]! : Colors.amber[100]!)
            : (Board.specialColors[propriete] ?? Colors.white);

          BoxDecoration decoration;
          if (state.isSelected) {
            decoration = BoxDecoration(
              color: Colors.limeAccent,
              borderRadius: BorderRadius.circular(3),
            );
          } else if (state.isDirectionIndicator) {
            decoration = BoxDecoration(
              gradient: LinearGradient(
                begin: state.isVertical ? Alignment.topCenter : Alignment.centerLeft,
                end: state.isVertical ? Alignment.bottomCenter : Alignment.centerRight,
                colors: [Colors.limeAccent, baseColor],
              ),
              borderRadius: BorderRadius.circular(3),
            );
          } else {
            decoration = BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(3),
            );
          }

          return Container(
            decoration: decoration,
            child: Center(
              child: letter != null
                ? Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : Text(
                    propriete,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.brown[600],
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _TileState {
  final String? letter;
  final bool isSelected;
  final bool isDirectionIndicator;
  final bool isVertical;
  final bool isBlank;

  const _TileState({
    required this.letter,
    required this.isSelected,
    required this.isDirectionIndicator,
    required this.isVertical,
    required this.isBlank,
  });
}

class _CombinedTileNotifier extends ValueNotifier<_TileState> {
  final ValueNotifier<int?> selectedIndex;
  final ValueNotifier<List<List<String?>>> letters;
  final ValueNotifier<bool> isVertical;
  final ValueNotifier<List<int>> blanks;
  final int index;

  _CombinedTileNotifier({
    required this.selectedIndex,
    required this.letters,
    required this.isVertical,
    required this.blanks,
    required this.index,
  }) : super(_calculateState(selectedIndex.value, letters.value, isVertical.value, blanks.value, index)) {
    selectedIndex.addListener(_updateState);
    letters.addListener(_updateState);
    isVertical.addListener(_updateState);
    blanks.addListener(_updateState);
  }

  void _updateState() {
    // Modification de l'état de la classe parente
    value = _calculateState(selectedIndex.value, letters.value, isVertical.value, blanks.value, index);
  }

  static _TileState _calculateState(
    int? selected,
    List<List<String?>> letters,
    bool isVertical,
    List<int> blanks,
    int index,
  ) {
    final row = index ~/ Board.boardSize;
    final col = index % Board.boardSize;
    final letter = letters[row][col];
    
    final isSelected = selected == index;
    final isDirectionIndicator = selected != null &&
      ((isVertical && col == selected % Board.boardSize && row == (selected ~/ Board.boardSize) + 1) ||
       (!isVertical && row == selected ~/ Board.boardSize && col == (selected % Board.boardSize) + 1));

    return _TileState(
      letter: letter,
      isSelected: isSelected,
      isDirectionIndicator: isDirectionIndicator,
      isVertical: isVertical,
      isBlank: blanks.contains(index),
    );
  }

  @override
  void dispose() {
    selectedIndex.removeListener(_updateState);
    letters.removeListener(_updateState);
    isVertical.removeListener(_updateState);
    blanks.removeListener(_updateState);
    super.dispose();
  }
}