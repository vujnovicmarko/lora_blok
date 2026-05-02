import 'package:lora_blok/models/minigame.dart';

class Slag extends Minigame {
  Slag({super.callerId, super.results});

  @override
  String get fullName => 'SLAGANJE';

  @override
  String get shortName => 'SLAG';

  @override
  Slag copyWith({String? callerId, Map<String, int>? results}) {
    return Slag(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
