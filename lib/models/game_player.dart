class GamePlayer {
  final String id;
  final String name;
  final int score;

  const GamePlayer({required this.id, required this.name, this.score = 0});

  GamePlayer copyWith({String? id, String? name, int? score}) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
