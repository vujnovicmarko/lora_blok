import 'package:lora_blok/models/minigame.dart';

class Slag extends Minigame {
  final List<String> playerIds;
  final Map<String, int> basePoints;
  final Map<String, int> whistles;

  Slag({
    super.callerId,
    super.results,
    required this.playerIds,
    this.basePoints = const {},
    this.whistles = const {},
  });

  @override
  String get fullName => 'SLAGANJE';

  @override
  String get shortName => 'SLAG';

  @override
  List<int> get allowedScores => [-8, -4, 4, 8];

  int _getPriority(String playerId) {
    int callerIndex = playerIds.indexOf(callerId!);
    int playerIndex = playerIds.indexOf(playerId);
    return (playerIndex - callerIndex) % playerIds.length;
  }

  @override
  bool validateResults(Map<String, int> currentResults) {
    final positions = basePoints.values.toList();

    if (positions.length != 4 ||
        !positions.contains(-8) ||
        !positions.contains(-4) ||
        !positions.contains(4) ||
        !positions.contains(8)) {
      return false;
    }

    for (var a in basePoints.entries) {
      for (var b in basePoints.entries) {
        if (a.key == b.key) continue;

        int scoreA = a.value;
        int scoreB = b.value;
        int wA = whistles[a.key] ?? 0;
        int wB = whistles[b.key] ?? 0;

        if (scoreA < scoreB && wA > wB) {
          return false;
        }

        if (wA == wB) {
          int priorityA = _getPriority(a.key);
          int priorityB = _getPriority(b.key);

          if (priorityA < priorityB && scoreA > scoreB) {
            return false;
          }
        }
      }
    }
    return true;
  }

  @override
  String get validationErrorMessage =>
      "Provjerite redoslijed završetka i broj fućkanja.";

  @override
  Slag copyWith({String? callerId, Map<String, int>? results}) {
    return Slag(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
      playerIds: playerIds,
      basePoints: Map.from(basePoints),
      whistles: Map.from(whistles),
    );
  }
}
