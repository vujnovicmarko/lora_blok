import 'package:lora_blok/models/minigame.dart';

class Dame extends Minigame {
  Dame({super.callerId, super.results});

  @override
  String get fullName => 'DAME';

  @override
  String get shortName => 'DAME';

  @override
  Dame copyWith({String? callerId, Map<String, int>? results}) {
    return Dame(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
