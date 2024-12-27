import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:appli_scrabble/rack.dart';

class WordSuggestions extends StatelessWidget {
  final ValueNotifier<PlayableWord?> selectedWord = ValueNotifier<PlayableWord?>(null);
  final List<List<String?>> backUp = List.from(Board.letters.value.map((row) => List<String?>.from(row)));

  WordSuggestions({super.key});

  void _handleWordSelection(PlayableWord word) {
    Board.letters.value = List.from(backUp.map((row) => List<String?>.from(row)));
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
      children: [
        Expanded(
          child: ValueListenableBuilder<List<PlayableWord>>(
            valueListenable: GameScreen.wordSuggestions,
            builder: (context, words, _) {
              return ValueListenableBuilder<PlayableWord?>(
                valueListenable: selectedWord,
                builder: (context, currentWord, _) {
                  return ListView.builder(
                    itemCount: words.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final isSelected = word == currentWord;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                        elevation: isSelected ? 2 : 1,
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.white,
                        child: InkWell(
                          onTap: () => _handleWordSelection(word),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  word.word,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected 
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${word.points} pts',
                                    style: TextStyle(
                                      fontSize: 14,
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Rack.letters.value = [];
                  GameScreen.wordSuggestions.value = [];
                  selectedWord.value = null;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.check, size: 24),
              ),
              ElevatedButton(
                onPressed: () {
                  Board.letters.value = List.from(backUp.map((row) => List<String?>.from(row)));
                  selectedWord.value = null;
                  GameScreen.wordSuggestions.value = [];
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.close, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}