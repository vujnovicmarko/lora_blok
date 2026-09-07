import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lora_blok.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        num_wins INTEGER NOT NULL DEFAULT 0,
        num_games_played INTEGER NOT NULL DEFAULT 0,
        total_points INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        winner_id INTEGER,
        num_players INTEGER NOT NULL DEFAULT 4,
        played_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_finished INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (winner_id) REFERENCES players (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE game_players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        seat_position INTEGER NOT NULL,
        total_points INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games (id),
        FOREIGN KEY (player_id) REFERENCES players (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE game_minigames (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        minigame_type TEXT NOT NULL,
        caller_player_id INTEGER NOT NULL,
        round_index INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id),
        FOREIGN KEY (caller_player_id) REFERENCES players (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE game_minigame_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_minigame_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        points INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_minigame_id) REFERENCES game_minigames (id),
        FOREIGN KEY (player_id) REFERENCES players (id)
      )
    ''');
  }

  // ── Player CRUD ──

  Future<int> insertPlayer(String name) async {
    final db = await database;
    return await db.insert('players', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    final db = await database;
    return await db.query('players', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getPlayerById(int id) async {
    final db = await database;
    final results = await db.query('players', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getPlayerByName(String name) async {
    final db = await database;
    final results = await db.query('players', where: 'name = ?', whereArgs: [name]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getOrCreatePlayer(String name) async {
    final existing = await getPlayerByName(name);
    if (existing != null) return existing['id'] as int;
    return await insertPlayer(name);
  }



  // ── Game CRUD ──


  Future<List<Map<String, dynamic>>> getAllGames() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT *
      FROM games
      WHERE is_finished = 1
      ORDER BY played_at DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getGamePlayers(int gameId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT gp.*, p.name as player_name
      FROM game_players gp
      JOIN players p ON gp.player_id = p.id
      WHERE gp.game_id = ?
      ORDER BY gp.seat_position ASC
    ''', [gameId]);
  }

  // ── Game Players ──


  // ── Game Minigames ──


  // ── Full game save (called when game finishes) ──

  Future<void> saveCompletedGame({
    required List<Map<String, dynamic>> players,
    required List<Map<String, dynamic>> minigames,
    required Map<int, int> finalScores,
    required List<int> winnerIds,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      // Get or create all players in DB
      final Map<int, int> playerDbIds = {};
      for (var p in players) {
        final name = p['name'] as String;
        final existing = await txn.query('players', where: 'name = ?', whereArgs: [name]);
        int dbId;
        if (existing.isNotEmpty) {
          dbId = existing.first['id'] as int;
        } else {
          dbId = await txn.insert('players', {'name': name});
        }
        playerDbIds[p['id'] as int] = dbId;
      }

      final winnerDbId = winnerIds.isNotEmpty ? playerDbIds[winnerIds.first]! : 0;

      // Create game
      final gameId = await txn.insert('games', {
        'num_players': players.length,
        'winner_id': winnerDbId,
        'is_finished': 1,
      });

      // Insert game players with positions and final scores
      for (int i = 0; i < players.length; i++) {
        final playerId = players[i]['id'] as int;
        final dbId = playerDbIds[playerId]!;
        final totalPoints = finalScores[playerId] ?? 0;

        await txn.insert('game_players', {
          'game_id': gameId,
          'player_id': dbId,
          'seat_position': i + 1,
          'total_points': totalPoints,
        });
      }

      // Insert minigame results
      for (int i = 0; i < minigames.length; i++) {
        final mg = minigames[i];
        final callerGameId = mg['callerId'] as int?;
        final callerDbId = callerGameId != null ? playerDbIds[callerGameId]! : 0;

        final mgId = await txn.insert('game_minigames', {
          'game_id': gameId,
          'minigame_type': mg['type'] as String,
          'caller_player_id': callerDbId,
          'round_index': i,
        });

        final rawResults = mg['results'] as Map? ?? {};
        for (var entry in rawResults.entries) {
          final pDbId = playerDbIds[int.parse(entry.key.toString())];
          if (pDbId != null) {
            await txn.insert('game_minigame_scores', {
              'game_minigame_id': mgId,
              'player_id': pDbId,
              'points': entry.value as int,
            });
          }
        }
      }

      // Update player stats
      for (var p in players) {
        final playerId = p['id'] as int;
        final dbId = playerDbIds[playerId]!;
        final points = finalScores[playerId] ?? 0;
        final isWinner = winnerIds.contains(playerId);

        await txn.rawUpdate('''
          UPDATE players SET
            num_games_played = num_games_played + 1,
            total_points = total_points + ?,
            num_wins = num_wins + ?
          WHERE id = ?
        ''', [points, isWinner ? 1 : 0, dbId]);
      }
    });
  }

  Future<Map<String, dynamic>?> getFullGame(int gameId) async {
    final db = await database;
    
    final playersData = await db.rawQuery('''
      SELECT gp.player_id as dbId, gp.seat_position, p.name
      FROM game_players gp
      JOIN players p ON gp.player_id = p.id
      WHERE gp.game_id = ?
      ORDER BY gp.seat_position ASC
    ''', [gameId]);

    if (playersData.isEmpty) return null;

    final players = playersData.map((row) => {
      'id': row['seat_position'] as int,
      'name': row['name'],
      'dbId': row['dbId'],
    }).toList();

    final dbIdToTempId = {
      for (var row in playersData) row['dbId'] as int: row['seat_position'] as int
    };

    final minigamesData = await db.query(
      'game_minigames',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'round_index ASC',
    );

    final minigames = <Map<String, dynamic>>[];
    for (var mg in minigamesData) {
      final mgId = mg['id'] as int;
      final type = mg['minigame_type'] as String;
      final callerDbId = mg['caller_player_id'] as int;
      
      final scoresData = await db.query(
        'game_minigame_scores',
        where: 'game_minigame_id = ?',
        whereArgs: [mgId],
      );

      final results = <String, int>{};
      for (var s in scoresData) {
        final pDbId = s['player_id'] as int;
        final tempId = dbIdToTempId[pDbId];
        if (tempId != null) {
          results[tempId.toString()] = s['points'] as int;
        }
      }

      minigames.add({
        'type': type,
        'callerId': dbIdToTempId[callerDbId]?.toString(),
        'results': results,
        'playerIds': dbIdToTempId.values.map((v) => v.toString()).toList(),
      });
    }

    return {
      'players': players,
      'minigames': minigames,
    };
  }

  // ── Stats ──

  Future<List<Map<String, dynamic>>> getPlayerStats() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT *
      FROM players
      ORDER BY num_wins DESC, total_points ASC
    ''');

    return results.map((row) {
      final map = Map<String, dynamic>.from(row);
      final games = map['num_games_played'] as int? ?? 0;
      final wins = map['num_wins'] as int? ?? 0;
      final pts = map['total_points'] as int? ?? 0;
      
      map['avg_points'] = games > 0 ? pts / games : 0.0;
      map['win_rate'] = games > 0 ? (wins / games) * 100 : 0.0;
      
      return map;
    }).toList();
  }

  Future<void> deleteGame(int gameId) async {
    final db = await database;
    await db.transaction((txn) async {
      final gamePlayers = await txn.query('game_players', where: 'game_id = ?', whereArgs: [gameId]);
      
      int? minScore;
      for (var gp in gamePlayers) {
        final pts = gp['total_points'] as int? ?? 0;
        if (minScore == null || pts < minScore) minScore = pts;
      }

      for (var gp in gamePlayers) {
        final pId = gp['player_id'] as int;
        final ptsInGame = gp['total_points'] as int? ?? 0;
        final wasWinner = ptsInGame == minScore;

        await txn.rawUpdate('''
          UPDATE players SET
            num_games_played = MAX(0, num_games_played - 1),
            total_points = total_points - ?,
            num_wins = MAX(0, num_wins - ?)
          WHERE id = ?
        ''', [ptsInGame, wasWinner ? 1 : 0, pId]);
      }

      final minigames = await txn.query(
        'game_minigames',
        columns: ['id'],
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
      for (var mg in minigames) {
        await txn.delete(
          'game_minigame_scores',
          where: 'game_minigame_id = ?',
          whereArgs: [mg['id']],
        );
      }
      await txn.delete('game_minigames', where: 'game_id = ?', whereArgs: [gameId]);
      await txn.delete('game_players', where: 'game_id = ?', whereArgs: [gameId]);
      await txn.delete('games', where: 'id = ?', whereArgs: [gameId]);
    });
  }

  Future<void> clearAllGames() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('game_minigame_scores');
      await txn.delete('game_minigames');
      await txn.delete('game_players');
      await txn.delete('games');
    });
  }

  Future<void> clearAllPlayers() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('game_minigame_scores');
      await txn.delete('game_minigames');
      await txn.delete('game_players');
      await txn.delete('games');
      await txn.delete('players');
    });
  }


  Future<void> deletePlayer(int playerId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Find all games this player participated in
      final gameRows = await txn.rawQuery('''
        SELECT DISTINCT game_id FROM game_players WHERE player_id = ?
      ''', [playerId]);

      final gameIds = gameRows.map((r) => r['game_id'] as int).toList();

      // Delete each game fully (scores, minigames, game_players, game)
      for (final gameId in gameIds) {
        final allGamePlayers = await txn.query('game_players', where: 'game_id = ?', whereArgs: [gameId]);
        int? minScore;
        for (var gp in allGamePlayers) {
          final pts = gp['total_points'] as int? ?? 0;
          if (minScore == null || pts < minScore) minScore = pts;
        }

        // Decrement stats for other players in this game
        final otherPlayers = await txn.rawQuery('''
          SELECT player_id, total_points FROM game_players WHERE game_id = ? AND player_id != ?
        ''', [gameId, playerId]);

        for (var op in otherPlayers) {
          final otherPlayerId = op['player_id'] as int;
          final ptsInGame = op['total_points'] as int? ?? 0;
          final wasWinner = ptsInGame == minScore;
          await txn.rawUpdate('''
            UPDATE players SET
              num_games_played = MAX(0, num_games_played - 1),
              total_points = total_points - ?,
              num_wins = MAX(0, num_wins - ?)
            WHERE id = ?
          ''', [ptsInGame, wasWinner ? 1 : 0, otherPlayerId]);
        }

        final minigames = await txn.query(
          'game_minigames',
          columns: ['id'],
          where: 'game_id = ?',
          whereArgs: [gameId],
        );
        for (var mg in minigames) {
          await txn.delete(
            'game_minigame_scores',
            where: 'game_minigame_id = ?',
            whereArgs: [mg['id']],
          );
        }
        await txn.delete('game_minigames', where: 'game_id = ?', whereArgs: [gameId]);
        await txn.delete('game_players', where: 'game_id = ?', whereArgs: [gameId]);
        await txn.delete('games', where: 'id = ?', whereArgs: [gameId]);
      }

      // Delete the player
      await txn.delete('players', where: 'id = ?', whereArgs: [playerId]);
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
