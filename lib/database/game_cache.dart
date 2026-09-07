import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_player.dart';
import '../models/minigame.dart';


class GameCache {
  static const _activeGamesKey = 'active_games_list_v2';

  /// Save the current in-progress game state
  static Future<void> saveGameState({
    required String id,
    required List<GamePlayer> players,
    required List<Minigame> playedMinigames,
    required List<String> allMinigameTypes,
    required int currentPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final state = {
      'id': id,
      'players': players.map((p) => p.toJson()).toList(),
      'playedMinigames': playedMinigames.map((m) => m.toJson()).toList(),
      'allMinigameTypes': allMinigameTypes,
      'currentPage': currentPage,
      'savedAt': DateTime.now().toIso8601String(),
    };

    final rawList = prefs.getStringList(_activeGamesKey) ?? [];
    
    int index = -1;
    for (int i = 0; i < rawList.length; i++) {
      try {
        final decoded = jsonDecode(rawList[i]);
        if (decoded['id'] == id) {
          index = i;
          break;
        }
      } catch (_) {}
    }

    if (index != -1) {
      rawList[index] = jsonEncode(state);
    } else {
      rawList.add(jsonEncode(state));
    }

    await prefs.setStringList(_activeGamesKey, rawList);
  }

  /// Load all cached active games
  static Future<List<Map<String, dynamic>>> loadAllActiveGames() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_activeGamesKey) ?? [];
    
    List<Map<String, dynamic>> games = [];
    for (var raw in rawList) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        games.add(json);
      } catch (_) {}
    }
    
    games.sort((a, b) => (b['savedAt'] as String).compareTo(a['savedAt'] as String));
    return games;
  }

  /// Load a specific cached game state
  static Future<Map<String, dynamic>?> loadGameState(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_activeGamesKey) ?? [];

    for (var raw in rawList) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['id'] == id) {
          final players = (json['players'] as List)
              .map((p) => GamePlayer.fromJson(Map<String, dynamic>.from(p)))
              .toList();

          final playedMinigames = (json['playedMinigames'] as List)
              .map((m) => Minigame.fromJson(Map<String, dynamic>.from(m)))
              .toList();

          final allMinigameTypes = List<String>.from(json['allMinigameTypes']);
          final playerIds = players.map((p) => p.id).toList();
          final allMinigames = allMinigameTypes
              .map((type) => Minigame.blank(type, playerIds: playerIds))
              .toList();

          return {
            'id': id,
            'players': players,
            'playedMinigames': playedMinigames,
            'allMinigames': allMinigames,
            'allMinigameTypes': allMinigameTypes,
            'currentPage': json['currentPage'] as int,
            'savedAt': json['savedAt'] as String,
          };
        }
      } catch (_) {}
    }
    return null;
  }

  /// Clear specific cached game state
  static Future<void> clearGameState(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_activeGamesKey) ?? [];
    
    rawList.removeWhere((raw) {
      try {
        final json = jsonDecode(raw);
        return json['id'] == id;
      } catch (e) {
        return true; // remove corrupted
      }
    });

    await prefs.setStringList(_activeGamesKey, rawList);
  }

  /// Remove all cached active games containing the player with [playerId] or [playerName]
  static Future<void> removeActiveGamesWithPlayer(int playerId, {String? playerName}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_activeGamesKey) ?? [];
    
    rawList.removeWhere((raw) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final players = json['players'] as List? ?? [];
        for (var p in players) {
          if (p is Map) {
            final pId = p['id'];
            final pName = p['name'];
            if (pId == playerId) return true;
            if (playerName != null && pName == playerName) return true;
          }
        }
        return false;
      } catch (e) {
        return true; // remove corrupted
      }
    });

    await prefs.setStringList(_activeGamesKey, rawList);
  }

  /// Clear all cached active games
  static Future<void> clearAllActiveGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGamesKey);
  }
}
