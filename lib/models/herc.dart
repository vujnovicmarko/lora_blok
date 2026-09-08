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
  bool validateResults(Map<int, int> currentResults) {
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
  Herc copyWith({int? callerId, Map<int, int>? results}) {
    return Herc(
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

  factory Herc.fromJson(Map<String, dynamic> json) {
    return Herc(
      callerId: json['callerId'] != null
          ? int.parse(json['callerId'].toString())
          : null,
      results: (json['results'] as Map? ?? {}).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
    );
  }
}
