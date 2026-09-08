import 'dame.dart';
import 'dpp.dart';
import 'herc.dart';
import 'khzs.dart';
import 'manje.dart';
import 'prog.dart';
import 'slag.dart';
import 'vise.dart';

abstract class Minigame {
  String get fullName;
  String get shortName;
  final int? callerId;
  final Map<int, int> results;

  Minigame({this.callerId, Map<int, int>? results}) : results = results ?? {};

  List<int> get allowedScores;
  bool validateResults(Map<int, int> currentResults);
  String get validationErrorMessage;
  Minigame copyWith({int? callerId, Map<int, int>? results});
  Map<String, dynamic> toJson();

  factory Minigame.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'DPP':
        return Dpp.fromJson(json);
      case 'DAME':
        return Dame.fromJson(json);
      case 'KHZŠ':
        return Khzs.fromJson(json);
      case 'HERC':
        return Herc.fromJson(json);
      case 'MANJE':
        return Manje.fromJson(json);
      case 'VIŠE':
        return Vise.fromJson(json);
      case 'PROG':
        return Prog.fromJson(json);
      case 'SLAG':
        return Slag.fromJson(json);
      default:
        throw ArgumentError('Unknown minigame type: $type');
    }
  }

  factory Minigame.blank(String type, {List<int>? playerIds}) {
    switch (type) {
      case 'DPP':
        return Dpp();
      case 'DAME':
        return Dame();
      case 'KHZŠ':
        return Khzs();
      case 'HERC':
        return Herc();
      case 'MANJE':
        return Manje();
      case 'VIŠE':
        return Vise();
      case 'PROG':
        return Prog();
      case 'SLAG':
        return Slag(playerIds: playerIds ?? []);
      default:
        throw ArgumentError('Unknown minigame type: $type');
    }
  }
}
