import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/game_session.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/wordsuggestions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_scanner.dart';

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

  void refresh() {
    setState(() {});
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

          if (session == null) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scrabble Assistant',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(),
              ],
            );
          }

          final player = session.players[session.localPlayer];
          final opponent = session.players[1 - session.localPlayer]; // Deux joueurs pour l'instant

          return session.isGameOver
          // Partie terminée
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.score > opponent.score
                    ? "Victoire ! 🎉" 
                    : player.score < opponent.score
                      ? "Défaite 🤖" 
                      : "Match nul 🔄",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${player.score} - ${opponent.score}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Partie en ligne - afficher le code
                  if (session.isOnline) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Code: ${session.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  _buildScoreDisplay(player.name, player.score, session.localPlayer == session.playerTurn),
                  const SizedBox(width: 24),
                  _buildScoreDisplay(opponent.name, opponent.score, session.localPlayer != session.playerTurn),
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

          // Mode recherche
          if (session == null) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                  onPressed: () {
                    BoardScanner().scanBoard(context, boardState);
                  },
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
          }

          // Mode jeu
          if (session.isGameOver) return const SizedBox.shrink();
          bool hasPlacedLetters = boardState.tempLetters.isNotEmpty;
          bool isPlayerTurn = session.playerTurn == session.localPlayer;
          final placedWord = boardState.placedWord;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (!isPlayerTurn || (hasPlacedLetters && placedWord != null))
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
            !isPlayerTurn
                      ? Icons.computer  // Tour de l'ordinateur
                      : hasPlacedLetters
                        ? (placedWord != null
                            ? Icons.check  // Mot valide
                            : Icons.block) // Mot invalide
                        : Icons.swap_horiz, // Passer son tour
                    color: !isPlayerTurn || (hasPlacedLetters && placedWord == null)
                        ? Colors.grey[300]
                        : Colors.white,
                  ),
                  if (hasPlacedLetters && placedWord != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '+${placedWord.points}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: !isPlayerTurn
                  ? 'Faire jouer l\'ordinateur'
                  : hasPlacedLetters
                      ? (placedWord != null ? 'Valider le mot' : 'Placement invalide')
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
                      : () {
                        _showLetterExchangeDialog(context, session);
                      },
            ),
          );
        },
      ),
    ],
    );
  }

  void _showLetterExchangeDialog(BuildContext screenContext, GameSession session) {
    final selectedIndices = <int>{};
    final remainingCount = session.bag.remainingCount;

    showDialog(
      context: screenContext,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tileSize = (constraints.maxWidth - 16 - 7 * 4) / 7;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.brown[400]!, Colors.brown[300]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              session.playerRack.letters.length,
                              (index) {
                                final letter = session.playerRack.letters[index];
                                final isSelected = selectedIndices.contains(index);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedIndices.remove(index);
                                      } else if (selectedIndices.length < remainingCount) {
                                        selectedIndices.add(index);
                                      }
                                    });
                                  },
                                  child: Tile.buildTile(
                                    letter,
                                    tileSize,
                                    screenContext.read<BoardState>().letterPoints,
                                    isHighLighted: isSelected,
                                    withBorder: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '${selectedIndices.length}/$remainingCount',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedIndices.length == remainingCount 
                                ? Colors.orange 
                                : Colors.grey[600],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: selectedIndices.isEmpty ? null : () {
                            final letters = selectedIndices
                              .toList()
                              .map((i) => session.playerRack.letters[i])
                              .toList();
                            session.exchangeLetters(letters);
                            Navigator.of(context).pop();
                            refresh();
                          },
                          child: const Text('Échanger'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.brown[300],
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.extension,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scrabble Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsDialog(context);
                },
                hoverColor: Colors.white.withOpacity(0.1),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.settings,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _showSettingsDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController(
    text: context.read<AppState>().playerName
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Paramètres',
              style: TextStyle(
                color: Colors.brown[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section nom du joueur
                Text(
                  'Nom du joueur',
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Entrez votre nom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.brown[700]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 16),
                
                // Section type de plateau
                Text(
                  'Type de plateau',
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Scrabble classique'),
                  value: 'scrabble',
                  groupValue: BoardState.defaultBoardType,
                  activeColor: Colors.brown[700],
                  contentPadding: EdgeInsets.zero,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        BoardState.defaultBoardType = value;
                      });
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('7 lettres pour 1 mot'),
                  value: 'mywordgame',
                  groupValue: BoardState.defaultBoardType,
                  activeColor: Colors.brown[700],
                  contentPadding: EdgeInsets.zero,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        BoardState.defaultBoardType = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.brown[400]),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<AppState>().playerName = nameController.text.trim();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.brown[700]),
                ),
              ),
            ],
          );
        },
      );
    },
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
              title: session.isOnline 
                ? 'Partie en ligne ${session.id}' 
                : 'Partie #${index + 1}',
              subtitle: 'Dernier mot le ${_formatDate(session.updatedAt)}',
              leading: session.isOnline 
                ? Icon(Icons.wifi, color: Colors.brown[800])
                : Text(
                    '${session.players[session.localPlayer].score}-${session.players[1 - session.localPlayer].score}',
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
              // appState.createNewSession();
              Navigator.pop(context); // fermer le drawer
              _showNewGameDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showNewGameDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(
          'Nouvelle partie',
          style: TextStyle(
            color: Colors.brown[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Partie contre l'ordinateur
            ListTile(
              leading: Icon(
                Icons.computer,
                color: Colors.brown[700],
                size: 32,
              ),
              title: const Text(
                'Contre l\'ordinateur',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Jouez une partie classique contre l\'IA'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                context.read<AppState>().addSession(GameSession(context.read<AppState>().playerName));
              },
            ),
            
            const Divider(),
            
            /// Créer une partie en ligne
            ListTile(
              leading: Icon(
                Icons.wifi,
                color: Colors.brown[700],
                size: 32,
              ),
              title: const Text(
                'Créer une partie en ligne',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Générez un code pour inviter un ami'),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await context.read<AppState>().createOnlineSession();
                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Erreur'),
                      content: Text('Erreur de connexion: $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
              
              const Divider(),
              
              // Rejoindre une partie
              ListTile(
                leading: Icon(
                  Icons.login,
                  color: Colors.brown[700],
                  size: 32,
                ),
                title: const Text(
                  'Rejoindre une partie',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Entrez le code d\'une partie existante'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showJoinGameDialog(context);
                },
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.brown[400]),
            ),
          ),
        ],
      );
    },
  );
}



void _showJoinGameDialog(BuildContext context) {
  final TextEditingController codeController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(
          'Rejoindre une partie',
          style: TextStyle(
            color: Colors.brown[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: Colors.brown[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Entrez le code de la partie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Code de la partie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.brown[700]!),
                ),
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: Colors.brown[600],
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.brown[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                context.read<AppState>().joinSession(code);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tentative de connexion à la partie $code...'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejoindre'),
          ),
        ],
      );
    },
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
        trailing: isSearchMode ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: Colors.brown[400]),
              onPressed: () {
                final appState = context.read<AppState>();
                appState.searchBoard = BoardState();
                appState.isSearchMode = true;
                Navigator.pop(context);
              },
            ),
          ],
        ) : onDelete != null ? IconButton(
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