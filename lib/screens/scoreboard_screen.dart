import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_minigame_screen.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';
import '../widgets/scoreboard_table.dart';
import '../widgets/game_over_dialog.dart';

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

        int targetPage = callerIndex;
        if (_playedMinigames.length < totalRequired && _playedMinigames.length % gamesPerPlayer == 0) {
          targetPage = _playedMinigames.length ~/ gamesPerPlayer;
        }

        if (_currentPage != targetPage) {
          _pageController.animateToPage(
            targetPage,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        players: widget.players,
        playedMinigames: _playedMinigames,
      ),
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
                      child: ScoreboardTable(
                        callerIndex: callerIndex,
                        players: widget.players,
                        allMinigames: widget.allMinigames,
                        playedMinigames: _playedMinigames,
                        currentTotals: _getCurrentTotals(callerIndex),
                        onEditMinigame: _editMinigame,
                      ),
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
