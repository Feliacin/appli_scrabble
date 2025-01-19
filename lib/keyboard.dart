import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Keyboard extends StatelessWidget {
  const Keyboard({super.key});

  void _handleLetterPress(BuildContext context, String letter) {
    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      rackState.addLetter(letter);
    } else if (boardState.selectedIndex != null) {
      final index = boardState.selectedIndex!;
      final row = index ~/ BoardState.boardSize;
      final col = index % BoardState.boardSize;

      if (letter == ' ') {
        if (boardState.letters[row][col] != null) {
          boardState.toggleBlank(index);
        }
        return;
      }
      
      // Ajouter la lettre
      boardState.writeLetter(letter, row, col);

      // Déplacer la sélection
      if (boardState.isVertical && row < BoardState.boardSize - 1) {
        boardState.setSelectedIndex((row + 1) * BoardState.boardSize + col);
      } else if (!boardState.isVertical && col < BoardState.boardSize - 1) {
        boardState.setSelectedIndex(row * BoardState.boardSize + (col + 1));
      }
    }
  }

  void _handleBackspace(BuildContext context) {
    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      if (rackState.letters.isNotEmpty) {
        rackState.removeLetter(rackState.letters.length - 1);
      }
    } else if (boardState.selectedIndex != null) {
      final index = boardState.selectedIndex!;
      final row = index ~/ BoardState.boardSize;
      final col = index % BoardState.boardSize;
      
      // Supprimer la lettre de la case actuelle
      boardState.removeLetter(row, col);

      // Déplacer la sélection
      if (boardState.isVertical && row > 0) {
        boardState.setSelectedIndex((row - 1) * BoardState.boardSize + col);
      } else if (col > 0) {
        boardState.setSelectedIndex(row * BoardState.boardSize + (col - 1));
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
      // On prend la largeur disponible et on la divise par 10 (nombre max de touches par ligne)
      final keySize = (constraints.maxWidth - 20) / 10; // 20 pour le padding
      final buttonSize = keySize - 2; // 2 pour le padding entre les touches
      
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
                  ...row.map((letter) => Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: ElevatedButton(
                        onPressed: () => _handleLetterPress(context, letter),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                        ),
                        child: Text(letter.toUpperCase()),
                      ),
                    ),
                  )),
                  
                  if (idx == 2)
                    Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          onPressed: () => _handleBackspace(context),
                          icon: const Icon(Icons.backspace, color: Colors.red),
                        ),
                      ),
                    )
                ],
              );
            }),
          ],
        ),
      );
    }
  );
}
}