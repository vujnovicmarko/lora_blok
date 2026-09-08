import 'package:flutter/material.dart';
import '../models/dame.dart';
import '../models/dpp.dart';
import '../models/herc.dart';
import '../models/khzs.dart';
import '../models/manje.dart';
import '../models/minigame.dart';
import '../models/prog.dart';
import '../models/slag.dart';
import '../models/vise.dart';
import '../models/game_player.dart';
import '../database/database_helper.dart';
import '../widgets/empty_state_placeholder.dart';
import '../widgets/expandable_section_header.dart';
import '../utils/date_formatter.dart';
import '../database/game_cache.dart';
import 'scoreboard_screen.dart';

import '../widgets/settings_modal.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _pastGames = [];
  List<Map<String, dynamic>> _activeGames = [];
  bool _isLoading = true;
  bool _isHistoryExpanded = false;
  bool _isActiveExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final active = await GameCache.loadAllActiveGames();
    final gamesRaw = await DatabaseHelper.instance.getAllGames();
    final games = gamesRaw.map((g) => Map<String, dynamic>.from(g)).toList();

    for (var game in games) {
      final gamePlayers = await DatabaseHelper.instance.getGamePlayers(
        game['id'] as int,
      );
      game['player_names'] = gamePlayers
          .map((p) => p['player_name'] as String)
          .toList();

      int? minScore;
      for (var gp in gamePlayers) {
        final pts = gp['total_points'] as int? ?? 0;
        if (minScore == null || pts < minScore) minScore = pts;
      }
      game['winner_names'] = gamePlayers
          .where((gp) => (gp['total_points'] as int? ?? 0) == minScore)
          .map((gp) => gp['player_name'] as String)
          .toList();
    }

    if (mounted) {
      setState(() {
        _activeGames = active;
        _pastGames = games;
        _isLoading = false;
      });
    }
  }

  List<Minigame> _buildMinigameList() {
    return [
      Dpp(),
      Dame(),
      Khzs(),
      Herc(),
      Manje(),
      Vise(),
      Prog(),
      Slag(playerIds: []),
    ];
  }

  Future<void> _startNewGame() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          StartGameDialog(availableMinigames: _buildMinigameList()),
    );

    if (result == null) return;

    final players = result['players'] as List<GamePlayer>;
    final minigames = result['minigames'] as List<Minigame>;

    if (mounted) {
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreboardScreen(
            gameId: gameId,
            players: players,
            allMinigames: minigames,
          ),
        ),
      );
      _loadData();
    }
  }

  Future<void> _resumeGame(String id) async {
    final state = await GameCache.loadGameState(id);
    if (state == null) {
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nije moguće nastaviti igru.')),
        );
      }
      return;
    }

    final players = state['players'] as List<GamePlayer>;
    final allMinigames = state['allMinigames'] as List<Minigame>;
    final playedMinigames = state['playedMinigames'] as List<Minigame>;
    final currentPage = state['currentPage'] as int;

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreboardScreen(
            gameId: id,
            players: players,
            allMinigames: allMinigames,
            resumePlayedMinigames: playedMinigames,
            resumeCurrentPage: currentPage,
          ),
        ),
      );
      _loadData();
    }
  }

  Future<void> _viewPastGame(int dbId) async {
    final gameData = await DatabaseHelper.instance.getFullGame(dbId);
    if (gameData == null || !mounted) return;

    final playersData = gameData['players'] as List;
    final players = playersData
        .map((p) => GamePlayer(id: p['id'] as int, name: p['name'] as String))
        .toList();

    final minigamesData = gameData['minigames'] as List;
    final playedMinigames = minigamesData
        .map((m) => Minigame.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    final Set<String> uniqueTypes = {};
    for (var m in playedMinigames) {
      uniqueTypes.add(m.shortName);
    }

    final playerIds = players.map((p) => p.id).toList();
    final allMinigames = uniqueTypes
        .map((type) => Minigame.blank(type, playerIds: playerIds))
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreboardScreen(
          gameId: dbId.toString(),
          players: players,
          allMinigames: allMinigames,
          resumePlayedMinigames: playedMinigames,
          resumeCurrentPage: 0,
          isReadOnly: true,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCache(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati partiju?'),
        content: const Text(
          'Jeste li sigurni da želite obrisati aktivnu partiju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GameCache.clearGameState(id);
      _loadData();
    }
  }

  Future<void> _confirmDeletePastGame(int gameId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati partiju?'),
        content: const Text(
          'Jeste li sigurni da želite obrisati završenu partiju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteGame(gameId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool hasActiveGame = _activeGames.isNotEmpty;

    final List<Map<String, dynamic>> listItems = [];
    if (hasActiveGame) {
      listItems.add({'type': 'active_header'});
      if (_isActiveExpanded) {
        for (var game in _activeGames) {
          listItems.add({'type': 'active_game', 'game': game});
        }
      }
      listItems.add({'type': 'spacer'});
    }

    if (_pastGames.isNotEmpty) {
      listItems.add({'type': 'history_header'});
      if (_isHistoryExpanded) {
        for (var game in _pastGames) {
          listItems.add({'type': 'history_game', 'game': game});
        }
      }
    } else if (!hasActiveGame) {
      listItems.add({'type': 'empty'});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partije'),
        actions: [
          IconButton(
            onPressed: () => showSettingsModal(
              context,
              themeMode: widget.themeMode,
              onThemeToggle: widget.onThemeToggle,
              onDataCleared: _loadData,
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewGame,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];
                    final type = item['type'] as String;

                    if (type == 'active_header') {
                      return ExpandableSectionHeader(
                        title: 'Aktivne partije',
                        isExpanded: _isActiveExpanded,
                        onTap: () {
                          setState(() {
                            _isActiveExpanded = !_isActiveExpanded;
                          });
                        },
                      );
                    } else if (type == 'active_game') {
                      return _buildActiveGameCard(
                        item['game'],
                        colorScheme,
                        textTheme,
                      );
                    } else if (type == 'spacer') {
                      return const SizedBox(height: 24);
                    } else if (type == 'history_header') {
                      return ExpandableSectionHeader(
                        title: 'Povijest partija',
                        isExpanded: _isHistoryExpanded,
                        onTap: () {
                          setState(() {
                            _isHistoryExpanded = !_isHistoryExpanded;
                          });
                        },
                      );
                    } else if (type == 'history_game') {
                      return _buildGameHistoryCard(
                        item['game'],
                        colorScheme,
                        textTheme,
                      );
                    } else if (type == 'empty') {
                      return const EmptyStatePlaceholder(
                        icon: Icons.sports_esports,
                        title: 'Nema odigranih partija',
                        subtitle: 'Pritisni + za novu partiju',
                        actionIcon: Icons.add,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildGameHistoryCard(
    Map<String, dynamic> game,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final winnerNames = game['winner_names'] as List<String>? ?? [];
    final playedAt = game['played_at'] as String? ?? '';
    final formattedDate = DateFormatter.format(playedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text.rich(
          TextSpan(
            children: (game['player_names'] as List<String>? ?? []).map((name) {
              final isWinner = winnerNames.contains(name);
              return TextSpan(
                text: name == (game['player_names'] as List?)?.last
                    ? name
                    : '$name, ',
                style: TextStyle(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          style: textTheme.titleSmall,
        ),
        subtitle: Text(formattedDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () => _viewPastGame(game['id'] as int),
              child: const Text('Pregledaj'),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _confirmDeletePastGame(game['id'] as int),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGameCard(
    Map<String, dynamic> game,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final savedAt = game['savedAt'] as String? ?? '';
    final formattedDate = DateFormatter.format(savedAt);

    final playersList = game['players'] as List? ?? [];
    final playerNames = playersList
        .map((p) => p['name']?.toString() ?? '?')
        .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.primaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(
          playerNames,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _resumeGame(game['id'] as String),
              child: const Text('Nastavi'),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _confirmDeleteCache(game['id'] as String),
            ),
          ],
        ),
      ),
    );
  }
}

class StartGameDialog extends StatefulWidget {
  final List<Minigame> availableMinigames;

  const StartGameDialog({super.key, required this.availableMinigames});

  @override
  State<StartGameDialog> createState() => _StartGameDialogState();
}

class _StartGameDialogState extends State<StartGameDialog> {
  List<Map<String, dynamic>> _dbPlayers = [];
  final List<int?> _selectedPlayerIds = [null, null, null, null];
  final Set<String> _selectedMinigameNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (var m in widget.availableMinigames) {
      _selectedMinigameNames.add(m.shortName);
    }
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await DatabaseHelper.instance.getAllPlayers();
    setState(() {
      _dbPlayers = players;
      _isLoading = false;
    });
  }

  Future<void> _addNewPlayer() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewPlayerDialog(existingPlayers: _dbPlayers),
    );

    if (name == null || name.isEmpty) return;

    final newPlayerId = await DatabaseHelper.instance.insertPlayer(name);
    await _loadPlayers();

    if (mounted) {
      setState(() {
        final emptyIndex = _selectedPlayerIds.indexOf(null);
        if (emptyIndex != -1) {
          _selectedPlayerIds[emptyIndex] = newPlayerId;
        }
      });
    }
  }

  bool _canStart() {
    // Check if 4 distinct players are selected
    if (_selectedPlayerIds.contains(null)) return false;
    if (_selectedPlayerIds.toSet().length != 4) return false;
    // Check if at least one minigame is selected
    if (_selectedMinigameNames.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text(
        'Nova partija',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Odabir igrača:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 12,
                    bottom: 16.0,
                  ),
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedPlayerIds[i],
                    isExpanded: true,
                    hint: const Text('Odaberi igrača'),
                    decoration: InputDecoration(
                      labelText: 'Igrač ${i + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: _dbPlayers
                        .where((p) {
                          final id = p['id'] as int;
                          final isSelectedElsewhere =
                              _selectedPlayerIds.contains(id) &&
                              _selectedPlayerIds[i] != id;
                          return !isSelectedElsewhere;
                        })
                        .map((p) {
                          final id = p['id'] as int;
                          final name = p['name'] as String;
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPlayerIds[i] = val;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _addNewPlayer,
                icon: const Icon(Icons.person_add),
                label: const Text('Dodaj novog igrača'),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              const Text(
                'Odabir igara:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: widget.availableMinigames.map((m) {
                  final isSelected = _selectedMinigameNames.contains(
                    m.shortName,
                  );
                  return FilterChip(
                    label: Text(m.shortName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMinigameNames.add(m.shortName);
                        } else {
                          _selectedMinigameNames.remove(m.shortName);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _canStart()
              ? () {
                  // Build players
                  final players = _selectedPlayerIds.map((id) {
                    final dbPlayer = _dbPlayers.firstWhere(
                      (p) => p['id'] == id,
                    );
                    return GamePlayer(
                      id: dbPlayer['id'] as int,
                      name: dbPlayer['name'] as String,
                    );
                  }).toList();

                  // Build minigames
                  final minigames = widget.availableMinigames
                      .where(
                        (m) => _selectedMinigameNames.contains(m.shortName),
                      )
                      .toList();

                  Navigator.pop(context, {
                    'players': players,
                    'minigames': minigames,
                  });
                }
              : null,
          child: const Text('Započni'),
        ),
      ],
    );
  }
}

class _NewPlayerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingPlayers;
  const _NewPlayerDialog({required this.existingPlayers});

  @override
  State<_NewPlayerDialog> createState() => _NewPlayerDialogState();
}

class _NewPlayerDialogState extends State<_NewPlayerDialog> {
  late final TextEditingController _nameController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novi igrač'),
      content: TextField(
        controller: _nameController,
        maxLength: 16,
        decoration: InputDecoration(labelText: 'Ime', errorText: _errorText),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final existing = widget.existingPlayers.any(
              (p) => (p['name'] as String).toLowerCase() == name.toLowerCase(),
            );
            if (existing) {
              setState(() {
                _errorText = 'Igrač s tim imenom već postoji!';
              });
              return;
            }

            Navigator.pop(context, name);
          },
          child: const Text('Dodaj'),
        ),
      ],
    );
  }
}
