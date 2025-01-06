import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:appli_scrabble/rack.dart';

class WordSuggestions extends StatelessWidget {
  final ValueNotifier<PlayableWord?> selectedWord = ValueNotifier<PlayableWord?>(null);
  final List<List<String?>> backUpLetters = List.from(Board.letters.value.map((row) => List<String?>.from(row)));
  final List<int> backUpBlanks = List.from(Board.blanks.value);

  WordSuggestions({super.key});

  void _handleWordSelection(PlayableWord word) {
    Board.letters.value = List.from(backUpLetters.map((row) => List<String?>.from(row)));
    Board.blanks.value = List.from(backUpBlanks);
    if (selectedWord.value == word) {
      selectedWord.value = null;
    } else {
      word.place();
      selectedWord.value = word;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ValueListenableBuilder<List<PlayableWord>>(
            valueListenable: GameScreen.wordSuggestions,
            builder: (context, words, _) {
              return ValueListenableBuilder<PlayableWord?>(
                valueListenable: selectedWord,
                builder: (context, currentWord, _) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: words.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final isSelected = word == currentWord;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => _handleWordSelection(word),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.brown[100] : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.brown : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  word.word.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.brown : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${word.points} pts',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Rack.letters.value = [];
                  GameScreen.wordSuggestions.value = [];
                  selectedWord.value = null;
                },
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Board.letters.value = List.from(backUpLetters.map((row) => List<String?>.from(row)));
                  Board.blanks.value = List.from(backUpBlanks);
                  selectedWord.value = null;
                  GameScreen.wordSuggestions.value = [];
                },
                icon: const Icon(Icons.close),
                label: const Text('Annuler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}