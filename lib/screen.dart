import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/game_bar.dart';
import 'package:appli_scrabble/main_drawer.dart';
import 'package:appli_scrabble/wordsuggestions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Screen extends StatefulWidget {
  const Screen({super.key});

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> with WidgetsBindingObserver {
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
      // Sauvegarde de l'état de l'application
      context.read<AppState>().saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentSession = appState.currentSession;
    final boardState = currentSession?.boardState ?? appState.searchBoard;
    final rackState = currentSession?.playerRack ?? RackState();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: boardState),
        ChangeNotifierProvider.value(value: rackState),
      ],
      child: Scaffold(
        appBar: const GameBar(),
        drawer: const MainDrawer(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isPortrait = constraints.maxWidth < constraints.maxHeight;
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: isPortrait ? _buildPortraitLayout() : _buildLandscapeLayout(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Consumer2<AppState, BoardState>(
      builder: (context, appState, boardState, _) {
        final session = appState.currentSession;
        if (session == null) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            
            _buildControlButton(
              icon: Icons.lightbulb_outline,
              tooltip: 'Obtenir un conseil',
              onPressed: () {
                var suggestions = session.boardState
                    .findWord(session.playerRack.letters);
                if (suggestions.isNotEmpty) {
                  final suggestion = suggestions[0];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meilleur mot : ${suggestion.points} points',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            
            // Dernier mot joué
            if (session.lastPlayedWord != null)
              Text(
                '${session.players[session.playerTurn].name} ${session.lastPlayedWord!.word.toUpperCase()} (${session.lastPlayedWord!.points} points)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
            const Spacer(),

            boardState.tempLetters.isEmpty ?
              _buildControlButton(
                icon: Icons.refresh,
                tooltip: 'Mélanger les lettres',
                onPressed: () {
                    session.playerRack.shuffle();
                },
              ) :
              _buildControlButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: 'Récupérer les lettres',
                onPressed: () {
                    session.returnLettersToRack();
                },
              ),
            const SizedBox(width: 16),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.brown[700]),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGameArea() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final suggestions = appState.wordSuggestions;
        final isGameMode = appState.currentSession != null;
        
        if (suggestions.isNotEmpty) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 160),
            margin: const EdgeInsets.only(top: 4.0),
            child: WordSuggestions(),
          );
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Rack(),
            if (!isGameMode) Keyboard(context.read<BoardState>().letterPoints),
          ],
        );
      },
    );
  }  

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Board(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _buildGameControls(),
        ),
        _buildGameArea(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
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
        Container(
          width: 360,
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameControls(),
              const SizedBox(height: 16),
              _buildGameArea(),
            ],
          ),
        ),
      ],
    );
  }
}