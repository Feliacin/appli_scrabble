import 'package:appli_scrabble/main.dart';
import 'package:flutter/material.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/useful_classes.dart';


class Board extends StatelessWidget {
  static const int boardSize = 15; // Taille standard du plateau de Scrabble

  static ValueNotifier<int?> selectedIndex = ValueNotifier<int?>(null);
  static ValueNotifier<List<List<String?>>> letters = ValueNotifier<List<List<String?>>>(
    List.generate(boardSize, (_) => List.filled(boardSize, null))
  );
  static ValueNotifier<bool> isVertical = ValueNotifier<bool>(false);

  // Description des cases spéciales
  static final List<List<String>> specialPositions = (() {
    final List<List<String>> positions =
      List.generate(boardSize, (_) => List.filled(boardSize, ' '));
      
    final Map<String, List<List<int>>> initialPositions  = {
      'TW': [[0, 0], [0, 7], [7, 0]],
      'DW': [[1, 1], [2, 2], [3, 3], [4, 4]],
      'TL': [[1, 5], [5, 1], [5, 5]],
      'DL': [[0, 3], [2, 6], [3, 0], [6, 2], [6, 6]],
      'ST': [[7, 7]]
    };

    initialPositions.forEach((type, posList) {
      for (var pos in posList) {
        int x = pos[0];
        int y = pos[1];
        positions[x][y] = type;
        positions[x][boardSize - 1 - y] = type;
        positions[boardSize - 1 - x][y] = type;
        positions[x][y] = type;
        positions[boardSize - 1 - x][boardSize - 1 - y] = type;
      }
    });

    return positions;
  })();

  static final Map<String, Color> specialColors = {
    'TW': Colors.red[300]!, // Triple Word
    'DW': Colors.pink[200]!, // Double Word
    'TL': Colors.blue[300]!, // Triple Letter
    'DL': Colors.lightBlue[200]!, // Double Letter
    'ST': Colors.pink[300]!, // Starting point (centre)
    '': Colors.white
  };

  const Board({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[300],
          border: Border.all(color: Colors.brown[300]!, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
            crossAxisSpacing: 2.0, // Espace horizontal
            mainAxisSpacing: 2.0, // Espace vertical
          ),
          itemCount: boardSize * boardSize,
          itemBuilder: (context, index) {
            return Tile(propriete: specialPositions[index ~/ boardSize][index % boardSize],
                        index: index);
          },
        ),
      ),
    );
  }

  static void findWord(String rack) {
    if (rack.isEmpty) return;
    List<List<PossibleLetters>> possibleLetters = PossibleLetters.scan(letters.value);
    List<int> connections;
    var rackLetterCount = LetterCount(rack);
    var bestWords = BestWords(5);
    int middle = boardSize ~/ 2;
    if (Board.letters.value[middle][middle] == null) { // Premier mot
      connections = [middle];
      findWordOnLine(rackLetterCount, middle, true, possibleLetters, connections, bestWords);
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
              findWordOnLine(rackLetterCount, i, isRow, possibleLetters, connections, bestWords);
          }
        }
      }
    }
    GameScreen.wordSuggestions.value = bestWords.words;
  }

  static void findWordOnLine(LetterCount rackLetterCount, int index, bool isRow, List<List<PossibleLetters>> possibleLettersTable, List<int> connections,  BestWords bestWords) {
    int position, points, extra;
    bool ok;
    List<List<PrecomputedPlacement>> precomputedPlacements =  // Contraintes de placements selon la longueur du mot
      List.generate(boardSize + 1, (_) => <PrecomputedPlacement>[]); // Indices 0 et 1 inutilisés
    List<String?> lettersLine;
    List<String> specialPositionsLine;
    List<PossibleLetters> possibleLettersLine;

    if (isRow) {
      lettersLine = extractRow(letters.value, index);
      specialPositionsLine = extractRow(specialPositions, index);
      possibleLettersLine = extractRow(possibleLettersTable, index);
    } else {
      lettersLine = extractColumn(letters.value, index);
      specialPositionsLine = extractColumn(specialPositions, index);
      possibleLettersLine = extractColumn(possibleLettersTable, index);
    }

    for (int wordLength = 2; wordLength <= Board.boardSize; wordLength++) {
      position = 0; // Emplacement du début du mot
      for (int k = 0; k < connections.length; k++) {
        // Le but est que le mot dispose d'un caractère sur connections[k]
        while (position + wordLength - 1 < connections[k]) {
          position++;
        }
        for (; position + wordLength - 1 < Board.boardSize && position <= connections[k]; position++) {
          // On ne peut pas choisir un emplacement précédé ou suivi par une lettre
          if ((position != 0 && lettersLine[position-1] != null) || 
            (position + wordLength != Board.boardSize && lettersLine[position + wordLength] != null)) {
            continue;
          }
          var infoPlacement = PrecomputedPlacement();
          infoPlacement.positionWord = position;
          ok = true;
          for (int l = 0; l < wordLength; l++) {
            if (lettersLine[position + l] != null) { // Lettre imposée
              infoPlacement.forcedChar.add(lettersLine[position + l]!);
              infoPlacement.forcedCharPositions.add(l);
            } else {
              var possibleLetters = possibleLettersLine[position + l].get(!isRow); // possibilités dans le sens contraire d'écriture
              if (possibleLetters != null) {
                if (possibleLetters.isEmpty) {
                    ok = false; // Aucune possibilité de mot
                    break;
                } else {
                    infoPlacement.limitedChar.add(possibleLetters);
                    infoPlacement.limitedCharPositions.add(l);
                }
              }
            }
          }
          if (ok) {
            infoPlacement.letterCount = rackLetterCount.copy();
            for (int l = 0; l < infoPlacement.forcedChar.length; l++) {
                infoPlacement.letterCount!.addLetters(infoPlacement.forcedChar[l]);
            }
            precomputedPlacements[wordLength].add(infoPlacement);
          }
        }
      }
    }
    for (int wordLength=2; wordLength <= Board.boardSize; wordLength++) {
      for (var infoPlacement in precomputedPlacements[wordLength]) {
        for (String word in MainApp.dictionary.wordsByLength[wordLength]) {
          // Plusieurs filtres préalables
          // (1/3) Il faut qu'on dispose des lettres nécessaires (ou de blancs)
          if (!infoPlacement.letterCount!.accepts(MainApp.dictionary.letterCounts[word]!)) continue;

          // (2/3) On peut placer ici un mot de n lettres, mais il faut que les lettres forcées correspondent
          ok = true;
          for (int k=0; k < infoPlacement.forcedChar.length; k++) {
            if (infoPlacement.forcedChar[k] != word[infoPlacement.forcedCharPositions[k]]) {
              ok = false;
              break;
            }
          }
          if (!ok) continue;

          // (3/3) Il faut enfin que les lettres placées sur les liaisons entrent dans les possibilités
          ok = true;
          for (int k = 0; k < infoPlacement.limitedChar.length; k++) {
            if (!infoPlacement.limitedChar[k].contains(word[infoPlacement.limitedCharPositions[k]])) {
                ok = false;
                break;
            }
          }
          if (!ok) continue;

          // Le mot est jouable, calcul des points
          points = 0;
          extra = 0;
          position = infoPlacement.positionWord;
          for (int k = 0; k < word.length; k++) {
            if(lettersLine[k] != null) {
              points += calculatePoints(word[k]);
              continue;
            }
            if (possibleLettersLine[position + k].get(!isRow) != null) {
              int index = possibleLettersLine[position + k].get(!isRow)!.indexOf(word[k]);
              extra += possibleLettersLine[position + k].getPoints(!isRow)![index];
            }
            switch(specialPositionsLine[position + k]) {
              case 'DL':
                points += 2 * calculatePoints(word[k]);
                break;
              case 'TL':
                points += 3 * calculatePoints(word[k]);
                break;
              default:
                points += calculatePoints(word[k]);
                break;
            }
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
          if (infoPlacement.letterCount!.equals(MainApp.dictionary.letterCounts[word]!)) {
            points += 50; // Bonus pour avoir utilisé toutes les lettres
          }
          if (bestWords.accepts(points)) {
            if (isRow) {
              bestWords.add(PlayableWord(word, index, position, true, points));
            } else {
              bestWords.add(PlayableWord(word, position, index, false, points));
            }
          }
        }
      }
    }
  }
}