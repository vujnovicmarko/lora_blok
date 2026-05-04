import 'package:lora_blok/models/minigame.dart';

class Dame extends Minigame {
  Dame({super.callerId, super.results});

  @override
  String get fullName => 'DAME';

  @override
  String get shortName => 'DAME';

  @override
  List<int> get allowedScores => [0, 2, 4, 6, 8];

  @override
  bool validateResults(Map<String, int> currentResults) {
    int sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8.';

  @override
  Dame copyWith({String? callerId, Map<String, int>? results}) {
    return Dame(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
