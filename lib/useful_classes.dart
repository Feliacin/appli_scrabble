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
                } else {
                  proposal.write(letters[i+k][j]);
                }
              }
            }
            if (MainApp.dictionary.exists(proposal.toString())) {
              int points = calculatePoints(proposal.toString());
              for (int blank in Board.blanks.value) {
                if (isHorizontal) {
                  if (i * Board.boardSize + j - lettersBefore <= blank && blank <= i * Board.boardSize + j + lettersAfter) {
                    points -= calculatePoints(proposal.toString()[blank % Board.boardSize - (j - lettersBefore)]);
                  }
                } else {
                  if ((blank-j) % Board.boardSize == 0 && blank ~/ Board.boardSize >= i - lettersBefore && blank ~/ Board.boardSize <= i + lettersAfter) {
                    points -= calculatePoints(proposal.toString()[blank ~/ Board.boardSize - (i - lettersBefore)]);
                  }
                }
              }
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
  List<int> blankPositions;

  PlayableWord(this.word, this.row, this.col, this.isHorizontal, this.points, this.blankPositions);

  void place() {
    List<List<String?>> letters = List.from(Board.letters.value);
    List<int> blanks = List.from(Board.blanks.value);
    for (int i = 0; i < word.length; i++) {
      isHorizontal
        ? letters[row][col + i] = word[i]
        : letters[row + i][col] = word[i];
    }
    for (int blankPosition in blankPositions) {
      isHorizontal
        ? blanks.add(row * Board.boardSize + col + blankPosition)
        : blanks.add((row + blankPosition) * Board.boardSize + col);
    }
    // Notifie que la valeur a changé
    Board.letters.value = letters;
    Board.blanks.value = blanks;
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
  int size = 0;

  LetterCount([String letters = '']) {
    addLetters(letters);
  }

  LetterCount copy() {
    LetterCount copy = LetterCount();
    copy.letterTable = List<int>.from(letterTable);
    copy.blankCount = blankCount;
    copy.size = size;
    return copy;
  }

  void addLetters(String letters) {
    letters = letters;
    for (int i = 0; i < letters.length; i++) {
      int charCode = letters.codeUnitAt(i);
      if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
        letterTable[charCode - 'a'.codeUnitAt(0)]++;
      } else {
        blankCount++;
      }
      size ++;
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

  List<String> getMissingLetters(LetterCount other) {
    List<String> difference = [];
    for (int i = 0; i < 26; i++) {
      int diff = other.letterTable[i] - letterTable[i];
      while (diff > 0) {
        difference.add(String.fromCharCode('a'.codeUnitAt(0) + i));
        diff--;
      }
    }
    return difference;
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

Map<String, int> letterPoints() => Board.boardType.value == 'scrabble' 
  ?  {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4, 'I': 1,
    'J': 8, 'K': 10, 'L': 1, 'M': 2, 'N': 1, 'O': 1, 'P': 3, 'Q': 8, 'R': 1,
    'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 10, 'X': 10, 'Y': 10, 'Z': 10
  }
  : {
    'A': 1, 'B': 5, 'C': 3, 'D': 4, 'E': 1, 'F': 5, 'G': 4, 'H': 5, 'I': 1,
    'J': 7, 'K': 10, 'L': 2, 'M': 3, 'N': 1, 'O': 1, 'P': 4, 'Q': 7, 'R': 1,
    'S': 1, 'T': 1, 'U': 2, 'V': 5, 'W': 10, 'X': 8, 'Y': 8, 'Z': 8
  };


int calculatePoints(String word) {
  int points = 0;
  for (int i = 0; i < word.length; i++) {
    points += letterPoints()[word[i].toUpperCase()]!;
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

int minimiseBlankLoss (List<int> blankPositions, int begining, List<String> specialPositions, List<PossibleLetters> possibleLetters, bool isHorizontal) {
  int blankLoss (int position) {
    int loss = {
      'TL': 2,
      'DL': 1,
    }[specialPositions[begining + position]] ?? 0;
    if (possibleLetters[begining + position].get(!isHorizontal) != null) {
      loss += {
        'TW': 3,
        'DW': 2,
        'TL': 3,
        'DL': 2,
      }[specialPositions[begining + position]] ?? 1;
    }
    return loss;
  }
  return blankPositions.reduce((min, element) => blankLoss(element) < blankLoss(min) ? element : min);
}

// class Dictionary {
//   final List<Set<String>> wordsByLength = [];
//   final Map<String, LetterCount> letterCounts = {};

//   Future<void> load(String filePath) async {
//     try {
//       final String content = await rootBundle.loadString(filePath);
//       final List<String> lines = content.split('\n');

//       wordsByLength.addAll(List.generate(Board.boardSize + 1, (_) => {}));
      
//       for (String word in lines) {
//         word = word.trim();
//         if (word.isEmpty) continue;
//         wordsByLength[word.length].add(word);
//         letterCounts[word] = LetterCount(word);
//       }
//       print('Dictionary loaded');
//     } catch (e) {
//       throw Exception('Error loading dictionary: $e');
//     }
//   }
  
//   bool exists(String word) => wordsByLength[word.length].contains(word);
// }



class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
}

class Dictionary {
  final List<TrieNode> _rootsByLength = [];

  Future<void> load(String filePath) async {
    try {
      final String content = await rootBundle.loadString(filePath);
      final List<String> lines = content.split('\n');

      // Initialiser les racines pour chaque longueur possible
      _rootsByLength.addAll(List.generate(Board.boardSize + 1, (_) => TrieNode()));
      
      for (String word in lines) {
        word = word.trim();
        if (word.isEmpty) continue;
        
        // Ajouter le mot dans le Trie correspondant à sa longueur
        _insertWord(word);
      }
      print('Dictionary loaded');
    } catch (e) {
      throw Exception('Error loading dictionary: $e');
    }
  }

  void _insertWord(String word) {
    TrieNode current = _rootsByLength[word.length];
    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      current.children.putIfAbsent(letter, () => TrieNode());
      current = current.children[letter]!;
    }
    current.isEndOfWord = true;
  }
  
  bool exists(String word) {
    TrieNode? current = _rootsByLength[word.length];
    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      current = current?.children[letter];
      if (current == null) return false;
    }
    return current!.isEndOfWord;
  }

  // Trouve tous les mots possibles d'une longueur donnée avec les lettres disponibles
  Set<String> getPossibleWords(
    List<String> rack,
    int length,
    List<String?> placedLetters,
    List<List<String>?> possibleLetters
  ) {
    Set<String> words = {};
    _getWordsWithPrefix(
      _rootsByLength[length],
      rack.toList(), // On fait une copie pour ne pas modifier le rack original
      length,
      "",
      placedLetters,
      possibleLetters,
      words
    );
    return words;
  }

  void _getWordsWithPrefix(
    TrieNode node,
    List<String> remainingLetters,
    int targetLength,
    String prefix,
    List<String?> placedLetters,
    List<List<String>?> possibleLetters,
    Set<String> results
  ) {
    // Si on a atteint la longueur cible et que c'est un mot valide
    if (prefix.length == targetLength) {
      if (node.isEndOfWord) {
        results.add(prefix);
      }
      return;
    }

    // Position actuelle dans la ligne
    int position = prefix.length;
    
    // Si on a une lettre fixe à cette position
    if (placedLetters[position] != null) {
      TrieNode? nextNode = node.children[placedLetters[position]!];
      if (nextNode != null) {
        _getWordsWithPrefix(
          nextNode,
          remainingLetters,
          targetLength,
          prefix + placedLetters[position]!,
          placedLetters,
          possibleLetters,
          results
        );
      }
      return;
    }

    // Pour chaque lettre possible à cette position
    for (int i = 0; i < remainingLetters.length; i++) {
      String letter = remainingLetters[i];
      
      // Vérifier si la lettre est autorisée à cette position
      if (possibleLetters[position] != null && !possibleLetters[position]!.contains(letter)) {
        continue;
      }
      
      if (node.children.containsKey(letter)) {
        // Retirer la lettre du rack et continuer récursivement
        remainingLetters.removeAt(i);
        _getWordsWithPrefix(
          node.children[letter]!,
          remainingLetters,
          targetLength,
          prefix + letter,
          placedLetters,
          possibleLetters,
          results
        );
        // Remettre la lettre dans le rack pour la prochaine itération
        remainingLetters.insert(i, letter);
      }
    }
  }
}

// Pour chaque longueur de mot, la classe contient un node racine, dont le champs children contient des node pour chaque première lettre possible.
// Ces nodes secondaires contiennent des enfants pour chaque seconde lettre possible à partir de cette lettre de départ.
// Ainsi de suite jusqu'à la fin du mot de longueur fixée d'avance.
// Il faut une fonction récursive comme ça : getWordsWithPrefix(rack, length, prefix, lettersLine, possibleLettersLine)
