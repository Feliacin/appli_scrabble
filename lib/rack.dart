import 'package:flutter/material.dart';
import 'package:appli_scrabble/board.dart';

class Rack extends StatelessWidget {
  static ValueNotifier<List<String>> letters = ValueNotifier<List<String>>([]);
  static ValueNotifier<bool> isSelected = ValueNotifier<bool>(true);
  static const int maxLetters = 7;

  const Rack({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: letters,
                  builder: (context, letters, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(maxLetters, (index) {
                          final hasLetter = index < letters.length;
                          return GestureDetector(
                            onTap: () {
                              isSelected.value = true;
                              Board.selectedIndex.value = null;
                            },
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isSelected,
                              builder: (context, isRackSelected, _) {
                                return Container(
                                  width: 35,
                                  height: 35,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: hasLetter ? Colors.amber[100] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: isRackSelected && !hasLetter ? Colors.orange : Colors.brown[200]!,
                                      width: isRackSelected && !hasLetter ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: hasLetter
                                      ? Center(
                                          child: 
                                              Text(
                                                letters[index].toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                        )
                                      : null,
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
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
                    onTap: () => Board.findWord(letters.value),
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(Icons.search, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}