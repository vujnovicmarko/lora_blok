import 'package:flutter/material.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';
import 'scoreboard_cell.dart';

class ScoreboardTable extends StatelessWidget {
  final int callerIndex;
  final List<GamePlayer> players;
  final List<Minigame> allMinigames;
  final List<Minigame> playedMinigames;
  final Map<String, int> currentTotals;
  final Function(Minigame, int, GamePlayer) onEditMinigame;

  const ScoreboardTable({
    super.key,
    required this.callerIndex,
    required this.players,
    required this.allMinigames,
    required this.playedMinigames,
    required this.currentTotals,
    required this.onEditMinigame,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gamesPerPlayer = allMinigames.length;
    final totalColumns = players.length + 1;
    final caller = players[callerIndex];

    final startIndex = callerIndex * gamesPerPlayer;
    final pageGames = <Minigame>[];
    final List<TableRow> rows = [];

    for (var i = startIndex; i < startIndex + gamesPerPlayer && i < playedMinigames.length; i++) {
      pageGames.add(playedMinigames[i]);
    }

    rows.add(
      TableRow(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
        children: [
          const ScoreboardCell(text: "IGRA", isBold: true),
          ...players.map((p) => ScoreboardCell(text: p.name.toUpperCase(), isBold: true)),
        ],
      ),
    );

    rows.add(
      TableRow(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
        children: [
          const ScoreboardCell(text: "START", isBold: true),
          ...players.map((p) => ScoreboardCell(text: "${currentTotals[p.id]}", isBold: true, color: colorScheme.primary)),
        ],
      ),
    );

    for (var i = 0; i < gamesPerPlayer; i++) {
      if (i < pageGames.length) {
        final game = pageGames[i];
        final globalIndex = startIndex + i;
        final isLastRow = globalIndex == playedMinigames.length - 1;

        List<Widget> rowCells = [
          ScoreboardCell(
            text: game.shortName,
            isBold: true,
            onLongPress: () => onEditMinigame(game, globalIndex, caller),
          ),
        ];

        for (var p in players) {
          final int delta = game.results[p.id] ?? 0;
          currentTotals[p.id] = currentTotals[p.id]! + delta;

          String? deltaStr;
          Color? deltaCol;

          if (isLastRow) {
            if (delta > 0) {
              deltaStr = " (+$delta)";
              deltaCol = colorScheme.error;
            } else if (delta < 0) {
              deltaStr = " ($delta)";
              deltaCol = colorScheme.primary;
            } else {
              deltaStr = " (0)";
              deltaCol = colorScheme.onSurface;
            }
          }

          rowCells.add(
            ScoreboardCell(
              text: "${currentTotals[p.id]}",
              deltaText: deltaStr,
              deltaColor: deltaCol,
              onLongPress: () => onEditMinigame(game, globalIndex, caller),
            ),
          );
        }

        rows.add(TableRow(children: rowCells));
      } else {
        rows.add(
          TableRow(
            children: List.generate(totalColumns, (_) => const ScoreboardCell(text: "")),
          ),
        );
      }
    }

    return Table(
      defaultColumnWidth: FractionColumnWidth(1.0 / totalColumns),
      border: TableBorder.all(color: colorScheme.outline),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }
}
