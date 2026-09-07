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
  bool validateResults(Map<int, int> currentResults) {
    final sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8.';

  @override
  Dpp copyWith({int? callerId, Map<int, int>? results}) {
    return Dpp(
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

  factory Dpp.fromJson(Map<String, dynamic> json) {
    return Dpp(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
