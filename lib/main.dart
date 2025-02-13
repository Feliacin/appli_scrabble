import 'dart:convert';

import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/screen.dart';
import 'package:appli_scrabble/game_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'useful_classes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MainApp.dictionary.load('assets/dictionnaire.txt');
  
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

  @override
  Widget build(BuildContext context) {
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
  BoardState searchBoard = BoardState()..place(PlayableWord('bienvenue', [])..setPosition(7, 3, true));
  List<PlayableWord> _wordSuggestions = [];
  final List<GameSession> _sessions = [];
  int? _currentSessionIndex;

  List<PlayableWord> get wordSuggestions => _wordSuggestions;
  List<GameSession> get sessions => _sessions;
  bool get isSearchMode => _currentSessionIndex == null;
  bool get isGameMode => _currentSessionIndex != null;
  GameSession? get currentSession => 
  _currentSessionIndex != null ? _sessions[_currentSessionIndex!] : null;

  set isSearchMode(bool value) {
    _currentSessionIndex = value ? null : _currentSessionIndex;
    notifyListeners();
  }

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
    } else if (_currentSessionIndex != null && _currentSessionIndex! > index) {
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

  Future<void> saveState() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('searchBoard', jsonEncode(searchBoard.toJson()));
  await prefs.setString('defaultBoardType', BoardState.defaultBoardType);

  List<Map<String, dynamic>> sessionsData =
      _sessions.map((session) {
        return session.toJson();
      }).toList();
  await prefs.setString('app_sessions', jsonEncode(sessionsData));

  if (_currentSessionIndex != null) {
    await prefs.setInt('app_current_session', _currentSessionIndex!);
  } else {
    await prefs.remove('app_current_session');
  }
}

  Future<void> restoreState() async {
    final prefs = await SharedPreferences.getInstance();

    String? searchBoardJson = prefs.getString('searchBoard');
    if (searchBoardJson != null) {
      searchBoard = BoardState.fromJson(jsonDecode(searchBoardJson));
    }
    BoardState.defaultBoardType = prefs.getString('defaultBoardType') ?? 'scrabble';

    String? sessionsJson = prefs.getString('app_sessions');
    if (sessionsJson != null) {
      List<dynamic> sessionsData = jsonDecode(sessionsJson);
      _sessions.clear();
      for (var sessionData in sessionsData) {
        _sessions.add(GameSession.fromJson(sessionData));
      }
    }

    _currentSessionIndex = prefs.getInt('app_current_session');
    notifyListeners();
  }
}