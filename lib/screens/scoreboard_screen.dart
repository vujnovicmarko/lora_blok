import 'package:flutter/material.dart';
import 'add_minigame_screen.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';

class ScoreboardScreen extends StatefulWidget {
  final List<GamePlayer> players;
  final List<Minigame> allMinigames;

  const ScoreboardScreen({
    super.key,
    required this.players,
    required this.allMinigames,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Minigame> _playedMinigames = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, int> _getCurrentTotals(int callerIndex) {
    Map<String, int> scores = {for (var p in widget.players) p.id: 0};
    int maxGamesToCount = callerIndex * widget.allMinigames.length;

    for (int i = 0; i < maxGamesToCount && i < _playedMinigames.length; i++) {
      for (var p in widget.players) {
        scores[p.id] = scores[p.id]! + (_playedMinigames[i].results[p.id] ?? 0);
      }
    }
    return scores;
  }

  Future<void> _openAddMinigameScreen() async {
    final int gamesPerPlayer = widget.allMinigames.length;
    final int totalPlayed = _playedMinigames.length;

    final int callerIndex = totalPlayed ~/ gamesPerPlayer;
    final caller = widget.players[callerIndex];

    final playedByThisPlayer = _playedMinigames
        .where((m) => m.callerId == caller.id)
        .toList();

    final Minigame? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMinigameScreen(
          players: widget.players,
          allMinigames: widget.allMinigames,
          playedByThisPlayer: playedByThisPlayer,
          caller: caller,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _playedMinigames.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.players.length,
          allowImplicitScrolling: true,
          physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) => _buildScoreboardPage(index),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildScoreboardPage(int callerIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    final caller = widget.players[callerIndex];

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          caller.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildTable(callerIndex),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTable(int callerIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    final int gamesPerPlayer = widget.allMinigames.length;

    Map<String, int> currentTotals = _getCurrentTotals(callerIndex);
    int startIndex = callerIndex * gamesPerPlayer;
    List<Minigame> pageGames = [];
    for (
      int i = startIndex;
      i < startIndex + gamesPerPlayer && i < _playedMinigames.length;
      i++
    ) {
      pageGames.add(_playedMinigames[i]);
    }

    List<TableRow> rows = [];

    rows.add(
      TableRow(
        children: [
          const _TableCellLabel(label: "IGRA", rotated: true),
          ...widget.players.map(
            (p) => _TableCellLabel(label: p.name, rotated: true),
          ),
        ],
      ),
    );

    rows.add(
      TableRow(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "START",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ...widget.players.map(
            (p) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "${currentTotals[p.id]}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    for (int i = 0; i < gamesPerPlayer; i++) {
      if (i < pageGames.length) {
        final game = pageGames[i];

        for (var p in widget.players) {
          currentTotals[p.id] =
              currentTotals[p.id]! + (game.results[p.id] ?? 0);
        }

        rows.add(
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 20.0,
                ),
                child: Text(
                  game.shortName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...widget.players.map((p) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "${currentTotals[p.id]}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      } else {
        rows.add(
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                child: Text(""),
              ),
              ...widget.players.map((p) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(""),
                  ),
                );
              }),
            ],
          ),
        );
      }
    }

    return Table(
      columnWidths: const {0: FixedColumnWidth(80.0)},
      border: TableBorder.all(color: colorScheme.outline),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                  ),
                )
              : const SizedBox(width: 48),
          FilledButton(
            onPressed: () => _openAddMinigameScreen(),
            child: const Text("NOVA IGRA"),
          ),
          _currentPage < widget.players.length - 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                  ),
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TableCellLabel extends StatelessWidget {
  final String label;
  final bool rotated;

  const _TableCellLabel({required this.label, this.rotated = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      alignment: Alignment.center,
      child: rotated
          ? RotatedBox(
              quarterTurns: 3,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            )
          : Text(label, style: TextStyle(color: colorScheme.onSurface)),
    );
  }
}
