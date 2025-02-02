import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
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
      //context.read<BoardState>().saveState();
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
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
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
    return Consumer<AppState>(
      builder: (context, appState, _) {
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
                '${session.isPlayerTurn ? 'IA :' : 'Vous :'} ${session.lastPlayedWord!.word.toUpperCase()} (${session.lastPlayedWord!.points} points)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
            const Spacer(),
            
            _buildControlButton(
              icon: Icons.refresh,
              tooltip: 'Récupérer/Mélanger les lettres',
              onPressed: () {
                if (session.boardState.tempLetters.isEmpty) {
                  session.playerRack.shuffle();
                } else {
                  session.returnLettersToRack();
                }
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
            if (!isGameMode) const Keyboard(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.brown[300],
      title: Consumer<AppState>(
        builder: (context, appState, _) {
          final session = appState.currentSession;
          return session != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoreDisplay("Vous", session.playerScore, session.isPlayerTurn),
                  const SizedBox(width: 24),
                  _buildScoreDisplay("IA", session.computerScore, !session.isPlayerTurn),
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
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Trouver les possibilités',
                        onPressed: () {
                          appState.setWordSuggestions(
                            context.read<BoardState>().findWord(rackState.letters)
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
      actions: [
      Consumer2<AppState, BoardState>(
        builder: (context, appState, boardState, child) {
          final session = appState.currentSession;
          // Vérifier si l’on est en mode partie
          if (session == null) return const SizedBox.shrink();

          // Déterminer si le joueur a déposé des lettres
          bool hasPlacedLetters = boardState.tempLetters.isNotEmpty;
          bool isPlayerTurn = session.isPlayerTurn;
          final placedWord = boardState.placedWord;
          return IconButton(
            icon: Icon(
              !isPlayerTurn
                ? Icons.play_arrow  // Tour de l'ordinateur
                : hasPlacedLetters
                  ? (placedWord != null
                      ? Icons.check  // Mot valide
                      : Icons.error) // Mot invalide
                  : Icons.skip_next, // Passer son tour
              color: !isPlayerTurn || (hasPlacedLetters && placedWord == null)
                  ? Colors.grey
                  : Colors.white,
            ),
            tooltip: !isPlayerTurn
                ? 'Faire jouer l\'ordinateur'
                : hasPlacedLetters
                    ? (placedWord != null ? 'Valider le mot' : 'Mot invalide')
                    : 'Passer le tour',
            onPressed: !isPlayerTurn
                ? () {
                    session.computerPlays();
                    setState(() {});
                  }
                : hasPlacedLetters && placedWord != null
                    ? () {
                        session.playerPlays(placedWord);
                        setState(() {});
                      }
                    : null,
          );
        },
      ),
    ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return Column(
            children: [
              _buildDrawerHeader(appState),
              _buildSessionList(appState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(AppState appState) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.brown[300],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(16),
      child: const Align(
        alignment: Alignment.center,
        child: Text(
          'Scrabble Assistant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionList(AppState appState) {
    return Expanded(
      child: ListView(
        children: [
          // Mode Recherche
          _buildSessionTile(
            isSearchMode: true,
            isSelected: appState.currentSession == null,
            onTap: () {
              appState.exitGameMode();
              Navigator.pop(context);
            },
          ),
          
          // Séparateur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Colors.brown[200], height: 1),
          ),
          
          // Liste des parties existantes
          ...appState.sessions.asMap().entries.map((entry) {
            final index = entry.key;
            final session = entry.value;
            final isCurrentSession = appState.currentSession == session;
            
            return _buildSessionTile(
              title: 'Partie #${index + 1}',
              subtitle: 'Créée le ${_formatDate(session.createdAt)}',
              leading: Text(
                '${session.playerScore}-${session.computerScore}',
                style: TextStyle(
                  color: Colors.brown[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              isSelected: isCurrentSession,
              onTap: () {
                appState.switchToSession(index);
                Navigator.pop(context);
              },
              onDelete: () => appState.deleteSession(index),
            );
          }),

          // Nouvelle partie
          _buildSessionTile(
            title: 'Nouvelle partie',
            leading: Icon(
              Icons.add,
              color: Colors.brown[800],
            ),
            isSelected: false,
            onTap: () {
              appState.createNewSession();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    String title = 'Mode Recherche',
    String? subtitle,
    Widget? leading,
    required bool isSelected,
    bool isSearchMode = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.brown[50] : null,
      ),
      child: ListTile(
        dense: true,
        leading: leading ?? Icon(
          Icons.search,
          color: Colors.brown[800],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.brown[800],
            fontWeight: isSearchMode ? FontWeight.w500 : null,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.brown[400],
          ),
        ) : null,
        trailing: onDelete != null ? IconButton(
          icon: Icon(Icons.close, size: 18, color: Colors.brown[400]),
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}