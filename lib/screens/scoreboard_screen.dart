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

  Future<void> _editMinigame(
    Minigame game,
    int globalIndex,
    GamePlayer caller,
  ) async {
    HapticFeedback.heavyImpact();

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
    final int gamesPerPlayer = widget.allMinigames.length;
    final int totalPlayed = _playedMinigames.length;

    if (totalPlayed >= widget.players.length * gamesPerPlayer) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sve igre su završene!")));
      return;
    }

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

        if (_currentPage != callerIndex) {
          _pageController.animateToPage(
            callerIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
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
    final int gamesPerPlayer = widget.allMinigames.length;
    final int totalColumns = widget.players.length + 1;
    final caller = widget.players[callerIndex];

    Map<String, int> currentTotals = _getCurrentTotals(callerIndex);
    int startIndex = callerIndex * gamesPerPlayer;
    List<Minigame> pageGames = [];
    List<TableRow> rows = [];

    for (
      int i = startIndex;
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
            (p) => _buildCenteredCell(p.name, isBold: true),
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

    for (int i = 0; i < gamesPerPlayer; i++) {
      if (i < pageGames.length) {
        final game = pageGames[i];
        final globalIndex = startIndex + i;
        final bool isLastRow = globalIndex == _playedMinigames.length - 1;

        List<Widget> rowCells = [
          _buildClickableCell(
            game.shortName,
            () => _editMinigame(game, globalIndex, caller),
            isBold: true,
          ),
        ];

        for (var p in widget.players) {
          int delta = game.results[p.id] ?? 0;
          currentTotals[p.id] = currentTotals[p.id]! + delta;

          String? deltaStr;
          Color? deltaCol;

          if (isLastRow) {
            if (delta > 0) {
              deltaStr = " (+$delta)";
              deltaCol = Colors.red;
            } else if (delta < 0) {
              deltaStr = " ($delta)";
              deltaCol = Colors.green;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? colorScheme.onSurface,
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: text),
              if (deltaText != null)
                TextSpan(
                  text: deltaText,
                  style: TextStyle(color: deltaColor),
                ),
            ],
          ),
        ),
      ),
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
