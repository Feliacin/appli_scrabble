import 'package:appli_scrabble/useful_classes.dart';
import 'package:appli_scrabble/wordsuggestions.dart';

import 'board.dart';
import 'rack.dart';

class GameSession {
  final DateTime createdAt = DateTime.now();
  final BoardState boardState = BoardState();
  final RackState playerRack = RackState();
  List<String> computerRack = [];
  int playerScore = 0;
  int computerScore = 0;
  bool isPlayerTurn = true;
  final LetterBag bag = LetterBag('scrabble');
  PlayableWord? lastPlayedWord;

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
    // Remettre les lettres temporaires dans le rack
    for (var pos in boardState.tempLetters) {
      String letter = boardState.letters[pos.row][pos.col]!;
      playerRack.addLetter(letter);
      boardState.removeLetter(pos);
    }
    boardState.tempLetters = [];
  }

  void playerPlays(PlayableWord word) {
    lastPlayedWord = word;
    boardState.tempLetters = [];
    for (int i = 0; i < word.word.length; i++) {
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
      computerRack.add(bag.drawLetter());
    }
    computerScore += lastPlayedWord!.points;
    boardState.updatePossibleLetters();
    isPlayerTurn = true;
  }
}

class LetterBag {
  final List<String> _letters = [];
  
  LetterBag(String type) {
    _initializeLetters(type);
  }

  void _initializeLetters(String type) {
    final letterDistribution = type == 'scrabble' ? {
      'a': 9, 'b': 2, 'c': 2, 'd': 3, 'e': 15, 'f': 2, 'g': 2, 'h': 2, 'i': 8,
      'j': 1, 'k': 1, 'l': 5, 'm': 3, 'n': 6, 'o': 6, 'p': 2, 'q': 1, 'r': 6,
      's': 6, 't': 6, 'u': 6, 'v': 2, 'w': 1, 'x': 1, 'y': 1, 'z': 1, ' ': 2
    } : {
      'a': 9, 'b': 2, /* ... compléter avec toutes les lettres ... */
    };
    letterDistribution.forEach((letter, count) {
      _letters.addAll(List.filled(count, letter));
    });
    _letters.shuffle();
  }

  String drawLetter() => _letters.removeLast();
  bool get isEmpty => _letters.isEmpty;
  int get remainingCount => _letters.length;
}