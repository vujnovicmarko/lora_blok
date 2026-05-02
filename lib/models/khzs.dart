import 'package:lora_blok/models/minigame.dart';

class Khzs extends Minigame {
  Khzs({super.callerId, super.results});

  @override
  String get fullName => 'KRALJ HERC, ZADNJI ŠTIH';

  @override
  String get shortName => 'KHZŠ';

  @override
  Khzs copyWith({String? callerId, Map<String, int>? results}) {
    return Khzs(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
