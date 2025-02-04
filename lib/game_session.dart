import 'package:appli_scrabble/useful_classes.dart';
import 'package:appli_scrabble/wordsuggestions.dart';

import 'board.dart';
import 'rack.dart';

class GameSession {
  DateTime createdAt = DateTime.now();
  BoardState boardState = BoardState();
  RackState playerRack = RackState();
  List<String> computerRack = [];
  int playerScore = 0;
  int computerScore = 0;
  bool isPlayerTurn = true;
  LetterBag bag = LetterBag('scrabble');
  PlayableWord? lastPlayedWord;
  bool isGameOver = false;

  GameSession() {
    _distributeInitialLetters();
  }

  void _distributeInitialLetters() {
    for (int i = 0; i < RackState.maxLetters; i++) {
      playerRack.addLetter(bag.drawLetter());
      computerRack.add(bag.drawLetter());
    }
  }

  void returnLettersToRack() {
    for (var pos in boardState.tempLetters) {
      String letter = boardState.letters[pos.row][pos.col]!;
      playerRack.addLetter(letter);
      boardState.removeLetter(pos);
      boardState.removeBlank(pos);
    }
    boardState.tempLetters = [];
  }

  void playerPlays(PlayableWord word) {
    lastPlayedWord = word;
    boardState.tempLetters = [];
    for (int i = 0; bag.isNotEmpty && i < word.length; i++) {
      playerRack.addLetter(bag.drawLetter());
    }
    playerScore += word.points;
    boardState.updatePossibleLetters();
    isPlayerTurn = false;
  }

  void computerPlays() {
    lastPlayedWord = boardState.findWord(computerRack)[WordSuggestions.number - 1];
    boardState.place(lastPlayedWord!);
    for (var letter in lastPlayedWord!.word.split('')) {
      computerRack.remove(letter);
      if (bag.isNotEmpty) {
        computerRack.add(bag.drawLetter());
      }
    }
    computerScore += lastPlayedWord!.points;
    boardState.updatePossibleLetters();
    isPlayerTurn = true;
  }

  void _endGame() {
    isGameOver = true;
    
    final pointValues = boardState.letterPoints;
    
    for (var letter in playerRack.letters) {
      if (letter != ' ') { // Ignorer les lettres blanches
        playerScore -= pointValues[letter] ?? 0;
        computerScore += pointValues[letter] ?? 0;
      }
    }
    
    for (var letter in computerRack) {
      if (letter != ' ') {
        computerScore -= pointValues[letter] ?? 0;
        playerScore += pointValues[letter] ?? 0;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'playerScore': playerScore,
      'computerScore': computerScore,
      'isPlayerTurn': isPlayerTurn,
      'lastPlayedWord': lastPlayedWord != null ? {
        'word': lastPlayedWord!.word,
        'points': lastPlayedWord!.points
      } : null,
      'boardState': boardState.toJson(),
      'playerRack': playerRack.toJson(),
      'computerRack': computerRack,
      'bag': bag.toJson(),
      'isGameOver': isGameOver,
    };
  }

  GameSession.fromJson(Map<String, dynamic> json)
    : createdAt = DateTime.parse(json['createdAt']),
      playerScore = json['playerScore'],
      computerScore = json['computerScore'],
      isPlayerTurn = json['isPlayerTurn'],
      isGameOver = json['isGameOver'],
      computerRack = List<String>.from(json['computerRack']) {
        boardState = BoardState.fromJson(json['boardState']);
        playerRack = RackState.fromJson(json['playerRack']);
        if (json['lastPlayedWord'] != null) {
          lastPlayedWord = PlayableWord(json['lastPlayedWord']['word'], []);
          lastPlayedWord!.points = json['lastPlayedWord']['points'];
        }
        bag = LetterBag.fromJson(json['bag']);
  }

}

class LetterBag {
  List<String> _letters = [];
  
  LetterBag(String type) {
    _initializeLetters(type);
  }

  void _initializeLetters(String type) {
    final letterDistribution = {
      'a': 9, 'b': 2, 'c': 2, 'd': 3, 'e': 15, 'f': 2, 'g': 2, 'h': 2, 'i': 8,
      'j': 1, 'k': 1, 'l': 5, 'm': 3, 'n': 6, 'o': 6, 'p': 2, 'q': 1, 'r': 6,
      's': 6, 't': 6, 'u': 6, 'v': 2, 'w': 1, 'x': 1, 'y': 1, 'z': 1, ' ': 2
    };
    letterDistribution.forEach((letter, count) {
      _letters.addAll(List.filled(count, letter));
    });
    _letters.shuffle();
  }

  String drawLetter() => _letters.removeLast();
  bool get isNotEmpty => _letters.isNotEmpty;
  int get remainingCount => _letters.length;

  Map<String, dynamic> toJson() {
    return {'letters': _letters};
  }

  LetterBag.fromJson(Map<String, dynamic> json) {
    _letters = List<String>.from(json['letters']);
  }
}