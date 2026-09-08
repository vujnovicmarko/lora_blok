import 'package:flutter/material.dart';
import '../models/minigame.dart';

class GameSelector extends StatelessWidget {
  final List<Minigame> allMinigames;
  final List<Minigame> playedByThisPlayer;
  final Minigame? selectedMinigame;
  final Minigame? initialMinigame;
  final Function(Minigame) onSelected;

  const GameSelector({
    super.key,
    required this.allMinigames,
    required this.playedByThisPlayer,
    required this.selectedMinigame,
    required this.initialMinigame,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: allMinigames.map((game) {
        bool isAlreadyPlayed = playedByThisPlayer.any(
          (p) => p.shortName == game.shortName,
        );
        bool isSelected = selectedMinigame?.shortName == game.shortName;
        bool isCurrentEditTarget = initialMinigame?.shortName == game.shortName;
        bool isDisabled = isAlreadyPlayed && !isCurrentEditTarget;

        return ChoiceChip(
          label: Text(game.shortName),
          selected: isSelected,
          onSelected: isDisabled
              ? null
              : (val) {
                  if (val) onSelected(game);
                },
        );
      }).toList(),
    );
  }
}
