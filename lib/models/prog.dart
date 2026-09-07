import 'package:lora_blok/models/minigame.dart';

class Prog extends Minigame {
  Prog({super.callerId, super.results});

  @override
  String get fullName => 'Prognoza';

  @override
  String get shortName => 'PROG';

  @override
  List<int> get allowedScores => [-8, 8];

  @override
  bool validateResults(Map<int, int> currentResults) {
    return currentResults.values.contains(8);
  }

  @override
  String get validationErrorMessage => 'Barem jedna osoba mora imati 8 bodova.';

  @override
  Prog copyWith({int? callerId, Map<int, int>? results}) {
    return Prog(
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

  factory Prog.fromJson(Map<String, dynamic> json) {
    return Prog(
      callerId: json['callerId'] != null ? int.parse(json['callerId'].toString()) : null,
      results: (json['results'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}
