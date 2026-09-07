import 'package:lora_blok/models/minigame.dart';

class Dame extends Minigame {
  Dame({super.callerId, super.results});

  @override
  String get fullName => 'Dame';

  @override
  String get shortName => 'DAME';

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
  Dame copyWith({int? callerId, Map<int, int>? results}) {
    return Dame(
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

  factory Dame.fromJson(Map<String, dynamic> json) {
    return Dame(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
