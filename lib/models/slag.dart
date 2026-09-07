import 'package:lora_blok/models/minigame.dart';

class Slag extends Minigame {
  final List<int> playerIds;
  final Map<int, int> basePoints;
  final Map<int, int> whistles;

  Slag({
    super.callerId,
    super.results,
    required this.playerIds,
    this.basePoints = const {},
    this.whistles = const {},
  });

  @override
  String get fullName => 'Slaganje';

  @override
  String get shortName => 'SLAG';

  @override
  List<int> get allowedScores => [-8, -4, 4, 8];

  int _getPriority(int playerId) {
    final callerIndex = playerIds.indexOf(callerId!);
    final playerIndex = playerIds.indexOf(playerId);
    return (playerIndex - callerIndex) % playerIds.length;
  }

  @override
  bool validateResults(Map<int, int> currentResults) {
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

        final scoreA = a.value;
        final scoreB = b.value;
        final wA = whistles[a.key] ?? 0;
        final wB = whistles[b.key] ?? 0;

        if (scoreA < scoreB && wA > wB) {
          return false;
        }

        if (wA == wB) {
          final priorityA = _getPriority(a.key);
          final priorityB = _getPriority(b.key);

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
  Slag copyWith({int? callerId, Map<int, int>? results}) {
    return Slag(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
      playerIds: playerIds,
      basePoints: Map.from(basePoints),
      whistles: Map.from(whistles),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': shortName,
    'callerId': callerId,
    'results': results.map((k, v) => MapEntry(k.toString(), v)),
    'playerIds': playerIds,
    'basePoints': basePoints.map((k, v) => MapEntry(k.toString(), v)),
    'whistles': whistles.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory Slag.fromJson(Map<String, dynamic> json) {
    return Slag(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
      playerIds: (json['playerIds'] as List<dynamic>? ?? []).map((e) => int.parse(e.toString())).toList(),
      basePoints: (json['basePoints'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
      whistles: (json['whistles'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
