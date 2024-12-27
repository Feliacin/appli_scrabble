// Classes et fonctions utiles pour la recherche du mot

import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:flutter/services.dart';

class PossibleLetters {
  List<String>? verticalPossibilities;
  List<String>? horizontalPossibilities;
  List<int>? verticalPoints;
  List<int>? horizontalPoints;
  
  List<String>? get(bool isHorizontal) {
    return isHorizontal ? horizontalPossibilities : verticalPossibilities;
  }

  List<int>? getPoints(bool isHorizontal) {
    return isHorizontal ? horizontalPoints : verticalPoints;
  }

  void open(bool isHorizontal) {
    if (isHorizontal) {
      horizontalPossibilities = [];
      horizontalPoints = [];
    } else {
      verticalPossibilities = [];
      verticalPoints = [];
    }
  }

  void add(String character, int points, bool isHorizontal) {
    if (isHorizontal) {
      horizontalPossibilities!.add(character);
      horizontalPoints!.add(points);
    } else {
      verticalPossibilities!.add(character);
      verticalPoints!.add(points);
    }
  }

  static List<List<PossibleLetters>> scan(List<List<String?>> letters) {
    List<List<PossibleLetters>> possibleLetters = List.generate(
      Board.boardSize, (_) => List.generate(
        Board.boardSize, (_) => PossibleLetters()));
    int lettersBefore, lettersAfter;

    for(int i=0; i<Board.boardSize; i++) {
      for(int j=0; j<Board.boardSize; j++) {
        if (letters[i][j] != null) { // Lettre placée
          continue;
        }
        for (bool isHorizontal in [true, false]) {
          if (isHorizontal) {
            for (lettersBefore=0; (j-lettersBefore > 0) && (letters[i][j-lettersBefore-1] != null); lettersBefore++) {
            }
            for (lettersAfter=0; (j+lettersAfter < Board.boardSize - 1) && (letters[i][j+lettersAfter+1] != null); lettersAfter++) {
            }
          } else {
            for (lettersBefore=0; (i-lettersBefore > 0) && (letters[i-lettersBefore-1][j] != null); lettersBefore++) {
            }
            for (lettersAfter=0; (i+lettersAfter < Board.boardSize - 1) && (letters[i+lettersAfter+1][j] != null); lettersAfter++) {
            }
          }
          if (lettersBefore+lettersAfter == 0) { // Pas de lettre autour
            continue;
          }
          possibleLetters[i][j].open(isHorizontal);
          for (int charCode = 'a'.codeUnitAt(0); charCode <= 'z'.codeUnitAt(0); charCode++) {
            String char = String.fromCharCode(charCode);
            var proposal = StringBuffer();
            for (int k= -lettersBefore; k<=lettersAfter; k++) {
              if (k == 0) {
                proposal.write(char);
              } else {
                if (isHorizontal) {
                  proposal.write(letters[i][j+k]);
                }
                else {
                  proposal.write(letters[i+k][j]);
                }
              }
            }
            if (MainApp.dictionary.exists(proposal.toString())) {
              int points = calculatePoints(proposal.toString());
              switch(Board.specialPositions[i][j]) {
                case 'TW':
                  points *= 3;
                  break;
                case 'DW':
                  points *= 2;
                  break;
                case 'TL':
                  points += calculatePoints(char) * 2;
                  break;
                case 'DL':
                  points += calculatePoints(char);
                  break;
              }
              possibleLetters[i][j].add(char, points, isHorizontal);
            }
          }
        }
      }
    }
    return possibleLetters;
  }
}

class PlayableWord {
  String word;
  int row;
  int col;
  bool isHorizontal;
  int points;

  PlayableWord(this.word, this.row, this.col, this.isHorizontal, this.points);

  void place() {
    List<List<String?>> letters = List.from(Board.letters.value);
    if (isHorizontal) {
      for (int j = 0; j < word.length; j++) {
        letters[row][col + j] = word[j];
      }
    } else {
      for (int i = 0; i < word.length; i++) {
        letters[row + i][col] = word[i];
      }
    }
    // Notifie que la valeur a changé
    Board.letters.value = letters;
  }
}

class BestWords {
  List<PlayableWord> words = [];
  final int lengthMax;

  BestWords(this.lengthMax);

  bool accepts(int points) {
    if (words.length < lengthMax) {
      return true;
    }
    return points > words.last.points;
  }

  void add(PlayableWord word) {
    int i = 0;
    while (i < words.length && words[i].points > word.points) {
      i++;
    }
    words.insert(i, word);
    if (words.length > lengthMax) {
      words.removeLast();
    }    
  }
}

class LetterCount {
  List<int> letterTable = List<int>.filled(26, 0);
  int blankCount = 0;

  LetterCount([String letters = '']) {
    addLetters(letters);
  }

  LetterCount copy() {
    LetterCount copy = LetterCount();
    copy.letterTable = List<int>.from(letterTable);
    copy.blankCount = blankCount;
    return copy;
  }

  bool equals(LetterCount other) {
    if (blankCount != other.blankCount) return false;
    for (int i = 0; i < 26; i++) {
      if (letterTable[i] != other.letterTable[i]) return false;
    }
    return true;
  }

  void addLetters(String letters) {
    letters = letters.toLowerCase();
    for (int i = 0; i < letters.length; i++) {
      int charCode = letters.codeUnitAt(i);
      if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
        letterTable[charCode - 'a'.codeUnitAt(0)]++;
      } else {
        blankCount++;
      }
    }
  }

  bool accepts(LetterCount other) {
    int remainingBlanks = blankCount;
    for (int i = 0; i < 26; i++) {
      int diff = letterTable[i] - other.letterTable[i];
      while (diff < 0) {
        if (remainingBlanks == 0) return false;
        remainingBlanks--;
        diff++;
      }
    }
    return true;
  }
}

// Caractéristiques des emplacements possibles des mots d'une certaine longueur
class PrecomputedPlacement {
  int positionWord = 0;
  List<String> forcedChar = [];
  List<int> forcedCharPositions = [];  // Indice par rapport au début du mot
  List<List<String>> limitedChar = [];
  List<int> limitedCharPositions = [];  // Indice par rapport au début du mot
  LetterCount? letterCount;
}

Map<String, int> letterPoints = {
  'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4, 'I': 1,
  'J': 8, 'K': 10, 'L': 1, 'M': 2, 'N': 1, 'O': 1, 'P': 3, 'Q': 8, 'R': 1,
  'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 10, 'X': 10, 'Y': 10, 'Z': 10
};

int calculatePoints(String word) {
  int points = 0;
  for (int i = 0; i < word.length; i++) {
    points += letterPoints[word[i].toUpperCase()]!;
  }
  return points;
}

List<T> extractRow<T>(List<List<T>> table, int rowIndex) {
  if (rowIndex < 0 || rowIndex >= table.length) {
    throw RangeError("Index en dehors des limites");
  }
  return table[rowIndex];
}

List<T> extractColumn<T>(List<List<T>> table, int columnIndex) {
  if (table.isEmpty || columnIndex < 0 || columnIndex >= table[0].length) {
    throw RangeError("Index en dehors des limites");
  }
  return table.map((row) => row[columnIndex]).toList();
}

class Dictionary {
  final List<Set<String>> wordsByLength = [];
  final Map<String, LetterCount> letterCounts = {};

  Future<void> load(String filePath) async {
    try {
      final String content = await rootBundle.loadString(filePath);
      final List<String> lines = content.split('\n');

      wordsByLength.addAll(List.generate(Board.boardSize + 1, (_) => {}));
      
      for (String word in lines) {
        word = word.trim();
        if (word.isEmpty) continue;
        wordsByLength[word.length].add(word);
        letterCounts[word] = LetterCount(word);
      }
    } catch (e) {
      throw Exception('Error loading dictionary: $e');
    }
  }
  
  bool exists(String word) => wordsByLength[word.length].contains(word);
}