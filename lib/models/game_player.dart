class GamePlayer {
  final int id;
  final String name;

  const GamePlayer({required this.id, required this.name});

  GamePlayer copyWith({int? id, String? name}) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
    id: json['id'] as int,
    name: json['name'] as String,
  );
}
