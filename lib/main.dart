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

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.brown[50],
      ),
      home: const Scaffold(
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
      appBar: AppBar(
        backgroundColor: Colors.brown[300],
        title: const Text(
          'Scrabble Assistant',
          style: TextStyle(fontSize: 18),
        ),
        toolbarHeight: 48,
        elevation: 2,
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: Board.boardType,
            builder: (context, currentType, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.settings, size: 20),
                tooltip: 'Changer le type de plateau',
                onSelected: (value) {
                  Board.boardType.value = value;
                  Board.reset();
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'scrabble',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: currentType == 'scrabble' ? Colors.green : Colors.transparent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Scrabble'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'mywordgame',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: currentType == 'mywordgame' ? Colors.green : Colors.transparent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('7 lettres pour 1 mot'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Board(),
                ),
              ),
              ValueListenableBuilder<List<PlayableWord>>(
                valueListenable: wordSuggestions,
                builder: (context, suggestions, _) {
                  return suggestions.isNotEmpty
                    ? Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 160),
                        margin: const EdgeInsets.only(top: 4.0),
                        child: WordSuggestions(),
                      )
                    : const Column(children: [Rack(), Keyboard()]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}