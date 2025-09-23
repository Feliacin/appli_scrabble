import 'package:appli_scrabble/tile.dart';
import 'package:flutter/material.dart';

class Keyboard extends StatelessWidget {
  final Map<String, int> letterPoints;
  final Function(String) onLetterPressed;
  final bool withBlank;
  final bool withDelete;
  const Keyboard(this.letterPoints, this.onLetterPressed, {
    super.key, this.withBlank = true, this.withDelete = true});

  @override
  Widget build(BuildContext context) {
    const letters = [
      ['a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['q', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm'],
      [' ', 'w', 'x', 'c', 'v', 'b', 'n', '⌫'],
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
                List<String> row = entry.value;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...row.map((letter) => (letter != ' ' || withBlank) && (letter != '⌫' || withDelete)
                      ? Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: InkWell(
                            onTap: () => onLetterPressed(letter),
                            child: Tile.buildTile(letter, buttonSize, letterPoints, withBorder: true, isBlank: letter == '⌫'),
                          ),
                        ),
                      )
                      : const SizedBox.shrink()
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