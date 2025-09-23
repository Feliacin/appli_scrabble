import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/game_dialogs.dart';
import 'package:appli_scrabble/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return Column(
            children: [
              _buildDrawerHeader(context, appState),
              _buildSessionList(context, appState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, AppState appState) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top, // Ajouter la marge de la zone sûre
        left: 16,
        right: 16,
        bottom: 16,
      ),
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
                    // L'appel au dialogue est maintenant dans un autre fichier
                    GameDialogs.showSettingsDialog(context, appState);
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

  Widget _buildSessionList(BuildContext context, AppState appState) {
    return Expanded(
      child: ListView(
        children: [
          // Mode Recherche
          _buildSessionTile(
            context,
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
            final scoreDisplay = session.players.length == 2 ?
              '${session.players[session.localPlayer].score}-${session.players[1 - session.localPlayer].score}'
              : '';
            
            return _buildSessionTile(
              context,
              title: session.isOnline 
                ? 'Partie ${session.id}' 
                : 'Partie #${index + 1}',
              subtitle: 'Dernier mot le ${_formatDate(session.updatedAt)}',
              leading: Text(
                scoreDisplay,
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
            context,
            title: 'Nouvelle partie',
            leading: Icon(
              Icons.add,
              color: Colors.brown[800],
            ),
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              GameDialogs.showNewGameDialog(context, appState);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context, {
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
        ) : onDelete != null ? 
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onLongPress: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.brown[400],
                ),
              ),
            )
                : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}