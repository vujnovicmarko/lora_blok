abstract class Minigame {
  String get fullName;
  String get shortName;
  final String? callerId;
  final Map<String, int> results;

  Minigame({this.callerId, Map<String, int>? results})
    : results = results ?? {};

  Minigame copyWith({String? callerId, Map<String, int>? results});
}
