// keyboard.dart
import 'package:flutter/material.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/rack.dart';


class Keyboard extends StatelessWidget {
  const Keyboard({super.key});

  void _handleLetterPress(String letter) {
    if (Rack.isSelected.value) {
      if (Rack.letters.value.length < Rack.maxLetters) {
        final newLetters = List<String>.from(Rack.letters.value);
        newLetters.add(letter);
        Rack.letters.value = newLetters;
      }
    } else if (Board.selectedIndex.value != null) {
      final row = Board.selectedIndex.value! ~/ Board.boardSize;
      final col = Board.selectedIndex.value! % Board.boardSize;
      
      // Ajouter la lettre
      Board.letters.value[row][col] = letter;
      //Board.setLetter(row, col, letter);

      // Déplacer la sélection
      if (Board.isVertical.value) {
        if (row < Board.boardSize - 1) {
          Board.selectedIndex.value = (row + 1) * Board.boardSize + col;
        }
      } else {
        if (col < Board.boardSize - 1) {
          Board.selectedIndex.value = row * Board.boardSize + (col + 1);
        }
      }
    }
  }

  void _handleBackspace() {
    if (Rack.isSelected.value && Rack.letters.value.isNotEmpty) {
      final newLetters = List<String>.from(Rack.letters.value);
      newLetters.removeLast();
      Rack.letters.value = newLetters;
    } else if (Board.selectedIndex.value != null) {
      final row = Board.selectedIndex.value! ~/ Board.boardSize;
      final col = Board.selectedIndex.value! % Board.boardSize;
      
      // Supprimer la lettre de la case actuelle
      Board.letters.value[row][col] = null;

      // Déplacer la sélection
      if (Board.isVertical.value && row > 0) {
        Board.selectedIndex.value = (row - 1) * Board.boardSize + col;
      } else {
        if (col > 0) {
        Board.selectedIndex.value = row * Board.boardSize + (col - 1);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const letters = [
      ['a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['q', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm'],
      ['w', 'x', 'c', 'v', 'b', 'n'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      //color: Colors.brown[300],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...letters.asMap().entries.map((entry) {
            int idx = entry.key;
            List<String> row = entry.value;
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flèche à gauche pour la dernière ligne
                if (idx == 2) 
                  ValueListenableBuilder<bool>(
                    valueListenable: Board.isVertical,
                    builder: (context, isVertical, _) {
                      return IconButton(
                        onPressed: () {
                          Board.isVertical.value = !Board.isVertical.value;
                        },
                        icon: Icon(
                          isVertical ? Icons.arrow_downward : Icons.arrow_forward,
                          color: Colors.blue,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                
                // Lettres
                ...row.map((letter) => Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: SizedBox(
                    width: 32,
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => _handleLetterPress(letter),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                      ),
                      child: Text(letter.toUpperCase()),
                    ),
                  ),
                )),
                
                // Retour arrière à droite pour la dernière ligne
                if (idx == 2)
                  IconButton(
                    onPressed: _handleBackspace,
                    icon: const Icon(Icons.backspace, color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    constraints: const BoxConstraints(),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}