import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_minigame_screen.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';
import '../widgets/scoreboard_table.dart';
import '../widgets/game_over_dialog.dart';
import '../database/game_cache.dart';

class ScoreboardScreen extends StatefulWidget {
  final String gameId;
  final List<GamePlayer> players;
  final List<Minigame> allMinigames;
  final List<Minigame>? resumePlayedMinigames;
  final int? resumeCurrentPage;

  final bool isReadOnly;

  const ScoreboardScreen({
    super.key,
    required this.gameId,
    required this.players,
    required this.allMinigames,
    this.resumePlayedMinigames,
    this.resumeCurrentPage,
    this.isReadOnly = false,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late PageController _pageController;
  var _currentPage = 0;
  final List<Minigame> _playedMinigames = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();

    if (widget.resumePlayedMinigames != null) {
      _playedMinigames.addAll(widget.resumePlayedMinigames!);
      _currentPage = widget.resumeCurrentPage ?? 0;
    }

    _pageController = PageController(initialPage: _currentPage);

    if (!widget.isReadOnly && _playedMinigames.isEmpty) {
      _cacheGameState();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cacheGameState() async {
    if (widget.isReadOnly || _isFinished) return;
    final allMinigameTypes = widget.allMinigames.map((m) => m.shortName).toList();
    await GameCache.saveGameState(
      id: widget.gameId,
      players: widget.players,
      playedMinigames: _playedMinigames,
      allMinigameTypes: allMinigameTypes,
      currentPage: _currentPage,
    );
  }

  Map<int, int> _getCurrentTotals(int callerIndex) {
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
    if (widget.isReadOnly) return;
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
      await _cacheGameState();
    }
  }

  Future<void> _openAddMinigameScreen() async {
    if (widget.isReadOnly) return;
    
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

      await _cacheGameState();

      if (_playedMinigames.length == totalRequired) {
        _showGameOverDialog();
      }
    }
  }

  Future<void> _showGameOverDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.gameId,
        players: widget.players,
        playedMinigames: _playedMinigames,
      ),
    );

    if (result == true) {
      _isFinished = true;
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !widget.isReadOnly && !_isFinished) {
          await _cacheGameState();
        }
      },
      child: Scaffold(
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
      ),
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
                        isReadOnly: widget.isReadOnly,
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
    if (widget.isReadOnly) {
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
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 40)),
              child: const Text("Početni zaslon"),
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
