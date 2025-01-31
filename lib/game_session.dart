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

  GameSession() {
    _distributeInitialLetters();
  }

   void _distributeInitialLetters() {
    for (int i = 0; i < RackState.maxLetters; i++) {
      playerRack.addLetter(bag.drawLetter());
      computerRack.add(bag.drawLetter());
    }
  }

}

class LetterBag {
  final List<String> _letters = [];
  
  LetterBag(String type) {
    _initializeLetters(type);
  }

  void _initializeLetters(String type) {
    final letterDistribution = type == 'scrabble' ? {
      'A': 9, 'B': 2, 'C': 2, 'D': 3, 'E': 15, 'F': 2, 'G': 2, 'H': 2, 'I': 8,
      'J': 1, 'K': 1, 'L': 5, 'M': 3, 'N': 6, 'O': 6, 'P': 2, 'Q': 1, 'R': 6,
      'S': 6, 'T': 6, 'U': 6, 'V': 2, 'W': 1, 'X': 1, 'Y': 1, 'Z': 1, ' ': 2
    } : {
      'A': 9, 'B': 2, /* ... compléter avec toutes les lettres ... */
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