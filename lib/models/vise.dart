import 'package:lora_blok/models/minigame.dart';

class Vise extends Minigame {
  Vise({super.callerId, super.results});

  @override
  String get fullName => 'VIŠE';

  @override
  String get shortName => 'VIŠE';

  @override
  Vise copyWith({String? callerId, Map<String, int>? results}) {
    return Vise(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
