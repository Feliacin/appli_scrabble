import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Keyboard extends StatelessWidget {
  final bool letterPicker;
  const Keyboard({super.key, this.letterPicker = false});

  void _handleLetterPress(BuildContext context, String letter) {
      if (letterPicker) {
        Navigator.of(context).pop(letter);
        return;
      }

    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      rackState.addLetter(letter);
    } else if (boardState.selectedIndex != null) {
      final pos = Position.fromIndex(boardState.selectedIndex!);

      if (letter == ' ') {
        if (boardState.letters[pos.row][pos.col] != null) {
          boardState.toggleBlank(pos);
        }
        return;
      }
      
      // Ajouter la lettre
      boardState.writeLetter(letter, pos);

      // Déplacer la sélection
      if (boardState.isVertical && pos.row < BoardState.boardSize - 1) {
        boardState.selectedIndex = (pos.row + 1) * BoardState.boardSize + pos.col;
      } else if (!boardState.isVertical && pos.col < BoardState.boardSize - 1) {
        boardState.selectedIndex = pos.row * BoardState.boardSize + (pos.col + 1);
      }
    }
  }

  void _handleBackspace(BuildContext context) {
    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      rackState.removeLetter(rackState.letters.length - 1);
    } else if (boardState.selectedIndex != null) {
      final index = boardState.selectedIndex!;
      final row = index ~/ BoardState.boardSize;
      final col = index % BoardState.boardSize;
      
      // Supprimer la lettre de la case actuelle
      boardState.removeLetter(Position(row, col));

      // Déplacer la sélection
      if (boardState.isVertical && row > 0) {
        boardState.selectedIndex = (row - 1) * BoardState.boardSize + col;
      } else if (col > 0) {
        boardState.selectedIndex = row * BoardState.boardSize + (col - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const letters = [
      ['a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['q', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm'],
      [' ', 'w', 'x', 'c', 'v', 'b', 'n'],
    ];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final keySize = (constraints.maxWidth - 20) / 10;
        final buttonSize = keySize - 2;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...letters.asMap().entries.map((entry) {
                int idx = entry.key;
                List<String> row = entry.value;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...row.map((letter) => letterPicker && letter != ' '
                      ? Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: InkWell(
                            onTap: () => _handleLetterPress(context, letter),
                            child: Tile.buildTile(letter, buttonSize, withBorder: true),
                          ),
                        ),
                      )
                      : const SizedBox.shrink()
                    ),
                    
                    if (idx == 2 && !letterPicker)
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: InkWell(
                            onTap: () => _handleBackspace(context),
                            child: Tile.buildTile(
                              '⌫',
                              buttonSize,
                              specialColor: [Colors.red[50]!, Colors.red[100]!],
                              withBorder: true
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}