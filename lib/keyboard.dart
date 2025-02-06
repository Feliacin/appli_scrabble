import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/rack.dart';
import 'package:appli_scrabble/tile.dart';
import 'package:appli_scrabble/useful_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Keyboard extends StatelessWidget {
  final bool letterPicker;
  final Map<String, int> letterPoints;
  const Keyboard(this.letterPoints, {super.key, this.letterPicker = false});

  void _handleLetterPress(BuildContext context, String letter) {
      if (letterPicker) {
        Navigator.of(context).pop(letter);
        return;
      }

    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      rackState.addLetter(letter);
    } else if (boardState.selectedIndex != null) {
      final pos = Position.fromIndex(boardState.selectedIndex!);

      if (letter == ' ') {
        if (boardState.letters[pos.row][pos.col] != null) {
          boardState.toggleBlank(pos);
        }
        return;
      }
      
      boardState.writeLetter(letter, pos);
      boardState.selectedIndex = pos.next(boardState.isVertical).index;
    }
  }

  void _handleBackspace(BuildContext context) {
    final rackState = context.read<RackState>();
    final boardState = context.read<BoardState>();
    
    if (rackState.isSelected) {
      rackState.removeLast();
    } else if (boardState.selectedIndex != null) {
      final pos = Position.fromIndex(boardState.selectedIndex!);

      boardState.removeLetter(pos);
      boardState.selectedIndex = pos.previous(boardState.isVertical).index;
    }
  }

  @override
  Widget build(BuildContext context) {
    const letters = [
      ['a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['q', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm'],
      [' ', 'w', 'x', 'c', 'v', 'b', 'n'],
    ];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final keySize = (constraints.maxWidth - 20) / 10;
        final buttonSize = keySize - 2;
                
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...letters.asMap().entries.map((entry) {
                int idx = entry.key;
                List<String> row = entry.value;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...row.map((letter) => letter != ' ' || !letterPicker
                      ? Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: InkWell(
                            onTap: () => _handleLetterPress(context, letter),
                            child: Tile.buildTile(letter, buttonSize, letterPoints, withBorder: true),
                          ),
                        ),
                      )
                      : const SizedBox.shrink()
                    ),
                    
                    if (idx == 2 && !letterPicker)
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: InkWell(
                            onTap: () => _handleBackspace(context),
                            child: Tile.buildTile(
                              '⌫',
                              buttonSize,
                              letterPoints,
                              specialColor: [Colors.red[50]!, Colors.red[100]!],
                              withBorder: true
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}