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
        Board.selectedIndex.value = index;
        Rack.isSelected.value = false;
      },
      child: ValueListenableBuilder<int?>(
        valueListenable: Board.selectedIndex,
        builder: (context, selected, child) {
          return ValueListenableBuilder<List<List<String?>>>(
            valueListenable: Board.letters,
            builder: (context, letters, _) {
              bool isSelected = selected == index;
              int row = index ~/ Board.boardSize;
              int col = index % Board.boardSize;
              String? letter = letters[row][col];
              return ValueListenableBuilder<List<int>>(
                valueListenable: Board.blanks,
                builder: (context, blanks, _) {
                  final isBlank = blanks.contains(index);
                  return Container(
                    decoration: BoxDecoration(
                      color: letter != null 
                          ? (isBlank ? Colors.pink[50] : Colors.amber[100])
                          : (isSelected
                              ? Colors.yellow[200]
                              : Board.specialColors[propriete] ?? Colors.white),
                      borderRadius: BorderRadius.circular(3),
                      border: isSelected
                          ? Border.all(color: Colors.orange, width: 2)
                          : Border.all(color: Colors.brown[200]!, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 2,
                              )
                            ]
                          : (letter != null 
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null),
                    ),
                    child: Center(
                      child: letter != null
                          ? Text(
                              letter.toUpperCase(),
                              style: TextStyle(
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
                }
              );
            },
          );
        },
      ),
    );
  }
}