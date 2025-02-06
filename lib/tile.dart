import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/game_session.dart';
import 'package:appli_scrabble/keyboard.dart';
import 'package:appli_scrabble/main.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appli_scrabble/rack.dart';

class Tile extends StatelessWidget {
  final String property;
  final int index;

  const Tile({super.key, required this.property, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppState, BoardState, RackState>(
      builder: (context, appState, boardState, rackState, _) {
        final pos = Position.fromIndex(index);
        final selectedPosition = Position.fromIndex(boardState.selectedIndex ?? 0);
        final letter = boardState.letters[pos.row][pos.col];
        final isSelected = boardState.selectedIndex == index;
        final isVertical = boardState.isVertical;
        
        final isDirectionIndicator = boardState.selectedIndex != null &&
          ((isVertical && pos.col == selectedPosition.col && pos.row == selectedPosition.row + 1) ||
           (!isVertical && pos.row == selectedPosition.row && pos.col == selectedPosition.col + 1));

        return LayoutBuilder(
          builder: (context, constraints) {
            final tileSize = constraints.maxWidth;

            return GestureDetector(
              onTap: () => appState.isSearchMode ? _handleTap(context, boardState, rackState) : null,
              child: DragTarget<DragData>(
                onWillAccept: (data) => letter == null, 
                onAccept: (data) => _handleDragAccept(context, boardState, rackState, data),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: _buildBackgroundDecoration(
                      isSelected,
                      isDirectionIndicator,
                      isVertical,
                      property,
                      tileSize,
                    ),
                    child: Center(
                      child: letter != null
                        ? _buildLetterWidget(letter, boardState, appState.currentSession, tileSize)
                        : _buildPropertyWidget(property),
                    ),
                  );
                },
              ),
            );
          }
        );
      },
    );
  }

  BoxDecoration _buildBackgroundDecoration(
    bool isSelected,
    bool isDirectionIndicator,
    bool isVertical,
    String property,
    double tileSize,
  ) {
    final baseColor = Board.specialColors[property] ?? Colors.white;

    if (isDirectionIndicator) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [Colors.limeAccent, baseColor],
        ),
        borderRadius: BorderRadius.circular(tileSize * 0.15),
      );
    } else {
      return BoxDecoration(
        color: isSelected ? Colors.limeAccent : baseColor,
        borderRadius: BorderRadius.circular(tileSize * 0.15),
      );
    }
  }

  Widget _buildLetterWidget(String letter, BoardState boardState, GameSession? session, double tileSize) {   
    if (boardState.isTemp(index)) {
      final isBlank = boardState.isBlank(index);

      return Draggable<DragData>(
        data: DragData(
          letter: isBlank ? ' ' : letter,
          boardIndex: index,
        ),
        onDragEnd: (details) => boardState.endDragging(details.wasAccepted, index),
        feedback: Material(
          color: Colors.transparent,
          child: buildTileWithShadow(isBlank ? ' ' : letter, tileSize, boardState.letterPoints)
        ),
        childWhenDragging: _buildPropertyWidget(property),
        child: buildTile(
          letter, tileSize, boardState.letterPoints,
          specialColor: isBlank ? [Colors.pink[50]!, Colors.pink[100]!] : [Colors.amberAccent[100]!, Colors.amberAccent]
        ),
      );
    } else if (boardState.isBlank(index)) {
      return buildTile(
        letter, tileSize, boardState.letterPoints,
        specialColor: [Colors.pink[50]!, Colors.pink[100]!]
      );
    } else if (boardState.tempLetters.isEmpty && (session?.lastPlayedWord?.covers(index) ?? false)) {
      return buildTile(
        letter, tileSize, boardState.letterPoints,
        specialColor: [Colors.amberAccent[100]!, Colors.amberAccent]
      );
      } else {
      return buildTile(
        letter, tileSize, boardState.letterPoints
      );
    }
  }

  Widget _buildPropertyWidget(String property) {
    return Text(
      property,
      style: TextStyle(
        fontSize: 8,
        color: Colors.brown[600],
      ),
    );
  }

  void _handleTap(BuildContext context, BoardState boardState, RackState rackState) {
    if (boardState.selectedIndex == index) {
      boardState.toggleVertical();
    } else {
      boardState.selectedIndex = index;
      rackState.isSelected = false;
    }
  }

  void _handleDragAccept(
    BuildContext context, 
    BoardState boardState, 
    RackState rackState, 
    DragData data
  ) {
    final pos = Position.fromIndex(index);
    
    if (boardState.letters[pos.row][pos.col] == null) {
      
      if (data.letter == ' ') {
        _showBlankLetterSelectionDialog(context, boardState, rackState, pos, data);
      } else {
        boardState.addTemporaryLetter(data.letter, pos);
        if (data.rackIndex != null) {
          rackState.removeLetter(data.rackIndex!);
        }
      }
    }
  }

  Future<void> _showBlankLetterSelectionDialog(
  BuildContext context,
  BoardState boardState,
  RackState rackState,
  Position pos,
  DragData data
) async {  
  final chosenLetter = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        insetPadding: EdgeInsets.all(4),
        contentPadding: EdgeInsets.all(4),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Keyboard(boardState.letterPoints, letterPicker: true),
        ),
      );
    },
  );

  if (chosenLetter != null) {
    boardState.addTemporaryLetter(chosenLetter, pos);
    boardState.toggleBlank(pos);
    if (data.rackIndex != null) {
      rackState.removeLetter(data.rackIndex!);
    }
  }
}
  static Widget buildTileWithShadow(String letter, double size, Map<String, int> letterPoints) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: buildTile(letter, size, letterPoints),
    );
  }

  static Widget buildTile(String letter, double size, Map<String, int> letterPoints, {
      double horizontalMargin = 0,
      bool withBorder = false,
      List<Color>? specialColor}) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        border: withBorder ? Border.all(
          color: Colors.brown[200]!,
          width: 1.5,
        ) : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: specialColor ?? [Colors.amber[50]!, Colors.amber[100]!],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          ),

          if (letter != ' ' && letter != '⌫')
            Positioned(
              bottom: size * 0.05,
              right: size * 0.05,
              child: Text(
                letterPoints[letter].toString(),
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
            ),
        ]
      )
    );
  }
}