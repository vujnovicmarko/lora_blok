class Player {
  final String id;
  final String name;
  final int score;

  const Player({required this.id, required this.name, this.score = 0});

  Player copyWith({String? id, String? name, int? score}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
