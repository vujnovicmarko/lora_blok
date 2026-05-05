import 'package:lora_blok/models/minigame.dart';

class Herc extends Minigame {
  Herc({super.callerId, super.results});

  @override
  String get fullName => 'Herčevi';

  @override
  String get shortName => 'HERC';

  @override
  List<int> get allowedScores => [-8, 0, 1, 2, 3, 4, 5, 6, 7];

  @override
  bool validateResults(Map<String, int> currentResults) {
    final values = currentResults.values;
    final sum = values.fold(0, (sum, val) => sum + val);

    final standardMatch = sum == 8 && values.every((v) => v >= 0);
    final sweepMatch =
        sum == -8 &&
        values.contains(-8) &&
        values.where((v) => v == 0).length == (values.length - 1);

    return standardMatch || sweepMatch;
  }

  @override
  String get validationErrorMessage =>
      'Zbroj mora biti 8 ili jedan igrač ima -8 i ostali 0.';

  @override
  Herc copyWith({String? callerId, Map<String, int>? results}) {
    return Herc(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
