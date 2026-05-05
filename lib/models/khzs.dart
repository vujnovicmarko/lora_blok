import 'package:lora_blok/models/minigame.dart';

class Khzs extends Minigame {
  Khzs({super.callerId, super.results});

  @override
  String get fullName => 'Kralj herc, zadnji štih';

  @override
  String get shortName => 'KHZŠ';

  @override
  List<int> get allowedScores => [0, 4, 8];

  @override
  bool validateResults(Map<String, int> currentResults) {
    final sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8.';

  @override
  Khzs copyWith({String? callerId, Map<String, int>? results}) {
    return Khzs(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }
}
