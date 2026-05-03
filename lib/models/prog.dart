import 'package:lora_blok/models/minigame.dart';

class Prog extends Minigame {
  Prog({super.callerId, super.results});

  @override
  String get fullName => 'PROGNOZA';

  @override
  String get shortName => 'PROG';

  @override
  List<int> get allowedScores => [-8, 8];

  @override
  bool validateResults(Map<String, int> currentResults) {
    return currentResults.values.contains(8);
  }

  @override
  String get validationErrorMessage => 'Barem jedna osoba mora imati 8 bodova!';

  @override
  Prog copyWith({String? callerId, Map<String, int>? results}) {
    return Prog(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
