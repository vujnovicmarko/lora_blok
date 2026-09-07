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
  bool validateResults(Map<int, int> currentResults) {
    final sum = currentResults.values.fold(0, (sum, val) => sum + val);
    return sum == 8;
  }

  @override
  String get validationErrorMessage => 'Zbroj bodova mora biti 8.';

  @override
  Khzs copyWith({int? callerId, Map<int, int>? results}) {
    return Khzs(
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

  factory Khzs.fromJson(Map<String, dynamic> json) {
    return Khzs(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
