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

        return GestureDetector(
          onTap: () => _handleTap(context, boardState, rackState),
          child: DragTarget<DragData>(
            onAccept: (data) => _handleDragAccept(context, boardState, rackState, data),
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration: _buildDecoration(
                  letter: letter,
                  isSelected: isSelected,
                  isDirectionIndicator: isDirectionIndicator,
                  isVertical: isVertical,
                  isTemp: boardState.tempLetters.contains(index),
                  isBlank: boardState.blanks.contains(index),
                ),
                child: Center(
                  child: letter != null
                    ? _buildLetterWidget(letter, boardState)
                    : _buildPropertyWidget(property),
                ),
              );
            },
          ),
        );
      },
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

  BoxDecoration _buildDecoration({
    required String? letter,
    required bool isSelected,
    required bool isDirectionIndicator,
    required bool isVertical,
    required bool isTemp,
    required bool isBlank,
  }) {
    final baseColor = letter != null
      ? (isBlank ? Colors.pink[50]! : Colors.amber[100]!)
      : (Board.specialColors[property] ?? Colors.white);

    if (isSelected) {
      return BoxDecoration(
        color: Colors.limeAccent,
        borderRadius: BorderRadius.circular(3),
      );
    } else if (isDirectionIndicator) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [Colors.limeAccent, baseColor],
        ),
        borderRadius: BorderRadius.circular(3),
      );
    } else if (isTemp) {
        return BoxDecoration(
          color: Colors.amberAccent,
          borderRadius: BorderRadius.circular(3),
        );
    } else {
      return BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(3),
      );
    }
  }


  Widget _buildLetterWidget(String letter, BoardState boardState) {
    final isTemp = boardState.tempLetters.contains(index);
    
    if (isTemp) {
      return Draggable<DragData>(
        data: DragData(
          letter: letter,
          boardIndex: index,
        ),
        feedback: buildTile(letter, 30),
        childWhenDragging: _buildPropertyWidget(property),
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    } else {
      return Text(
        letter.toUpperCase(),
        style: const TextStyle(
          color: Colors.brown,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
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

  static Widget buildTile(String? letter, double size) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: size * 0.025),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        border: letter != null ? Border.all(
          color: Colors.brown[200]!,
          width: 1.5,
        ) : null,
        gradient: letter != null ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Colors.amber[100]!,
          ],
        ) : null,
      ),
      child: letter != null
        ? Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          )
        : null,
    );
  }
}