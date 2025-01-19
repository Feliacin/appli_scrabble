import 'package:flutter/material.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/wordsuggestions.dart';
import 'package:provider/provider.dart';
import 'useful_classes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appState = AppState();
  final boardState = BoardState();
  final rackState = RackState();

  await boardState.restoreState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: boardState),
        ChangeNotifierProvider.value(value: rackState),
      ],
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
          child: GameScreen(),
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  List<PlayableWord> _wordSuggestions = [];
  bool _isGameMode = false;

  List<PlayableWord> get wordSuggestions => _wordSuggestions;
  bool get isGameMode => _isGameMode;

  void setWordSuggestions(List<PlayableWord> suggestions) {
    _wordSuggestions = suggestions;
    notifyListeners();
  }

  void clearWordSuggestions() {
    _wordSuggestions = [];
    notifyListeners();
  }

  void setGameMode(bool value) {
    _isGameMode = value;
    notifyListeners();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<BoardState>().saveState();
    }
  }

  void _handleGameModeChange(bool isGameMode) {
    final appState = context.read<AppState>();
    appState.setGameMode(isGameMode);
    
    // Réinitialiser l'état
    context.read<BoardState>().setSelectedIndex(null);
    context.read<RackState>().isSelected = true;
    
    Navigator.pop(context); // Ferme le Drawer
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    drawer: _buildDrawer(),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxWidth < constraints.maxHeight;
          
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: isPortrait
              ? Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Board(),
                      ),
                    ),
                    Consumer<AppState>(
                      builder: (context, appState, _) {
                        final suggestions = appState.wordSuggestions;
                        final isGameMode = appState.isGameMode;
                        return suggestions.isNotEmpty
                          ? Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 160),
                              margin: const EdgeInsets.only(top: 4.0),
                              child: WordSuggestions(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Rack(),
                                !isGameMode ? const Keyboard() : const SizedBox.shrink(),
                              ],
                            );
                      }
                    )
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Board(),
                        ),
                      ),
                    ),
                    Consumer<AppState>(
                      builder: (context, appState, _) {
                        final suggestions = appState.wordSuggestions;
                        final isGameMode = appState.isGameMode;
                        return Container(
                          width: 360,
                          padding: const EdgeInsets.only(left: 8.0),
                          child: suggestions.isNotEmpty
                            ? WordSuggestions()
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Rack(),
                                  !isGameMode ? const Keyboard() : const SizedBox.shrink(),
                                ],
                              ),
                        );
                      }
                    ),
                  ],
                ),
          );
        },
      ),
    ),
  );
}

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.brown[300],
    title: Consumer<AppState>(
      builder: (context, appState, _) {
        return appState.isGameMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreDisplay("Vous", 42, true),
                const SizedBox(width: 24),
                _buildScoreDisplay("IA", 38, false),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scrabble Assistant',
                  style: TextStyle(fontSize: 18),
                ),
                Consumer<RackState>(
                  builder: (context, rackState, _) {
                    return IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                      tooltip: 'Trouver les possibilités',
                      onPressed: () {
                        context.read<BoardState>().findWord(
                          rackState.letters.whereType<String>().toList(),
                          context.read<AppState>(),
                        );
                      },
                    );
                  },
                ),
              ],
            );
      },
    ),
    toolbarHeight: 48,
    elevation: 2,
    centerTitle: false,
  );
}

Widget _buildScoreDisplay(String player, int score, bool isCurrentTurn) {
  return Row(
    children: [
      Text(
        player,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      if (isCurrentTurn)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      const Text(
        " - ",
        style: TextStyle(color: Colors.white70),
      ),
      Text(
        score.toString(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer2<AppState, BoardState>(
        builder: (context, appState, boardState, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sports_esports),
                title: const Text('Jouer contre l\'ordinateur'),
                selected: appState.isGameMode,
                onTap: () => _handleGameModeChange(true),
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Chercher les meilleurs mots'),
                selected: !appState.isGameMode,
                onTap: () => _handleGameModeChange(false),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Type de plateau',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Scrabble'),
                selected: boardState.boardType == 'scrabble',
                onTap: () {
                  boardState.setBoardType('scrabble');
                  boardState.reset();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('7 lettres pour 1 mot'),
                selected: boardState.boardType == 'mywordgame',
                onTap: () {
                  boardState.setBoardType('mywordgame');
                  boardState.reset();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}