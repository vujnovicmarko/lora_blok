import 'package:lora_blok/models/minigame.dart';

class Manje extends Minigame {
  Manje({super.callerId, super.results});

  @override
  String get fullName => 'MANJE';

  @override
  String get shortName => 'MANJE';

  @override
  List<int> get allowedScores => [-8, 1, 2, 3, 4, 5, 6, 7, 8];

  @override
  bool validateResults(Map<String, int> currentResults) {
    int sum = currentResults.values
        .where((val) => val > 0)
        .fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj pozitivnih bodova mora biti 8.';

  @override
  Manje copyWith({String? callerId, Map<String, int>? results}) {
    return Manje(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
