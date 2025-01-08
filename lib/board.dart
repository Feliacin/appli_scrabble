import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:flutter/material.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/useful_classes.dart';


class Board extends StatelessWidget {
  static const int boardSize = 15; // Taille standard du plateau de Scrabble

  static ValueNotifier<int?> selectedIndex = ValueNotifier<int?>(null);
  static ValueNotifier<List<List<String?>>> letters = ValueNotifier<List<List<String?>>>(
    List.generate(boardSize, (_) => List.filled(boardSize, null))
  );
  static ValueNotifier<List<int>> blanks = ValueNotifier<List<int>>([]);
  static ValueNotifier<bool> isVertical = ValueNotifier<bool>(false);
  static final ValueNotifier<String> boardType = ValueNotifier<String>('scrabble');

  // Description des cases spéciales
  static List<List<String>> specialPositions = _initializeSpecialPositions('scrabble');

  static List<List<String>> _initializeSpecialPositions(String type) {
    final List<List<String>> positions =
      List.generate(boardSize, (_) => List.filled(boardSize, ' '));
      
    final Map<String, List<List<int>>> initialPositions = type == 'scrabble'
      ? {
        'TW': [[0, 0], [0, 7], [7, 0]],
        'DW': [[1, 1], [2, 2], [3, 3], [4, 4], [7, 7]],
        'TL': [[1, 5], [5, 1], [5, 5]],
        'DL': [[0, 3], [2, 6], [3, 0], [6, 2], [6, 6]]
      }
      : {
        'TW': [[0, 3], [3, 0]],
        'DW': [[1, 7], [7, 1], [4, 4]],
        'TL': [[1, 2], [2, 1]],
        'DL': [[3, 5], [2, 6], [5, 3], [6, 2], [5, 7], [7, 5], [6, 6]]
      };

    initialPositions.forEach((type, posList) {
      for (var pos in posList) {
        int x = pos[0];
        int y = pos[1];
        positions[x][y] = type;
        positions[x][boardSize - 1 - y] = type;
        positions[boardSize - 1 - x][y] = type;
        positions[boardSize - 1 - x][boardSize - 1 - y] = type;
      }
    });

    return positions;
  }

  static void write(String letter, int i, int j) {
    final newLetters = List<List<String?>>.from(letters.value);
    newLetters[i][j] = letter;
    Board.letters.value = newLetters;
  }

  static void reset() {
    letters.value = List.generate(boardSize, (_) => List.filled(boardSize, null));
    blanks.value = [];
    specialPositions = _initializeSpecialPositions(boardType.value);
  }

  static final Map<String, Color> specialColors = {
    'TW': Colors.red[300]!, // Triple Word
    'DW': Colors.pink[200]!, // Double Word
    'TL': Colors.blue[300]!, // Triple Letter
    'DL': Colors.lightBlue[200]!, // Double Letter
    '': Colors.white
  };

  const Board({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ValueListenableBuilder<String>(
        valueListenable: boardType,
        builder: (context, type, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.brown[300],
              border: Border.all(color: Colors.brown[300]!, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: boardSize,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
              ),
              itemCount: boardSize * boardSize,
              itemBuilder: (context, index) {
                return Tile(
                  propriete: specialPositions[index ~/ boardSize][index % boardSize],
                  index: index
                );
              },
            ),
          );
        },
      ),
    );
  }

  static void findWord(List<String> rack) {
    if (rack.isEmpty) return;
    List<List<PossibleLetters>> possibleLetters = PossibleLetters.scan(letters.value);
    List<int> connections;
    var bestWords = BestWords(10);
    int middle = boardSize ~/ 2;
    if (Board.letters.value[middle][middle] == null) { // Premier mot
      connections = [middle];
      findWordOnLine(rack, middle, true, possibleLetters, connections, bestWords);
    } else {
      for (bool isRow in [true, false]) {
        for (int i=0; i<boardSize; i++) { // Parcours des lignes ou colonnes
          connections = []; // La liste des indices où on peut accrocher un mot - liste croissante
          for (int j = 0; j < boardSize; j++) {
            // Accès aux positions selon la direction
            int row = isRow ? i : j;
            int col = isRow ? j : i;

            // S'il n'y a pas de lettre sur la case mais une à côté à laquelle se lier
            if (possibleLetters[row][col].get(true) != null || possibleLetters[row][col].get(false) != null) {
              connections.add(j);
            }
          }
          if (connections.isNotEmpty) {
              findWordOnLine(rack, i, isRow, possibleLetters, connections, bestWords);
          }
        }
      }
    }
    GameScreen.wordSuggestions.value = bestWords.words;
  }

  static void findWordOnLine(List<String> rack, int index, bool isRow, List<List<PossibleLetters>> possibleLettersTable, List<int> connections,  BestWords bestWords) {
    int position, points, extra, factor, playedLettersCount;
    bool isBlank;
    List<String?> lettersLine;
    List<String> specialPositionsLine;
    List<PossibleLetters> possibleLettersLine;
    List<int> blanksPlaced;
    List<List<int>> possiblePositions = List.generate(boardSize + 1, (_) => []);

    if (isRow) {
      lettersLine = extractRow(letters.value, index);
      specialPositionsLine = extractRow(specialPositions, index);
      possibleLettersLine = extractRow(possibleLettersTable, index);
      blanksPlaced = blanks.value.where((i) => i ~/ boardSize == index).map((i) => i % boardSize).toList();
    } else {
      lettersLine = extractColumn(letters.value, index);
      specialPositionsLine = extractColumn(specialPositions, index);
      possibleLettersLine = extractColumn(possibleLettersTable, index);
      blanksPlaced = blanks.value.where((i) => i % boardSize == index).map((i) => i ~/ boardSize).toList();
    }

    // Pré-calcul des positions possibles
    for (int wordLength = 2; wordLength <= Board.boardSize; wordLength++) {
      position = 0; // Emplacement du début du mot
      for (int k = 0; k < connections.length; k++) {
        // Le but est que le mot dispose d'un caractère sur connections[k]
        while (position + wordLength - 1 < connections[k]) {
          position++;
        }
        for (; position + wordLength - 1 < Board.boardSize && position <= connections[k]; position++) {
          // On ne peut pas choisir un emplacement précédé ou suivi par une lettre
          if ((position == 0 || lettersLine[position-1] == null) && 
            (position + wordLength == Board.boardSize || lettersLine[position + wordLength] == null)) {
            possiblePositions[wordLength].add(position);
          }
        }
      }
    }
    for (int wordLength=2; wordLength <= Board.boardSize; wordLength++) {
      for (var position in possiblePositions[wordLength]) {
        for (PlayableWord playableWord in MainApp.dictionary.getPossibleWords(
            rack,
            wordLength,
            lettersLine.sublist(position, position + wordLength),
            possibleLettersLine.sublist(position, position + wordLength).map((possibleLetters) => possibleLetters.get(!isRow)).toList())
            ) {
          // Calcul des points
          points = 0;
          extra = 0;
          playedLettersCount = 0;
          String word = playableWord.word;
          for (int k = 0; k < word.length; k++) {
            if(lettersLine[position + k] != null) {
              if (!blanksPlaced.contains(position + k)) {
                points += calculatePoints(word[k]);
              }
              continue;
            }
            playedLettersCount++;
            isBlank = playableWord.blankPositions.contains(k);
            if (possibleLettersLine[position + k].get(!isRow) != null) {
              int index = possibleLettersLine[position + k].get(!isRow)!.indexOf(word[k]);
              extra += possibleLettersLine[position + k].getPoints(!isRow)![index];
              factor = {'TL': 3, 'DL': 2, 'TW': 3, 'DW': 2}[specialPositionsLine[position + k]] ?? 1;
              extra -= isBlank ? factor * calculatePoints(word[k]) : 0;
            }
            factor = {'TL': 3, 'DL': 2}[specialPositionsLine[position + k]] ?? 1;
            points += !isBlank ? factor * calculatePoints(word[k]) : 0;
          }
          for (int k=0; k<word.length; k++) {
            if (lettersLine[position + k] != null) continue;
            if (specialPositionsLine[position + k] == 'DW') {
              points *= 2;
            } else if (specialPositionsLine[position + k] == 'TW') {
              points *= 3;
            }
          }
          points += extra;
          if (playedLettersCount == Rack.maxLetters) {
            points += boardType.value == 'scrabble' ? 50 : 49; // Bonus pour avoir utilisé toutes les lettres
          }

          // Comparaison avec les meilleurs mots
          if (bestWords.accepts(points)) {
            playableWord.points = points;
            isRow
              ? playableWord.setPosition(index, position, true)
              : playableWord.setPosition(position, index, false);
            bestWords.add(playableWord);
          }
        }
      }
    }
  }
}