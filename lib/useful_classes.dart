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

  static List<List<PossibleLetters>> scan(BoardState boardState) {
    List<List<PossibleLetters>> possibleLetters = List.generate(
      BoardState.boardSize, (_) => List.generate(
        BoardState.boardSize, (_) => PossibleLetters()));
    int lettersBefore, lettersAfter;
    var letters = boardState.letters;

    for(int i=0; i<BoardState.boardSize; i++) {
      for(int j=0; j<BoardState.boardSize; j++) {
        if (letters[i][j] != null) { // Lettre placée
          continue;
        }
        for (bool isHorizontal in [true, false]) {
          if (isHorizontal) {
            for (lettersBefore=0; (j-lettersBefore > 0) && (letters[i][j-lettersBefore-1] != null); lettersBefore++) {
            }
            for (lettersAfter=0; (j+lettersAfter < BoardState.boardSize - 1) && (letters[i][j+lettersAfter+1] != null); lettersAfter++) {
            }
          } else {
            for (lettersBefore=0; (i-lettersBefore > 0) && (letters[i-lettersBefore-1][j] != null); lettersBefore++) {
            }
            for (lettersAfter=0; (i+lettersAfter < BoardState.boardSize - 1) && (letters[i+lettersAfter+1][j] != null); lettersAfter++) {
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
              int points = boardState.calculatePoints(proposal.toString());
              for (int blank in boardState.blanks) {
                if (isHorizontal) {
                  if (i * BoardState.boardSize + j - lettersBefore <= blank && blank <= i * BoardState.boardSize + j + lettersAfter) {
                    points -= boardState.calculatePoints(proposal.toString()[blank % BoardState.boardSize - (j - lettersBefore)]);
                  }
                } else {
                  if ((blank-j) % BoardState.boardSize == 0 && blank ~/ BoardState.boardSize >= i - lettersBefore && blank ~/ BoardState.boardSize <= i + lettersAfter) {
                    points -= boardState.calculatePoints(proposal.toString()[blank ~/ BoardState.boardSize - (i - lettersBefore)]);
                  }
                }
              }
              switch(boardState.specialPositions[i][j]) {
                case 'TW':
                  points *= 3;
                  break;
                case 'DW':
                  points *= 2;
                  break;
                case 'TL':
                  points += boardState.calculatePoints(char) * 2;
                  break;
                case 'DL':
                  points += boardState.calculatePoints(char);
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
  List<int> blankPositions;
  int row;
  int col;
  bool isHorizontal;
  int points;

  PlayableWord(this.word,  this.blankPositions, {this.row = -1, this.col = -1, this.isHorizontal = true, this.points = 0});

  void setPosition(int row, int col, bool isHorizontal) {
    this.row = row;
    this.col = col;
    this.isHorizontal = isHorizontal;
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

class TrieNode {
  Map<String, TrieNode> children = {};
}

class Dictionary {
  final List<TrieNode> _rootsByLength = [];

  Future<void> load(String filePath) async {
    try {
      final String content = await rootBundle.loadString(filePath);
      final List<String> lines = content.split('\n');

      // Initialiser les racines pour chaque longueur possible
      _rootsByLength.addAll(List.generate(BoardState.boardSize + 1, (_) => TrieNode()));
      
      for (String word in lines) {
        word = word.trim();
        if (word.isEmpty) continue;
        
        // Ajouter le mot dans le Trie correspondant à sa longueur
        _insertWord(word);
      }
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
  }
  
  bool exists(String word) {
    TrieNode? current = _rootsByLength[word.length];
    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      current = current?.children[letter];
      if (current == null) return false;
    }
    return true;
  }

  // Trouve tous les mots possibles d'une longueur donnée avec les lettres disponibles
  Set<PlayableWord> getPossibleWords(
    List<String> rack,
    int length,
    List<String?> placedLetters,
    List<List<String>?> possibleLetters
  ) {
    Set<PlayableWord> words = {};
    Map<String, int> rackLetters = {};
    int blankCount = 0;
    
    // Séparer les blancs des lettres normales
    for (String letter in rack) {
      if (letter == ' ') {
        blankCount++;
      } else {
        rackLetters[letter] = (rackLetters[letter] ?? 0) + 1;
      }
    }
    
    _getWordsWithPrefix(
      _rootsByLength[length],
      rackLetters,
      blankCount,
      length,
      "",
      placedLetters,
      possibleLetters,
      words,
      []  // Liste pour suivre les positions des blancs
    );
    return words;
  }

  void _getWordsWithPrefix(
    TrieNode node,
    Map<String, int> remainingLetters,
    int remainingBlanks,
    int targetLength,
    String prefix,
    List<String?> placedLetters,
    List<List<String>?> possibleLetters,
    Set<PlayableWord> results,
    List<int> blankPositions
  ) {
    if (prefix.length == targetLength) {
      results.add(PlayableWord(prefix, blankPositions));
      return;
    }

    int position = prefix.length;
    
    // Si une lettre est déjà placée à cette position
    if (placedLetters[position] != null) {
      TrieNode? nextNode = node.children[placedLetters[position]!];
      if (nextNode != null) {
        _getWordsWithPrefix(
          nextNode,
          remainingLetters,
          remainingBlanks,
          targetLength,
          prefix + placedLetters[position]!,
          placedLetters,
          possibleLetters,
          results,
          blankPositions
        );
      }
      return;
    }

    // Essayer avec les lettres du rack
    for (String letter in remainingLetters.keys.toList()) {

      if (possibleLetters[position] != null && !possibleLetters[position]!.contains(letter)) {
        continue;
      }
      
      if (node.children.containsKey(letter)) {
        remainingLetters[letter] = remainingLetters[letter]! - 1;
        if (remainingLetters[letter] == 0) {
          remainingLetters.remove(letter);
        }
        _getWordsWithPrefix(
          node.children[letter]!,
          remainingLetters,
          remainingBlanks,
          targetLength,
          prefix + letter,
          placedLetters,
          possibleLetters,
          results,
          blankPositions
        );
        remainingLetters[letter] = (remainingLetters[letter] ?? 0) + 1;
      }
    }

    // Essayer avec un blanc si disponible
    if (remainingBlanks > 0) {
      // Tester toutes les lettres possibles pour le blanc
      for (String letter in node.children.keys) {
        if (possibleLetters[position] != null && !possibleLetters[position]!.contains(letter)) {
          continue;
        }
        
        List<int> newBlankPositions = List.from(blankPositions)..add(position);
        _getWordsWithPrefix(
          node.children[letter]!,
          remainingLetters,
          remainingBlanks - 1,
          targetLength,
          prefix + letter,
          placedLetters,
          possibleLetters,
          results,
          newBlankPositions
        );
      }
    }
  }
}