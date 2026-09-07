import 'package:flutter/material.dart';
import '../models/game_player.dart';
import '../models/minigame.dart';
import '../database/database_helper.dart';
import '../database/game_cache.dart';

class GameOverDialog extends StatelessWidget {
  final String gameId;
  final List<GamePlayer> players;
  final List<Minigame> playedMinigames;

  const GameOverDialog({
    super.key,
    required this.gameId,
    required this.players,
    required this.playedMinigames,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final finalScores = {for (var p in players) p.id: 0};
    for (var game in playedMinigames) {
      for (var p in players) {
        finalScores[p.id] = finalScores[p.id]! + (game.results[p.id] ?? 0);
      }
    }

    final sortedPlayers = List<GamePlayer>.from(players);
    sortedPlayers.sort((a, b) => finalScores[a.id]!.compareTo(finalScores[b.id]!));

    final playerRanks = <int, int>{};
    int currentRank = 1;
    int? previousScore;
    
    for (int i = 0; i < sortedPlayers.length; i++) {
      final p = sortedPlayers[i];
      final score = finalScores[p.id]!;
      
      if (score != previousScore) {
        currentRank = i + 1;
        previousScore = score;
      }
      playerRanks[p.id] = currentRank;
    }

    final minScore = finalScores[sortedPlayers.first.id]!;
    final winnerIds = sortedPlayers
        .where((p) => finalScores[p.id] == minScore)
        .map((p) => p.id)
        .toList();

    return AlertDialog(
      title: const Center(
        child: Text("Partija završena!", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            ...sortedPlayers.map((p) {
              int rank = playerRanks[p.id]!;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$rank. ${p.name}",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      "${finalScores[p.id]}",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            const Divider(),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Tablica"),
        ),
        FilledButton(
          onPressed: () async {
            // Save game to database
            await _saveGameToDatabase(finalScores, winnerIds);

            // Clear the cached game state
            await GameCache.clearGameState(gameId);

            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: OutlinedButton.styleFrom(side: BorderSide(color: colorScheme.primary)),
          child: const Text("Početna"),
        ),
      ],
    );
  }

  Future<void> _saveGameToDatabase(
    Map<int, int> finalScores,
    List<int> winnerIds,
  ) async {
    try {
      final playerMaps = players.map((p) => p.toJson()).toList();
      final minigameMaps = playedMinigames.map((m) => m.toJson()).toList();

      await DatabaseHelper.instance.saveCompletedGame(
        players: playerMaps,
        minigames: minigameMaps,
        finalScores: finalScores,
        winnerIds: winnerIds,
      );
    } catch (e) {
      // Silently fail — don't block the user from returning home
      debugPrint('Error saving game to database: $e');
    }
  }
}
