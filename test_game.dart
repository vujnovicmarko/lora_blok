import 'dart:convert';

void main() {
  final players = [
    {'id': 1, 'name': 'A'},
    {'id': 2, 'name': 'B'},
    {'id': 3, 'name': 'C'},
    {'id': 4, 'name': 'D'},
  ];
  
  final finalScores = {1: 0, 2: 0, 3: 8, 4: 24};
  
  final sortedPlayers = List<Map<String, dynamic>>.from(players);
  sortedPlayers.sort((a, b) => finalScores[a['id']]!.compareTo(finalScores[b['id']]!));

  final minScore = finalScores[sortedPlayers.first['id']]!;
  final winnerIds = sortedPlayers
      .where((p) => finalScores[p['id']] == minScore)
      .map((p) => p['id'])
      .toList();

  print('winnerIds: $winnerIds');

  for (var p in players) {
    final playerId = p['id'] as int;
    final points = finalScores[playerId] ?? 0;
    final isWinner = winnerIds.contains(playerId);
    print('Player $playerId: points=$points, isWinner=$isWinner');
  }
}
