import 'package:flutter/material.dart';
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

  final Map<String, Map<String, Map<String, int>>> playedGameScores = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) => _buildScoreboardPage(index),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildScoreboardPage(int activePlayerIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    final activePlayer = widget.players[activePlayerIndex];

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          activePlayer.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
              ),
              child: _buildTable(activePlayer.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(String activePlayerId) {
    final colorScheme = Theme.of(context).colorScheme;

    return Table(
      columnWidths: const {0: FixedColumnWidth(60)},
      border: TableBorder.symmetric(
        inside: BorderSide(color: colorScheme.outlineVariant),
      ),
      children: [
        TableRow(
          children: [
            const _TableCellLabel(label: "IGRA", rotated: true),
            ...widget.players.map(
              (p) => _TableCellLabel(label: p.name, rotated: true),
            ),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          children: [
            const SizedBox(height: 40),
            ...widget.players.map(
              (p) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "${p.score}",
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
        ...widget.allMinigames.map((game) {
          final roundScores = playedGameScores[activePlayerId]?[game.shortName];

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  game.shortName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...widget.players.map((p) {
                final score = roundScores?[p.id];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      score != null ? "$score" : "-",
                      style: TextStyle(
                        fontWeight: score != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: score == null
                            ? colorScheme.onSurfaceVariant
                            : (score >= 0 ? Colors.green : Colors.red),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease,
                  ),
                )
              : const SizedBox(width: 48),
          ElevatedButton(onPressed: () {}, child: const Text("NOVA IGRA")),
          _currentPage < widget.players.length - 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease,
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
