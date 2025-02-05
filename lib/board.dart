import 'dart:math';

import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:appli_scrabble/wordsuggestions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appli_scrabble/tile.dart';

class Board extends StatelessWidget {
  const Board({super.key});

  static Map<String, Color> specialColors = {
    'TW': Colors.red[400]!,
    'DW': Colors.pink[200]!,
    'TL': Colors.blue[300]!,
    'DL': Colors.lightBlue[200]!,
    '': Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Consumer<BoardState>(
        builder: (context, boardState, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final spacing = constraints.maxWidth / 200;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  border: Border.all(color: Colors.brown[300]!, width: spacing),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: BoardState.boardSize,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: BoardState.boardSize * BoardState.boardSize,
                  itemBuilder: (context, index) {
                    return Tile(
                      property: boardState.specialPositions[index ~/ BoardState.boardSize][index % BoardState.boardSize],
                      index: index,
                    );
                  },
                ),
              );
            }
          );
        },
      ),
    );
  }
}

class BoardState extends ChangeNotifier {
  static const int boardSize = 15;

  int? _selectedIndex;
  List<List<String?>> _letters;
  List<Position> _blanks;
  bool _isVertical;
  String _boardType;
  static String defaultBoardType = 'scrabble';
  List<Position> _tempLetters;
  List<List<String>> _specialPositions;
  List<List<PossibleLetters>> possibleLetters;

  BoardState(): 
    _letters = List.generate(boardSize, (_) => List.filled(boardSize, null)),
    _blanks = [],
    _tempLetters = [],
    _isVertical = false,
    _boardType = defaultBoardType,
    _specialPositions = _initializeSpecialPositions(defaultBoardType),
    possibleLetters = List.generate(boardSize, (_) => List.generate(boardSize, (_) => PossibleLetters()));

  // Getters
  int? get selectedIndex => _selectedIndex;
  List<List<String?>> get letters => _letters;
  bool get isVertical => _isVertical;
  String get boardType => _boardType;
  List<List<String>> get specialPositions => _specialPositions;
  List<Position> get blanks => _blanks;
  List<Position> get tempLetters => _tempLetters;
  Position get center => Position(boardSize ~/ 2, boardSize ~/ 2);
  bool get isFirstTurn => _letters[center.row][center.col] == null || isTemp(center.index);

  // Setters
  set letters(List<List<String?>> newLetters) {
    _letters = newLetters;
    notifyListeners();
  }
  set blanks(List<Position> newBlanks) {
    _blanks = newBlanks;
    notifyListeners();
  }
  set selectedIndex(int? value) {
    _selectedIndex = value;
    notifyListeners();
  }
  set tempLetters(List<Position> newTempLetters) {
    _tempLetters = newTempLetters;
    notifyListeners();
  }
  //

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

  Map<String, int> get letterPoints => boardType == 'scrabble' 
  ?  {
    'a': 1, 'b': 3, 'c': 3, 'd': 2, 'e': 1, 'f': 4, 'g': 2, 'h': 4, 'i': 1,
    'j': 8, 'k': 10, 'l': 1, 'm': 2, 'n': 1, 'o': 1, 'p': 3, 'q': 8, 'r': 1,
    's': 1, 't': 1, 'u': 1, 'v': 4, 'w': 10, 'x': 10, 'y': 10, 'z': 10
    }
    : {
    'a': 1, 'b': 5, 'c': 3, 'd': 4, 'e': 1, 'f': 5, 'g': 4, 'h': 5, 'i': 1,
    'j': 7, 'k': 10, 'l': 2, 'm': 3, 'n': 1, 'o': 1, 'p': 4, 'q': 7, 'r': 1,
    's': 1, 't': 1, 'u': 2, 'v': 5, 'w': 10, 'x': 8, 'y': 8, 'z': 8
    };

  void endDragging (bool wasAccepted, int index) {
    if (wasAccepted) {
      removeTemporaryLetter(Position.fromIndex(index));
      removeBlank(Position.fromIndex(index));
    }
  }

  void toggleVertical() {
    _isVertical = !_isVertical;
    notifyListeners();
  }

  void toggleBlank(Position position) {
    if (_blanks.contains(position)) {
      _blanks.remove(position);
    } else {
      _blanks.add(position);
    }
    notifyListeners();
  }

  void removeBlank(Position position) {
    _blanks.remove(position);
    notifyListeners();
  }

  bool isBlank(index) => _blanks.contains(Position.fromIndex(index));

  void writeLetter(String letter, Position pos) {
    _letters[pos.row][pos.col] = letter;
    notifyListeners();
  }

  void removeLetter(Position pos){
    _letters[pos.row][pos.col] = null;
    notifyListeners();
  }

  void addTemporaryLetter(String letter, Position pos) {
    letters[pos.row][pos.col] = letter;
    _tempLetters.add(pos);
    notifyListeners();
  }

  void removeTemporaryLetter(Position pos) {
    letters[pos.row][pos.col] = null;
    _tempLetters.remove(pos);
    notifyListeners();
  }

  bool isTemp(int index) => _tempLetters.contains(Position.fromIndex(index));

  void updatePossibleLetters() => possibleLetters = PossibleLetters.scan(this);

  void place(PlayableWord playableWord) {
    for (int i = 0; i < playableWord.length; i++) {
      playableWord.isHorizontal
        ? letters[playableWord.row][playableWord.col + i] = playableWord.word[i]
        : letters[playableWord.row + i][playableWord.col] = playableWord.word[i];
    }
    for (int blankPosition in playableWord.blankPositions) {
      playableWord.isHorizontal
        ? blanks.add(Position(playableWord.row, playableWord.col + blankPosition))
        : blanks.add(Position(playableWord.row + blankPosition, playableWord.col));
    }
    notifyListeners();
  }

  List<PlayableWord> findWord(List<String> rack) {
    if (rack.isEmpty) return [];
    
    possibleLetters = PossibleLetters.scan(this);
    List<int> connections;
    var bestWords = BestWords(WordSuggestions.number);
    int middle = boardSize ~/ 2;
    
    if (letters[middle][middle] == null) { // Premier mot
      connections = [middle];
      findWordOnLine(rack, middle, true, possibleLetters, connections, bestWords);
    } else {
      for (bool isRow in [true, false]) {
        for (int i = 0; i < boardSize; i++) {
          connections = [];
          for (int j = 0; j < boardSize; j++) {
            int row = isRow ? i : j;
            int col = isRow ? j : i;

            if (possibleLetters[row][col].get(true) != null || 
                possibleLetters[row][col].get(false) != null) {
              connections.add(j);
            }
          }
          if (connections.isNotEmpty) {
            findWordOnLine(rack, i, isRow, possibleLetters, connections, bestWords);
          }
        }
      }
    }
    
    return bestWords.words;
  }

  void findWordOnLine(
    List<String> rack,
    int index,
    bool isRow,
    List<List<PossibleLetters>> possibleLettersTable,
    List<int> connections,
    BestWords bestWords
  ) {
    int position;
    List<String?> lettersLine;
    List<PossibleLetters> possibleLettersLine;
    List<List<int>> possiblePositions = List.generate(boardSize + 1, (_) => []);

    if (isRow) {
      lettersLine = extractRow(letters, index);
      possibleLettersLine = extractRow(possibleLettersTable, index);
    } else {
      lettersLine = extractColumn(letters, index);
      possibleLettersLine = extractColumn(possibleLettersTable, index);
    }

    // Pré-calcul des positions possibles
    for (int wordLength = 2; wordLength <= boardSize; wordLength++) {
      position = 0; // Emplacement du début du mot
      for (int k = 0; k < connections.length; k++) {
        // Le but est que le mot dispose d'un caractère sur connections[k]
        while (position + wordLength - 1 < connections[k]) {
          position++;
        }
        for (; position + wordLength - 1 < boardSize && position <= connections[k]; position++) {
          // On ne peut pas choisir un emplacement précédé ou suivi par une lettre
          if ((position == 0 || lettersLine[position-1] == null) && 
            (position + wordLength == boardSize || lettersLine[position + wordLength] == null)) {
            possiblePositions[wordLength].add(position);
          }
        }
      }
    }
    for (int wordLength=2; wordLength <= boardSize; wordLength++) {
      for (var position in possiblePositions[wordLength]) {
        for (PlayableWord playableWord in MainApp.dictionary.getPossibleWords(
            rack,
            wordLength,
            lettersLine.sublist(position, position + wordLength),
            possibleLettersLine.sublist(position, position + wordLength).map((possibleLetters) => possibleLetters.get(!isRow)).toList())
            ) {
            
          isRow
              ? playableWord.setPosition(index, position, true)
              : playableWord.setPosition(position, index, false);
          playableWord.calculatePoints(this);

          // Comparaison avec les meilleurs mots
          if (bestWords.accepts(playableWord.points)) {
            bestWords.add(playableWord);
          }
        }
      }
    }
  }

  // Lecture des mots posés sur le plateau
  PlayableWord? get placedWord {
    if (_tempLetters.isEmpty) return null;

    // Déterminer l'orientation
    int i = _tempLetters[0].row;
    int j = _tempLetters[0].col;
    bool isHorizontal;

    if (_tempLetters.length == 1) {
      // Pour une seule lettre, vérifier les deux directions possibles
      String letter = letters[i][j]!;
      bool horizontalPossible = possibleLetters[i][j].get(true)?.contains(letter) ?? false;
      bool verticalPossible = possibleLetters[i][j].get(false)?.contains(letter) ?? false;

      if (horizontalPossible && !verticalPossible) {
        isHorizontal = true;
      } else if (!horizontalPossible && verticalPossible) {
        isHorizontal = false;
      } else if (horizontalPossible && verticalPossible) {
        // Si les deux directions sont possibles, choisir celle qui forme le mot le plus long
        String horizontalWord = _getWordAt(_findStartPosition(i, j, true), true);
        String verticalWord = _getWordAt(_findStartPosition(i, j, false), false);
        isHorizontal = horizontalWord.length >= verticalWord.length;
      } else {
        return null;
      }
    } else {
      isHorizontal = _tempLetters[0].row == _tempLetters[1].row;
    }

    if (!_checkAlignment(isHorizontal)) {
      return null;
    }

    Position startPos = _findStartPosition(i, j, isHorizontal);

    // Créer et configurer le mot jouable
    PlayableWord placedWord = PlayableWord(_getWordAt(startPos, isHorizontal), []);
    placedWord.setPosition(startPos.row, startPos.col, isHorizontal);

    if (_isValidWord(placedWord)) {
      placedWord.calculatePoints(this);
      return placedWord;
    }

    return null;
  }

  bool _checkAlignment(bool isHorizontal) {
    int reference = isHorizontal ? _tempLetters[0].row : _tempLetters[0].col;
    
    // Vérifier que toutes les lettres sont sur la même ligne/colonne
    if (!_tempLetters.every((pos) => 
        (isHorizontal ? pos.row : pos.col) == reference)) {
      return false;
    }

    // Vérifier la continuité des lettres
    List<int> positions = _tempLetters
        .map((pos) => isHorizontal ? pos.col : pos.row)
        .toList();
    int minPos = positions.fold(boardSize, min);
    int maxPos = positions.fold(0, max);

    for (int k = minPos; k <= maxPos; k++) {
      if (letters[isHorizontal ? reference : k][isHorizontal ? k : reference] == null) {
        return false;
      }
    }
    return true;
  }

  Position _findStartPosition(int i, int j, bool isHorizontal) {
    int pos = isHorizontal ? j : i;
    for (pos; pos>0 && letters[isHorizontal ? i : pos-1][isHorizontal ? pos-1 : j] != null; pos--) {}
    return isHorizontal ? Position(i, pos) : Position(pos, j);
  }

  String _getWordAt(Position startPos, bool horizontal) {
    List<String> word = [];
    int pos = horizontal ? startPos.col : startPos.row;
    
    while (pos < boardSize && letters[horizontal ? startPos.row : pos][horizontal ? pos : startPos.col] != null) {
      word.add(letters[horizontal ? startPos.row : pos][horizontal ? pos : startPos.col]!);
      pos++;
    }
    
    return word.join();
  }

  bool _isValidWord(PlayableWord placedWord) {
    // Vérifier la connexion avec les lettres existantes ou la case centrale
    bool hasConnection = false;
    if (isFirstTurn) {
      if (_tempLetters.length < 2 || !isTemp(center.index)) {
        return false;
      } else {
        hasConnection = true;
      }
    }

    if (!MainApp.dictionary.exists(placedWord.word)) {
      return false;
    }

    // Vérifier les contraintes pour chaque lettre placée
    for (Position pos in _tempLetters) {
      var possibilities = possibleLetters[pos.row][pos.col].get(!placedWord.isHorizontal);
      if (possibilities != null) {
        if (possibilities.contains(letters[pos.row][pos.col])) {
          hasConnection = true;
        } else {
          return false;
        }
      }
      if (!hasConnection && possibleLetters[pos.row][pos.col].get(placedWord.isHorizontal) != null) {
        hasConnection = true;
      }
    }
    return hasConnection;
  }

  // Sauvegarde et restauration de l'état
  Map<String, dynamic> toJson() {
    return {
      'letters': _letters.map((row) => row.map((letter) => letter ?? '').toList()).toList(),
      'blanks': _blanks.map((pos) => {'row': pos.row, 'col': pos.col}).toList(),
      'tempLetters': _tempLetters.map((pos) => {'row': pos.row, 'col': pos.col}).toList(),
      'boardType': _boardType,
    };
  }

  BoardState.fromJson(Map<String, dynamic> json)
    : _letters = (json['letters'] as List).map((row) =>
        (row as List).map((letter) => letter == '' ? null : letter as String).toList()).toList(),
      _blanks = (json['blanks'] as List).map((e) => Position(e['row'], e['col'])).toList(),
      _tempLetters = (json['tempLetters'] as List).map((e) => Position(e['row'], e['col'])).toList(),
      _isVertical = false,
      _boardType = json['boardType'],
      _specialPositions = _initializeSpecialPositions(json['boardType']),
      possibleLetters = [] {
      possibleLetters = PossibleLetters.scan(this);
  }

}