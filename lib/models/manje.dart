import 'package:lora_blok/models/minigame.dart';

class Manje extends Minigame {
  Manje({super.callerId, super.results});

  @override
  String get fullName => 'Manje';

  @override
  String get shortName => 'MANJE';

  @override
  List<int> get allowedScores => [-8, 1, 2, 3, 4, 5, 6, 7, 8];

  @override
  bool validateResults(Map<int, int> currentResults) {
    final sum = currentResults.values
        .where((val) => val > 0)
        .fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj pozitivnih bodova mora biti 8.';

  @override
  Manje copyWith({int? callerId, Map<int, int>? results}) {
    return Manje(
      callerId: callerId ?? this.callerId,
      results: results ?? Map.from(this.results),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': shortName,
    'callerId': callerId,
    'results': results.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory Manje.fromJson(Map<String, dynamic> json) {
    return Manje(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
