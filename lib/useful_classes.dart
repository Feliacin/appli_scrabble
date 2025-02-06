// Classes et fonctions utiles pour la recherche du mot

import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:flutter/services.dart';

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);
  Position.fromIndex(int index)
      : row = index ~/ BoardState.boardSize,
        col = index % BoardState.boardSize;

  int get index => row * BoardState.boardSize + col;

  Position next (bool horizontal) {
    if (horizontal && col < BoardState.boardSize - 1) {
      return Position(row, col + 1);
    } else if (!horizontal && row < BoardState.boardSize - 1) {
      return Position(row + 1, col);
    } else {
      return this;
    }
  }

  Position previous (bool horizontal) {
    if (horizontal && col > 0) {
      return Position(row, col - 1);
    } else if (!horizontal && row > 0) {
      return Position(row - 1, col);
    } else {
      return this;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Position && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);
}

class PossibleLetters {
  List<String>? _verticalPossibilities;
  List<String>? _horizontalPossibilities;
  List<int>? _verticalPoints;
  List<int>? _horizontalPoints;
  
  List<String>? get(bool isHorizontal) { // Renvoie les lettres possibles
    return isHorizontal ? _horizontalPossibilities : _verticalPossibilities;
  }

  int getPoints(String letter, bool isHorizontal) { // Renvoie les points d'une lettre possible
    final index = get(isHorizontal)!.indexOf(letter);
    return isHorizontal ? _horizontalPoints![index] : _verticalPoints![index];
  }

  void _open(bool isHorizontal) {
    if (isHorizontal) {
      _horizontalPossibilities = [];
      _horizontalPoints = [];
    } else {
      _verticalPossibilities = [];
      _verticalPoints = [];
    }
  }

  void _add(String character, int points, bool isHorizontal) {
    if (isHorizontal) {
      _horizontalPossibilities!.add(character);
      _horizontalPoints!.add(points);
    } else {
      _verticalPossibilities!.add(character);
      _verticalPoints!.add(points);
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
          possibleLetters[i][j]._open(isHorizontal);
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
              int points = proposal.toString().split('').map((char) => boardState.letterPoints[char]!).reduce((a, b) => a + b);
              for (Position blank in boardState.blanks) {
                if (isHorizontal) {
                  if (blank.row == i && blank.col >= j - lettersBefore && blank.col <= j + lettersAfter) {
                    points -= boardState.letterPoints[proposal.toString()[blank.col - (j - lettersBefore)]]!;
                  }
                } else {
                  if (blank.col == j && blank.row >= i - lettersBefore && blank.row <= i + lettersAfter) {
                    points -= boardState.letterPoints[proposal.toString()[blank.row - (i - lettersBefore)]]!;
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
                  points += boardState.letterPoints[char]! * 2;
                  break;
                case 'DL':
                  points += boardState.letterPoints[char]!;
                  break;
              }
              possibleLetters[i][j]._add(char, points, isHorizontal);
            }
          }
        }
      }
    }
    return possibleLetters;
  }
}

class PlayableWord {
  final String word;
  List<int> blankPositions;
  int row;
  int col;
  bool isHorizontal;
  int points;

  PlayableWord(this.word,  this.blankPositions, {this.row = -1, this.col = -1, this.isHorizontal = true, this.points = 0});

  // Déléguer les méthodes de String
  int get length => word.length;
  String operator [](int index) => word[index];

  void setPosition(int row, int col, bool isHorizontal) {
    this.row = row;
    this.col = col;
    this.isHorizontal = isHorizontal;
  }

  void calculatePoints (BoardState boardState) {
    points = 0;
    bool isBlank;
    int extra = 0, playedLettersCount = 0, factor;
    List<String?> lettersLine;
    List<String> specialPositionsLine;
    List<PossibleLetters> possibleLettersLine;
    List<int> blanksPlaced;

    if (isHorizontal) {
      lettersLine = extractRow(boardState.letters, row, from: col);
      boardState.tempLetters.where((l) => l.row == row && l.col >= col)
                            .forEach((l) => lettersLine[l.col - col] = null);
      specialPositionsLine = extractRow(boardState.specialPositions, row, from: col);
      possibleLettersLine = extractRow(boardState.possibleLetters, row, from: col);
      blanksPlaced = boardState.blanks.where((blank) => blank.row == row && blank.col >= col)
                                      .map((blank) => blank.col - col)
                                      .toList();
    } else {
      lettersLine = extractColumn(boardState.letters, col, from: row);
      boardState.tempLetters.where((l) => l.col == col && l.row >= row)
                            .forEach((l) => lettersLine[l.row - row] = null);
      specialPositionsLine = extractColumn(boardState.specialPositions, col, from: row);
      possibleLettersLine = extractColumn(boardState.possibleLetters, col, from: row);
      blanksPlaced = boardState.blanks.where((blank) => blank.col == col)
                                      .map((blank) => blank.row - row)
                                      .toList();
    }

    for (int k = 0; k < word.length; k++) {
      if(lettersLine[k] != null) {
        if (!blanksPlaced.contains(k)) {
          points += boardState.letterPoints[word[k]]!;
        }
        continue;
      }
      playedLettersCount++;
      isBlank = blankPositions.contains(k);
      if (possibleLettersLine[k].get(!isHorizontal) != null) {
        extra += possibleLettersLine[k].getPoints(word[k], !isHorizontal);
        factor = {'TL': 3, 'DL': 2, 'TW': 3, 'DW': 2}[specialPositionsLine[k]] ?? 1;
        extra -= isBlank ? factor * boardState.letterPoints[word[k]]! : 0;
      }
      factor = {'TL': 3, 'DL': 2}[specialPositionsLine[k]] ?? 1;
      points += !isBlank ? factor * boardState.letterPoints[word[k]]! : 0;
    }
    for (int k=0; k<word.length; k++) {
      if (lettersLine[k] != null) continue;
      if (specialPositionsLine[k] == 'DW') {
        points *= 2;
      } else if (specialPositionsLine[k] == 'TW') {
        points *= 3;
      }
    }
    points += extra;
    if (playedLettersCount == RackState.maxLetters) {
      points += boardState.boardType == 'scrabble' ? 50 : 49; // Bonus pour avoir utilisé toutes les lettres
    }
  }

  bool covers (int index) {
    final position = Position.fromIndex(index);
    if (isHorizontal) {
      return position.row == row && position.col >= col && position.col < col + length;
    } else {
      return position.col == col && position.row >= row && position.row < row + length;
    }
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

List<T> extractRow<T>(List<List<T>> table, int rowIndex, {int from = 0}) {
  if (rowIndex < 0 || rowIndex >= table.length) {
    throw RangeError("Index en dehors des limites");
  }
  return table[rowIndex].skip(from).toList();
}

List<T> extractColumn<T>(List<List<T>> table, int columnIndex, {int from = 0}) {
  if (table.isEmpty || columnIndex < 0 || columnIndex >= table[0].length) {
    throw RangeError("Index en dehors des limites");
  }
  return table.map((row) => row[columnIndex]).skip(from).toList();
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