import 'package:appli_scrabble/main.dart';
import 'package:flutter/material.dart';
import 'package:appli_scrabble/board.dart';

class Rack extends StatelessWidget {
  static var letters = ValueNotifier<List<String?>>(List.filled(maxLetters+1, null));
  static var isSelected = ValueNotifier<bool>(true);
  static const int maxLetters = 7;

  const Rack({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: GameScreen.isGameMode,
            builder: (context, isGameMode, _) {
              return ValueListenableBuilder<List<String?>>(
                valueListenable: letters,
                builder: (context, lettersValue, _) {
                  return isGameMode ?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(maxLetters+1, (index) {
                          final hasLetter = lettersValue[index] != null;
                          return GestureDetector(
                            onTap: hasLetter ? () {
                              final newLetters = List<String?>.from(lettersValue);
                              final indexOfNull = newLetters.indexOf(null);
                              final letter = lettersValue[index]!;
                              if (index>indexOfNull) {
                                for (int i = index; i>indexOfNull; i--) {
                                  newLetters[i] = newLetters[i-1];
                                }
                              } else {
                                for (int i = index; i<indexOfNull; i++) {
                                  newLetters[i] = newLetters[i+1];
                                }
                              }
                              newLetters[indexOfNull] = letter;                              
                              letters.value = newLetters;
                            } : null,
                            child: Draggable<_DragData>(
                              data: hasLetter ? _DragData(letter: lettersValue[index]!, rackIndex: index) : null,
                              feedback: hasLetter ? _buildTile(lettersValue[index]!) : Container(),
                              childWhenDragging: _buildTile(null),
                              child: DragTarget<_DragData> (
                                onAccept: (data) {
                                // Gérer le déplacement des lettres dans le rack
                                  final newLetters = List<String?>.from(lettersValue);
                                  if(hasLetter) {
                                    // Échanger les lettres]
                                    final letter = newLetters[index];
                                    newLetters[index] = data.letter;
                                    newLetters[data.rackIndex] = letter;
                                  } else {
                                    // Déplacer vers un emplacement vide
                                    newLetters[index] = data.letter;
                                    newLetters[data.rackIndex] = null;
                                  }
                                  letters.value = newLetters;
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return _buildTile(lettersValue[index]);
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(maxLetters, (index) {
                        return GestureDetector(
                          onTap: () {
                            isSelected.value = true;
                            Board.selectedIndex.value = null;
                            print(isSelected.value);
                          },
                          child: ValueListenableBuilder<bool>(
                            valueListenable: isSelected,
                            builder: (context, isRackSelected, _) {
                              return _buildTile(lettersValue[index]);
                            },
                          ),
                        );
                      }),
                      const SizedBox(width: 16),
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Board.findWord(letters.value.whereType<String>().toList()),
                            borderRadius: BorderRadius.circular(8),
                            child: const Icon(Icons.search, size: 20, color: Colors.white),
                          ),
                        )
                      ),
                    ],
                  );
                }
              );
            }
          ),
        ),
      ],
    );
  }


  Widget _buildTile(String? letter) {
  return ValueListenableBuilder<bool>(
    valueListenable: isSelected,
    builder: (context, isRackSelected, _) {
      return Container(
        width: 35,
        height: 35,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: letter != null 
            ? Colors.amber[100]
            : Colors.grey[200],
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isRackSelected 
              ? Colors.brown[200]!
              : Colors.brown[100]!,
            width: isRackSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRackSelected ? 0.2 : 0.1),
              spreadRadius: 0,
              blurRadius: isRackSelected ? 3 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: letter != null
          ? Center(
              child: Text(
                letter.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            )
          : null,
      );
    },
  );
}
}

  class _DragData {
  final String letter;
  final int rackIndex;

  _DragData({required this.letter, required this.rackIndex});
}