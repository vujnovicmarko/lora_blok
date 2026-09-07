import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_player.dart';

class ScoreSelectorRow extends StatelessWidget {
  final List<GamePlayer> players;
  final Map<int, int> values;
  final List<int>? allowedScores;
  final Function(int playerId, int newValue) onChanged;

  const ScoreSelectorRow({
    super.key,
    required this.players,
    required this.values,
    required this.onChanged,
    this.allowedScores,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDescending = allowedScores != null && allowedScores!.length > 1 && allowedScores!.first > allowedScores!.last;

    return Row(
      children: players.map((player) {
        int currentValue = values[player.id] ?? (allowedScores?.first ?? 0);
        int currentIndex = allowedScores?.indexOf(currentValue) ?? currentValue;

        bool canGoUp, canGoDown;
        if (allowedScores != null) {
          canGoUp = isDescending ? currentIndex > 0 : currentIndex < allowedScores!.length - 1;
          canGoDown = isDescending ? currentIndex < allowedScores!.length - 1 : currentIndex > 0;
        } else {
          canGoUp = currentValue < 12;
          canGoDown = currentValue > 0;
        }

        return Expanded(
          child: Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                onPressed: canGoUp
                    ? () {
                        int newValue = allowedScores != null 
                            ? allowedScores![isDescending ? currentIndex - 1 : currentIndex + 1] 
                            : currentValue + 1;
                        onChanged(player.id, newValue);
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
              Text(
                '$currentValue',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: canGoDown
                    ? () {
                        int newValue = allowedScores != null 
                            ? allowedScores![isDescending ? currentIndex + 1 : currentIndex - 1] 
                            : currentValue - 1;
                        onChanged(player.id, newValue);
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
