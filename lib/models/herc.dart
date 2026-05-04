import 'package:lora_blok/models/minigame.dart';

class Herc extends Minigame {
  Herc({super.callerId, super.results});

  @override
  String get fullName => 'HERČEVI';

  @override
  String get shortName => 'HERC';

  @override
  List<int> get allowedScores => [-8, 0, 1, 2, 3, 4, 5, 6, 7];

  @override
  bool validateResults(Map<String, int> currentResults) {
    int sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8 || sum == -8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8 ili -8.';

  @override
  Herc copyWith({String? callerId, Map<String, int>? results}) {
    return Herc(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
