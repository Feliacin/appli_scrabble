import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/game_session.dart';

class GameDialogs {
  static void showSettingsDialog(BuildContext context, AppState appState) {
    final TextEditingController nameController = TextEditingController(
      text: appState.playerName
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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

static void showNewGameDialog(BuildContext screenContext, AppState appState) {
  final TextEditingController codeController = TextEditingController();
  final letterPoints = screenContext.read<BoardState>().letterPoints;

  showDialog(
    context: screenContext,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.zero,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // L'en-tête de votre dialogue
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Text(
                      'Nouvelle partie',
                      style: TextStyle(
                        color: Colors.brown[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Option "Contre l'ordinateur"
                  _buildGameOption(
                    icon: Icons.computer,
                    title: 'Contre l\'ordinateur',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      appState.addSession(GameSession(appState.playerName));
                    },
                  ),

                  const SizedBox(height: 16),

                  // Option "Créer une partie en ligne"
                  _buildGameOption(
                    icon: Icons.wifi,
                    title: 'Créer une partie en ligne',
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      try {
                        await appState.createOnlineSession();
                      } catch (e) {
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section "Rejoindre une partie"
                  Text(
                    'ou rejoignez une partie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.brown[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ de texte pour le code
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.brown[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown[300]!),
                    ),
                    child: Center(
                      child: Text(
                        codeController.text.toUpperCase().padRight(6, '_'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bouton "Rejoindre"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ElevatedButton(
                      onPressed: codeController.text.length == 6
                          ? () {
                              final code = codeController.text.trim();
                              Navigator.of(dialogContext).pop();
                              appState.joinSession(code);
                              ScaffoldMessenger.of(screenContext).showSnackBar(
                                SnackBar(
                                  content: Text('Tentative de connexion à la partie $code...'),
                                  backgroundColor: Colors.brown,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.brown[200],
                        disabledForegroundColor: Colors.brown[400],
                      ),
                      child: const Text(
                        'Rejoindre',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Keyboard(
                    letterPoints,
                    onLetterPressed: (String letter) {
                      setState(() {
                        if (letter.toLowerCase() == '⌫') {
                          if (codeController.text.isNotEmpty) {
                            codeController.text = codeController.text.substring(0, codeController.text.length - 1);
                          }
                        } else if (codeController.text.length < 6) {
                          codeController.text += letter.toUpperCase();
                        }
                      });
                    },
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
  static Widget _buildGameOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Le code de cette fonction reste inchangé
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.brown[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showLetterExchangeDialog(BuildContext screenContext, GameSession session, AppState appState) {
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
                            appState.refresh();
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
}