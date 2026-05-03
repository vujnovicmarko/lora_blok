abstract class Minigame {
  String get fullName;
  String get shortName;
  final String? callerId;
  final Map<String, int> results;

  Minigame({this.callerId, Map<String, int>? results})
    : results = results ?? {};

  List<int> get allowedScores;
  bool validateResults(Map<String, int> currentResults);
  String get validationErrorMessage;
  Minigame copyWith({String? callerId, Map<String, int>? results});
}
