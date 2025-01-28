import 'package:appli_scrabble/board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appli_scrabble/rack.dart';

class Tile extends StatelessWidget {
  final String property;
  final int index;

  const Tile({super.key, required this.property, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BoardState, RackState>(
      builder: (context, boardState, rackState, _) {
        final row = index ~/ BoardState.boardSize;
        final col = index % BoardState.boardSize;
        final letter = boardState.letters[row][col];
        final isSelected = boardState.selectedIndex == index;
        final isVertical = boardState.isVertical;
        
        final isDirectionIndicator = boardState.selectedIndex != null &&
          ((isVertical && 
            col == boardState.selectedIndex! % BoardState.boardSize && 
            row == (boardState.selectedIndex! ~/ BoardState.boardSize) + 1) ||
           (!isVertical && 
            row == boardState.selectedIndex! ~/ BoardState.boardSize && 
            col == (boardState.selectedIndex! % BoardState.boardSize) + 1));

        return LayoutBuilder(
          builder: (context, constraints) {
            final tileSize = constraints.maxWidth;

            return GestureDetector(
              onTap: () => _handleTap(context, boardState, rackState),
              child: DragTarget<DragData>(
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
                        ? _buildLetterWidget(letter, boardState, tileSize)
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

  Widget _buildLetterWidget(String letter, BoardState boardState, double tileSize) {
    final isTemp = boardState.tempLetters.contains(index);
    final isBlank = boardState.blanks.contains(index);
    
    if (isTemp) {
      return Draggable<DragData>(
        data: DragData(
          letter: letter,
          boardIndex: index,
        ),
        feedback: Material(
          color: Colors.transparent,
          child: buildTileWithShadow(letter, tileSize)
        ),
        childWhenDragging: _buildPropertyWidget(property),
        child: buildTile(
          letter, 
          tileSize,
          specialColor: [Colors.amberAccent[100]!, Colors.amberAccent]
        ),
      );
    } else if (isBlank) {
    return buildTile(
        letter,
        tileSize,
        specialColor: [Colors.pink[50]!, Colors.pink[100]!]
      );
    } else{
      return buildTile(
        letter,
        tileSize,
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
      boardState.setSelectedIndex(index);
      rackState.isSelected = false;
    }
  }

  void _handleDragAccept(
    BuildContext context, 
    BoardState boardState, 
    RackState rackState, 
    DragData data
  ) {
    final row = index ~/ BoardState.boardSize;
    final col = index % BoardState.boardSize;
    
    if (boardState.letters[row][col] == null) {
      boardState.addTemporaryLetter(data.letter, row, col);
      
      // Retirer la lettre du rack ou de son ancienne position
      if (data.rackIndex != null) {
        rackState.removeLetter(data.rackIndex!);
      } else if (data.boardIndex != null) {
        boardState.removeTemporaryLetter(data.boardIndex!);
      }
    }
  }

  static Widget buildTileWithShadow(String letter, double size) {
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
      child: buildTile(letter, size),
    );
  }

  static Widget buildTile(String letter, double size, {
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
      child: Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          )
    );
  }
}