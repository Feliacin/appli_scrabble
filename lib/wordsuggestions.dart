import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WordSuggestions extends StatefulWidget {
  const WordSuggestions({super.key});

  @override
  State<WordSuggestions> createState() => _WordSuggestionsState();
}

class _WordSuggestionsState extends State<WordSuggestions> {
  PlayableWord? selectedWord;
  late List<List<String?>> backupLetters;
  late List<int> backupBlanks;

  @override
  void initState() {
    super.initState();
    final boardState = context.read<BoardState>();
    backupLetters = List.from(
      boardState.letters.map((row) => List<String?>.from(row))
    );
    backupBlanks = List.from(boardState.blanks);
  }

  void _handleWordSelection(BuildContext context, PlayableWord word) {
    final boardState = context.read<BoardState>();
    
    // Restaurer l'état précédent
    boardState.setLetters(
      List.from(backupLetters.map((row) => List<String?>.from(row)))
    );
    boardState.setBlanks(List.from(backupBlanks));
    
    setState(() {
      if (selectedWord == word) {
        selectedWord = null;
      } else {
        boardState.place(word);
        selectedWord = word;
      }
    });
  }

  void _handleValidate(BuildContext context) {
    context.read<AppState>().clearWordSuggestions();
    setState(() {
      selectedWord = null;
    });
  }

  void _handleCancel(BuildContext context) {
  final boardState = context.read<BoardState>();
  
    boardState.setLetters(
      List.from(backupLetters.map((row) => List<String?>.from(row)))
    );
    boardState.setBlanks(List.from(backupBlanks));
    
    setState(() {
      selectedWord = null;
    });
    context.read<AppState>().clearWordSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: appState.wordSuggestions.length,
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  final word = appState.wordSuggestions[index];
                  final isSelected = word == selectedWord;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => _handleWordSelection(context, word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0
                        ),
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
                                fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0
                              ),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleValidate(context),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _handleCancel(context),
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