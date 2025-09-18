import 'dart:math';

import 'package:appli_scrabble/useful_classes.dart';
import 'package:appli_scrabble/wordsuggestions.dart';

import 'board.dart';
import 'rack.dart';

class GameSession {
  DateTime updatedAt = DateTime.now();
  String? id;
  List<PlayerInfo> players = [];
  int localPlayer = 0;
  int playerTurn = 0;
  BoardState boardState = BoardState();
  RackState playerRack = RackState();
  LetterBag bag = LetterBag('scrabble');
  PlayableWord? lastPlayedWord;
  bool isGameOver = false;

  void _nextTurn() {
    playerTurn = (playerTurn + 1) % players.length;
  }
  bool get isOnline => id != null;

  GameSession(String playerName, [this.id]) {
    addPlayer(playerName);
    if (id == null) {
      addPlayer('IA');
    }
  }

 void addPlayer(String name) {
    final newPlayer = PlayerInfo(name);
    for (int i = 0; i < RackState.maxLetters; i++) {
      newPlayer.rack.add(bag.drawLetter());
    }
    players.add(newPlayer);
  }

  void returnLettersToRack() {
    for (var pos in boardState.tempLetters) {
      String letter = boardState.isBlank(pos.index) ? ' ' : boardState.letters[pos.row][pos.col]!;
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
    boardState.highlightedWord = lastPlayedWord;
    players[localPlayer].score += word.points;
    if (bag.isEmpty && playerRack.letters.isEmpty) {
      _endGame();
    }
    boardState.updatePossibleLetters();
    _nextTurn();
    }

  void computerPlays() {
    returnLettersToRack();
    final computer = players.where((p) => p.name == 'IA').first;
    final possibleWords = boardState.findWord(computer.rack);
    if (possibleWords.isEmpty) {
      _endGame();
    }
    lastPlayedWord = possibleWords[min(possibleWords.length-1, WordSuggestions.number - 1)];
    boardState.place(lastPlayedWord!);
    for (var letter in lastPlayedWord!.word.split('')) {
      computer.rack.remove(letter);
      if (bag.isNotEmpty) {
        computer.rack.add(bag.drawLetter());
      }
    }
    boardState.highlightedWord = lastPlayedWord;
    computer.score += lastPlayedWord!.points;
    if (bag.isEmpty && computer.rack.isEmpty) {
      _endGame();
    }
    boardState.updatePossibleLetters();
    _nextTurn();
  }

  void exchangeLetters(List<String> letters) {
    for (var letter in letters) {
      playerRack.removeLetter(playerRack.letters.indexOf(letter));
      bag._letters.add(letter);
    }

    bag._letters.shuffle();

    for (var i = 0; i < letters.length && bag.isNotEmpty; i++) {
      playerRack.addLetter(bag.drawLetter());
    }

    _nextTurn();
  }

  void _endGame() {
    isGameOver = true;
    final pointValues = boardState.letterPoints;
    final firstFinisher = players.indexWhere((p) => p.rack.isEmpty);

    for (int i = 0; i < players.length; i++) {
      if (i == firstFinisher) continue; // Le premier à avoir fini ne perd pas de points
      for (var letter in players[i].rack) {
        if (letter != ' ') { // Ignorer les lettres blanches
          players[i].score -= pointValues[letter] ?? 0;
          players[firstFinisher].score += pointValues[letter] ?? 0;
        }
      }
    }
  }

  Map<String, dynamic> toJson({required bool localSave}) {
    return {
      'updatedAt': updatedAt.toIso8601String(),
      'game_code': id,
      'isGameOver': isGameOver,
      'bag': bag.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'playerTurn': playerTurn,
      'boardState': boardState.toJson(),

      'lastPlayedWord': lastPlayedWord != null ? {
        'word': lastPlayedWord!.word,
        'points': lastPlayedWord!.points
      } : null,
      'playerRack': localSave ? playerRack.toJson() : null,
      'localPlayer': localSave ? localPlayer : null,
    };
  }

  GameSession.fromJson(Map<String, dynamic> json) {
      updatedAt = DateTime.parse(json['updatedAt']);
      id = json['game_code'];
      isGameOver = json['isGameOver'];
      bag = LetterBag.fromJson(json['bag']);
      for (var playerInfo in json['players']) {
        players.add(PlayerInfo.fromJson(playerInfo));
      }
      playerTurn = json['playerTurn'];
      localPlayer = json['localPlayer'];
      boardState = BoardState.fromJson(json['boardState']);
      if (json['playerRack'] != null) {
        playerRack = RackState.fromJson(json['playerRack']);
      }
      if (json['lastPlayedWord'] != null) {
        lastPlayedWord = PlayableWord(json['lastPlayedWord']['word'], []);
        lastPlayedWord!.points = json['lastPlayedWord']['points'];
      }
  }
}

class LetterBag {
  List<String> _letters = [];
  
  LetterBag(String type) {
    _initializeLetters(type);
  }

  void _initializeLetters(String type) {
    // final letterDistribution = {
    //   'a': 9, 'b': 2, 'c': 2, 'd': 3, 'e': 15, 'f': 2, 'g': 2, 'h': 2, 'i': 8,
    //   'j': 1, 'k': 1, 'l': 5, 'm': 3, 'n': 6, 'o': 6, 'p': 2, 'q': 1, 'r': 6,
    //   's': 6, 't': 6, 'u': 6, 'v': 2, 'w': 1, 'x': 1, 'y': 1, 'z': 1, ' ': 2
    // };
    final letterDistribution = {
  'a': 4, 'b': 1, 'c': 2, 'd': 2, 'e': 6, 'f': 1, 'g': 1, 'h': 1, 'i': 4,
  'l': 2, 'm': 2, 'n': 3, 'o': 3, 'p': 1, 'r': 3, 's': 3, 't': 3, 'u': 3, 'v': 1, ' ': 2
};

    letterDistribution.forEach((letter, count) {
      _letters.addAll(List.filled(count, letter));
    });
    _letters.shuffle();
  }

  String drawLetter() => _letters.removeLast();
  bool get isEmpty => _letters.isEmpty;
  bool get isNotEmpty => _letters.isNotEmpty;
  int get remainingCount => _letters.length;

  Map<String, dynamic> toJson() {
    return {'letters': _letters};
  }

  LetterBag.fromJson(Map<String, dynamic> json) {
    _letters = List<String>.from(json['letters']);
  }
}

class PlayerInfo {
  String name;
  int score = 0;
  List<String> rack = [];
  int? leftGroupLength;

  PlayerInfo(this.name);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'rack': rack,
    };
  }

  PlayerInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        score = json['score'],
        rack = List<String>.from(json['rack']);
}