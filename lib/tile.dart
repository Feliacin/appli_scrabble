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
        if (Board.selectedIndex.value == index) { // Changer la direction
          Board.isVertical.value = !Board.isVertical.value;
        } else { // Sélectionner la case
          Board.selectedIndex.value = index;
          Rack.isSelected.value = false;
        }
      },
      child: ValueListenableBuilder<int?>(
        valueListenable: Board.selectedIndex,
        builder: (context, selected, child) {
          return ValueListenableBuilder<List<List<String?>>>(
            valueListenable: Board.letters,
            builder: (context, letters, _) {
              final row = index ~/ Board.boardSize;
              final col = index % Board.boardSize;
              final letter = letters[row][col];
              
              return ValueListenableBuilder<bool>(
                valueListenable: Board.isVertical,
                builder: (context, isVertical, _) {
                  // Déterminer le type de case (sélectionnée, direction, normale)
                  final isSelected = selected == index;
                  final isDirectionIndicator = selected != null &&
                    ((isVertical && col == selected % Board.boardSize && row == (selected ~/ Board.boardSize) + 1) ||
                     (!isVertical && row == selected ~/ Board.boardSize && col == (selected % Board.boardSize) + 1));

                  // Déterminer la décoration de la case
                  final baseColor = letter != null 
                    ? (Board.blanks.value.contains(index) ? Colors.pink[50]! : Colors.amber[100]!)
                    : (Board.specialColors[propriete] ?? Colors.white);

                  BoxDecoration decoration;
                  if (isSelected) {
                    decoration = BoxDecoration(
                      color: Colors.limeAccent,
                      borderRadius: BorderRadius.circular(3),
                    );
                  } else if (isDirectionIndicator) {
                    decoration = BoxDecoration(
                      gradient: LinearGradient(
                        begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
                        end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
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
              );
            },
          );
        },
      ),
    );
  }
}