import 'package:lora_blok/models/minigame.dart';

class Dpp extends Minigame {
  Dpp({super.callerId, super.results});

  @override
  String get fullName => 'Dečko preko puta';

  @override
  String get shortName => 'DPP';

  @override
  List<int> get allowedScores => [0, 2, 4, 6, 8];

  @override
  bool validateResults(Map<String, int> currentResults) {
    final sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8.';

  @override
  Dpp copyWith({String? callerId, Map<String, int>? results}) {
    return Dpp(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
