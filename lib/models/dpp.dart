import 'package:lora_blok/models/minigame.dart';

class Dpp extends Minigame {
  Dpp({super.callerId, super.results});

  @override
  String get fullName => 'DEČKO PREKO PUTA';

  @override
  String get shortName => 'DPP';

  @override
  Dpp copyWith({String? callerId, Map<String, int>? results}) {
    return Dpp(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
