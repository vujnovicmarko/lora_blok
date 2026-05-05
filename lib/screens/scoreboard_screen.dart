import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  var _currentPage = 0;
  final List<Minigame> _playedMinigames = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, int> _getCurrentTotals(int callerIndex) {
    final scores = {for (var p in widget.players) p.id: 0};
    final maxGamesToCount = callerIndex * widget.allMinigames.length;

    for (int i = 0; i < maxGamesToCount && i < _playedMinigames.length; i++) {
      for (var p in widget.players) {
        scores[p.id] = scores[p.id]! + (_playedMinigames[i].results[p.id] ?? 0);
      }
    }
    return scores;
  }

  Future<void> _editMinigame(
    Minigame game,
    int globalIndex,
    GamePlayer caller,
  ) async {
    HapticFeedback.heavyImpact();

    final playedByThisPlayer = _playedMinigames
        .where((m) => m.callerId == caller.id)
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMinigameScreen(
          players: widget.players,
          allMinigames: widget.allMinigames,
          playedByThisPlayer: playedByThisPlayer,
          caller: caller,
          initialMinigame: game,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _playedMinigames[globalIndex] = result;
      });
    }
  }

  Future<void> _openAddMinigameScreen() async {
    final gamesPerPlayer = widget.allMinigames.length;
    final totalRequired = widget.players.length * gamesPerPlayer;

    if (_playedMinigames.length >= totalRequired) {
      _showGameOverDialog();
      return;
    }

    final callerIndex = _playedMinigames.length ~/ gamesPerPlayer;
    final caller = widget.players[callerIndex];

    final playedByThisPlayer = _playedMinigames
        .where((m) => m.callerId == caller.id)
        .toList();

    final result = await Navigator.push(
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

        if (_currentPage != callerIndex) {
          _pageController.animateToPage(
            callerIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      });

      if (_playedMinigames.length == totalRequired) {
        _showGameOverDialog();
      }
    }
  }

  void _showGameOverDialog() {
    final textTheme = Theme.of(context).textTheme;

    final finalScores = {for (var p in widget.players) p.id: 0};
    for (var game in _playedMinigames) {
      for (var p in widget.players) {
        finalScores[p.id] = finalScores[p.id]! + (game.results[p.id] ?? 0);
      }
    }

    final sortedPlayers = List.from(widget.players);
    sortedPlayers.sort(
      (a, b) => finalScores[a.id]!.compareTo(finalScores[b.id]!),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Center(
            child: Text(
              "Partija završena!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                ...sortedPlayers.asMap().entries.map((entry) {
                  int rank = entry.key + 1;
                  GamePlayer p = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$rank. ${p.name}",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: rank == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          "${finalScores[p.id]}",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: rank == 1
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                const Divider(),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tablica"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
              ),
              child: const Text("Početna"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    final caller = widget.players[callerIndex];
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          caller.name.toUpperCase(),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
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
    final gamesPerPlayer = widget.allMinigames.length;
    final totalColumns = widget.players.length + 1;
    final caller = widget.players[callerIndex];

    final currentTotals = _getCurrentTotals(callerIndex);
    final startIndex = callerIndex * gamesPerPlayer;
    final pageGames = [];
    final List<TableRow> rows = [];

    for (
      var i = startIndex;
      i < startIndex + gamesPerPlayer && i < _playedMinigames.length;
      i++
    ) {
      pageGames.add(_playedMinigames[i]);
    }

    rows.add(
      TableRow(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
        children: [
          _buildCenteredCell("IGRA", isBold: true),
          ...widget.players.map(
            (p) => _buildCenteredCell(p.name.toUpperCase(), isBold: true),
          ),
        ],
      ),
    );

    rows.add(
      TableRow(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
        children: [
          _buildCenteredCell("START", isBold: true),
          ...widget.players.map(
            (p) => _buildCenteredCell(
              "${currentTotals[p.id]}",
              isBold: true,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );

    for (var i = 0; i < gamesPerPlayer; i++) {
      if (i < pageGames.length) {
        final game = pageGames[i];
        final globalIndex = startIndex + i;
        final isLastRow = globalIndex == _playedMinigames.length - 1;

        List<Widget> rowCells = [
          _buildClickableCell(
            game.shortName,
            () => _editMinigame(game, globalIndex, caller),
            isBold: true,
          ),
        ];

        for (var p in widget.players) {
          final int delta = game.results[p.id] ?? 0;
          currentTotals[p.id] = currentTotals[p.id]! + delta;

          String? deltaStr;
          Color? deltaCol;

          if (isLastRow) {
            if (delta > 0) {
              deltaStr = " (+$delta)";
              deltaCol = colorScheme.error;
            } else if (delta < 0) {
              deltaStr = " ($delta)";
              deltaCol = colorScheme.primary;
            } else {
              deltaStr = " (0)";
              deltaCol = colorScheme.onSurface;
            }
          }

          rowCells.add(
            _buildClickableCell(
              "${currentTotals[p.id]}",
              () => _editMinigame(game, globalIndex, caller),
              deltaText: deltaStr,
              deltaColor: deltaCol,
            ),
          );
        }

        rows.add(TableRow(children: rowCells));
      } else {
        rows.add(
          TableRow(
            children: List.generate(
              totalColumns,
              (_) => _buildCenteredCell(""),
            ),
          ),
        );
      }
    }

    return Table(
      defaultColumnWidth: FractionColumnWidth(1.0 / totalColumns),
      border: TableBorder.all(color: colorScheme.outline),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _buildClickableCell(
    String text,
    VoidCallback onLongPress, {
    bool isBold = false,
    String? deltaText,
    Color? deltaColor,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: _buildCenteredCell(
        text,
        isBold: isBold,
        deltaText: deltaText,
        deltaColor: deltaColor,
      ),
    );
  }

  Widget _buildCenteredCell(
    String text, {
    bool isBold = false,
    Color? color,
    String? deltaText,
    Color? deltaColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    final baseStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Text.rich(
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: text),
              if (deltaText != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Text(
                    deltaText,
                    style: textTheme.bodySmall?.copyWith(color: deltaColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final gamesPerPlayer = widget.allMinigames.length;
    final totalRequired = widget.players.length * gamesPerPlayer;
    final isGameOver = _playedMinigames.length >= totalRequired;

    return BottomAppBar(
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
            style: FilledButton.styleFrom(minimumSize: const Size(200, 40)),
            child: Text(isGameOver ? "Završi partiju" : "Nova igra"),
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
