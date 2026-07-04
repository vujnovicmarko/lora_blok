import 'package:flutter/material.dart';
import '../models/game_player.dart';

class PlayerNamesRow extends StatelessWidget {
  final List<GamePlayer> players;

  const PlayerNamesRow({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: players.map((player) {
        return Expanded(
          child: Text(
            player.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}
