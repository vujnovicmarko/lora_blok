import 'package:lora_blok/models/minigame.dart';

class Prog extends Minigame {
  Prog({super.callerId, super.results});

  @override
  String get fullName => 'PROGNOZA';

  @override
  String get shortName => 'PROG';

  @override
  Prog copyWith({String? callerId, Map<String, int>? results}) {
    return Prog(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
