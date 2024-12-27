import 'package:flutter/material.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/wordsuggestions.dart';
import 'useful_classes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour charger les assets
  runApp(MainApp());
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

    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: GameScreen(),
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  static ValueNotifier<List<PlayableWord>> wordSuggestions = ValueNotifier<List<PlayableWord>>([]);
  
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: Board(),
              ),
            ),
          ),
          ValueListenableBuilder<List<PlayableWord>>(
            valueListenable: wordSuggestions,
            builder: (context, suggestions, _) {
              return suggestions.isNotEmpty
                ? Expanded(child: WordSuggestions())
                : const Column(children: [Rack(), Keyboard()]);
            },
          ),
        ],
      ),
    );
  }
}