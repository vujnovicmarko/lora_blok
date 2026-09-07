import 'package:lora_blok/models/minigame.dart';

class Vise extends Minigame {
  Vise({super.callerId, super.results});

  @override
  String get fullName => 'Više';

  @override
  String get shortName => 'VIŠE';

  @override
  List<int> get allowedScores => [8, -1, -2, -3, -4, -5, -6, -7, -8];

  @override
  bool validateResults(Map<int, int> currentResults) {
    final sum = currentResults.values
        .where((val) => val < 0)
        .fold(0, (sum, val) => sum + val);
    return sum == -8;
  }

  @override
  String get validationErrorMessage => 'Zbroj negativnih bodova mora biti -8.';

  @override
  Vise copyWith({int? callerId, Map<int, int>? results}) {
    return Vise(
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

  factory Vise.fromJson(Map<String, dynamic> json) {
    return Vise(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
