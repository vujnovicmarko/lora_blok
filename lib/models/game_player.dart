class GamePlayer {
  final String id;
  final String name;

  const GamePlayer({required this.id, required this.name});

  GamePlayer copyWith({String? id, String? name, int? score}) {
    return GamePlayer(id: id ?? this.id, name: name ?? this.name);
  }
}
