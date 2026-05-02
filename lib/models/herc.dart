import 'package:lora_blok/models/minigame.dart';

class Herc extends Minigame {
  Herc({super.callerId, super.results});

  @override
  String get fullName => 'HERČEVI';

  @override
  String get shortName => 'HERC';

  @override
  Herc copyWith({String? callerId, Map<String, int>? results}) {
    return Herc(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
