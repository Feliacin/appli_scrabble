import 'dart:convert';

import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _lettersKey = 'board_letters';
  static const String _blanksKey = 'board_blanks';
  static const String _boardTypeKey = 'board_type';

  int? _selectedIndex;
  List<List<String?>> _letters;
  List<int> _blanks;
  bool _isVertical;
  String _boardType;
  List<int> _tempLetters;
  List<List<String>> _specialPositions;

  BoardState() : 
    _letters = List.generate(boardSize, (_) => List.filled(boardSize, null)),
    _blanks = [],
    _isVertical = false,
    _boardType = 'scrabble',
    _tempLetters = [],
    _specialPositions = _initializeSpecialPositions('scrabble');

  // Getters
  int? get selectedIndex => _selectedIndex;
  List<List<String?>> get letters => _letters;
  List<int> get blanks => _blanks;
  bool get isVertical => _isVertical;
  String get boardType => _boardType;
  List<int> get tempLetters => _tempLetters;
  List<List<String>> get specialPositions => _specialPositions;

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

  Map<String, int> letterPoints() => boardType == 'scrabble' 
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

  // Setters with notifications
  void setSelectedIndex(int? value) {
    _selectedIndex = value;
    notifyListeners();
  }

  void toggleVertical() {
    _isVertical = !_isVertical;
    notifyListeners();
  }

  void toggleBlank(int index) {
    if (_blanks.contains(index)) {
      _blanks.remove(index);
    } else {
      _blanks.add(index);
    }
  }

  void setBoardType(String value) {
    _boardType = value;
    _specialPositions = _initializeSpecialPositions(value);
    notifyListeners();
  }

  void setLetters(List<List<String?>> newLetters) {
    _letters = newLetters;
    notifyListeners();
  }

  void setBlanks(List<int> newBlanks) {
    _blanks = newBlanks;
    notifyListeners();
  }

  void writeLetter(String letter, int i, int j) {
    _letters[i][j] = letter;
    notifyListeners();
  }

  void removeLetter(int i, int j){
    _letters[i][j] = null;
    notifyListeners();
  }

  void addTemporaryLetter(String letter, int row, int col) {
    letters[row][col] = letter;
    tempLetters.add(row * boardSize + col);
    notifyListeners();
  }

  void removeTemporaryLetter(int index) {
    letters[index ~/ boardSize][index % boardSize] = null;
    tempLetters.remove(index);
    notifyListeners();
  }

  void reset() {
    _letters = List.generate(boardSize, (_) => List.filled(boardSize, null));
    _blanks = [];
    _specialPositions = _initializeSpecialPositions(_boardType);
    notifyListeners();
  }

  void place(PlayableWord playableWord) {
    for (int i = 0; i < playableWord.word.length; i++) {
      playableWord.isHorizontal
        ? letters[playableWord.row][playableWord.col + i] = playableWord.word[i]
        : letters[playableWord.row + i][playableWord.col] = playableWord.word[i];
    }
    for (int blankPosition in playableWord.blankPositions) {
      playableWord.isHorizontal
        ? blanks.add(playableWord.row * boardSize + playableWord.col + blankPosition)
        : blanks.add((playableWord.row + blankPosition) * boardSize + playableWord.col);
    }
    notifyListeners();
  }

  // State persistence
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<List<String>> serializedLetters = _letters.map((row) {
      return row.map((letter) => letter ?? '').toList();
    }).toList();
    
    await prefs.setString(_lettersKey, jsonEncode(serializedLetters));
    await prefs.setString(_blanksKey, jsonEncode(_blanks));
    await prefs.setString(_boardTypeKey, _boardType);
  }

  Future<void> restoreState() async {
    final prefs = await SharedPreferences.getInstance();

    final String? lettersJson = prefs.getString(_lettersKey);
    if (lettersJson != null) {
      final List<dynamic> decodedLetters = jsonDecode(lettersJson);
      _letters = decodedLetters.map((row) {
        return (row as List<dynamic>).map((letter) {
          return letter == '' ? null : letter as String;
        }).toList();
      }).toList();
    }

    final String? blanksJson = prefs.getString(_blanksKey);
    if (blanksJson != null) {
      final List<dynamic> decodedBlanks = jsonDecode(blanksJson);
      _blanks = decodedBlanks.map((e) => e as int).toList();
    }

    final String? savedBoardType = prefs.getString(_boardTypeKey);
    if (savedBoardType != null) {
      _boardType = savedBoardType;
      _specialPositions = _initializeSpecialPositions(savedBoardType);
    }

    notifyListeners();
  }

  void findWord(List<String> rack, AppState appState) {
    if (rack.isEmpty) return;
    
    List<List<PossibleLetters>> possibleLetters = PossibleLetters.scan(this);
    List<int> connections;
    var bestWords = BestWords(10);
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
    
    // Mise à jour des suggestions de mots
    appState.setWordSuggestions(bestWords.words);
  }

  void findWordOnLine(
    List<String> rack,
    int index,
    bool isRow,
    List<List<PossibleLetters>> possibleLettersTable,
    List<int> connections,
    BestWords bestWords
  ) {
    int position, points, extra, factor, playedLettersCount;
    bool isBlank;
    List<String?> lettersLine;
    List<String> specialPositionsLine;
    List<PossibleLetters> possibleLettersLine;
    List<int> blanksPlaced;
    List<List<int>> possiblePositions = List.generate(boardSize + 1, (_) => []);

    if (isRow) {
      lettersLine = extractRow(letters, index);
      specialPositionsLine = extractRow(specialPositions, index);
      possibleLettersLine = extractRow(possibleLettersTable, index);
      blanksPlaced = blanks.where((i) => i ~/ boardSize == index).map((i) => i % boardSize).toList();
    } else {
      lettersLine = extractColumn(letters, index);
      specialPositionsLine = extractColumn(specialPositions, index);
      possibleLettersLine = extractColumn(possibleLettersTable, index);
      blanksPlaced = blanks.where((i) => i % boardSize == index).map((i) => i ~/ boardSize).toList();
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
          if (playedLettersCount == RackState.maxLetters) {
            points += boardType == 'scrabble' ? 50 : 49; // Bonus pour avoir utilisé toutes les lettres
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