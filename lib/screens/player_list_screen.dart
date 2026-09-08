import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/game_cache.dart';
import '../widgets/settings_modal.dart';
import '../widgets/empty_state_placeholder.dart';

class PlayerListScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const PlayerListScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final playersRaw = await DatabaseHelper.instance.getPlayerStats();
    final activeGames = await GameCache.loadAllActiveGames();

    final List<Map<String, dynamic>> players = [];
    for (var p in playersRaw) {
      final pId = p['id'] as int;
      final pName = p['name'] as String;
      int activeCount = 0;
      for (var g in activeGames) {
        final playersList = g['players'] as List? ?? [];
        if (playersList.any(
          (player) =>
              player is Map && (player['id'] == pId || player['name'] == pName),
        )) {
          activeCount++;
        }
      }
      final dbGames = p['num_games_played'] as int? ?? 0;
      final totalCount = dbGames + activeCount;
      players.add({...p, 'total_games': totalCount});
    }

    if (mounted) {
      setState(() {
        _players = players;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewPlayer() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewPlayerDialog(existingPlayers: _players),
    );

    if (name == null || name.isEmpty) return;

    await DatabaseHelper.instance.insertPlayer(name);
    _loadPlayers();
  }

  Future<void> _confirmDeletePlayer(
    int playerId,
    String playerName,
    int gameCount,
  ) async {
    final String warningText = gameCount > 0
        ? 'Brisanjem igrača "$playerName" obrisat će se i ${gameCount == 1 ? '1 partija' : 'sve $gameCount partije'} u kojima je sudjelovao.'
        : 'Jeste li sigurni da želite obrisati igrača "$playerName"?';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati igrača?'),
        content: Text(warningText),
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
      await DatabaseHelper.instance.deletePlayer(playerId);
      await GameCache.removeActiveGamesWithPlayer(
        playerId,
        playerName: playerName,
      );
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Igrači'),
        actions: [
          IconButton(
            onPressed: () => showSettingsModal(
              context,
              themeMode: widget.themeMode,
              onThemeToggle: widget.onThemeToggle,
              onDataCleared: _loadPlayers,
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPlayer,
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _players.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  EmptyStatePlaceholder(
                    icon: Icons.people_outline,
                    title: 'Nema dodanih igrača',
                    subtitle: 'Pritisni + za novog igrača',
                    actionIcon: Icons.person_add,
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: _loadPlayers,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    return _buildPlayerCard(
                      _players[index],
                      colorScheme,
                      textTheme,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildPlayerCard(
    Map<String, dynamic> player,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final name = player['name'] as String;
    final id = player['id'] as int;
    final dbGames = player['num_games_played'] as int? ?? 0;
    final totalGames = player['total_games'] as int? ?? 0;
    final numWins = player['num_wins'] as int? ?? 0;
    final avgPoints = player['avg_points'] as num? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(
          name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Partije: $dbGames   '
          'Pobjede: $numWins   '
          'Prosjek: ${avgPoints.toStringAsFixed(1)}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () => _confirmDeletePlayer(id, name, totalGames),
        ),
      ),
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
