import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/board_scanner.dart';
import 'package:appli_scrabble/game_dialogs.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameBar extends StatelessWidget implements PreferredSizeWidget {
  const GameBar({super.key});

  @override
  Widget build(BuildContext context) {
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
          final opponent = session.players.length > 1 ? session.players[1 - session.localPlayer] : null; // Deux joueurs pour l'instant

          return session.isGameOver
          // Partie terminée
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.score > opponent!.score
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
                  _buildScoreDisplay(player.name, player.score, session.localPlayer == session.playerTurn),
                  const SizedBox(width: 24),
                  opponent != null ? _buildScoreDisplay(opponent.name, opponent.score, session.localPlayer != session.playerTurn) : const SizedBox(),
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
                      appState.refresh();
                    }
                  : hasPlacedLetters && placedWord != null
                      ? () {
                          session.playerPlays(placedWord);
                          appState.sendMove();
                          appState.refresh();
                        }
                      : () {
                        GameDialogs.showLetterExchangeDialog(context, session, appState);
                      },
            ),
          );
        },
      ),
    ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
}