import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/screen.dart';
import 'package:appli_scrabble/game_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'useful_classes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appState = AppState();
  await appState.restoreState();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  static final Dictionary dictionary = Dictionary();

  const MainApp({super.key});

  _loadDictionary() async {
    await dictionary.load('assets/dictionnaire.txt');
  }

  @override
  Widget build(BuildContext context) {
    _loadDictionary();

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.brown[50],
      ),
      home: const Scaffold(
        body: Center(
          child: Screen(),
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  BoardState searchBoard = BoardState();
  List<PlayableWord> _wordSuggestions = [];
  final List<GameSession> _sessions = [];
  int? _currentSessionIndex;

  List<PlayableWord> get wordSuggestions => _wordSuggestions;
  List<GameSession> get sessions => _sessions;
  bool get isGameMode => _currentSessionIndex != null;
  GameSession? get currentSession => 
    _currentSessionIndex != null ? _sessions[_currentSessionIndex!] : null;

  void createNewSession() {
    final session = GameSession();
    _sessions.add(session);
    _currentSessionIndex = _sessions.length - 1;
    notifyListeners();
  }

  void deleteSession(int index) {
    _sessions.removeAt(index);
    if (_currentSessionIndex == index) {
      _currentSessionIndex = _sessions.isEmpty ? null : 0;
    } else if (_currentSessionIndex! > index) {
      _currentSessionIndex = _currentSessionIndex! - 1;
    }
    notifyListeners();
  }

  void switchToSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _currentSessionIndex = index;
      notifyListeners();
    }
  }

  void exitGameMode() {
    _currentSessionIndex = null;
    notifyListeners();
  }

  void setWordSuggestions(List<PlayableWord> suggestions) {
    _wordSuggestions = suggestions;
    notifyListeners();
  }

  void clearWordSuggestions() {
    _wordSuggestions = [];
    notifyListeners();
  }

  Future<void> restoreState() async {
    // to do
  }
}