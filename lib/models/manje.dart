import 'package:lora_blok/models/minigame.dart';

class Manje extends Minigame {
  Manje({super.callerId, super.results});

  @override
  String get fullName => 'MANJE';

  @override
  String get shortName => 'MANJE';

  @override
  Manje copyWith({String? callerId, Map<String, int>? results}) {
    return Manje(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
