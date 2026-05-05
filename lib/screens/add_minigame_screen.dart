import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';
import '../models/slag.dart';

class AddMinigameScreen extends StatefulWidget {
  final List<GamePlayer> players;
  final List<Minigame> allMinigames;
  final List<Minigame> playedByThisPlayer;
  final GamePlayer caller;
  final Minigame? initialMinigame;

  const AddMinigameScreen({
    super.key,
    required this.players,
    required this.allMinigames,
    required this.playedByThisPlayer,
    required this.caller,
    this.initialMinigame,
  });

  @override
  State<AddMinigameScreen> createState() => _AddMinigameScreenState();
}

class _AddMinigameScreenState extends State<AddMinigameScreen> {
  Minigame? _selectedMinigame;
  var _isEditing = false;

  final Map<String, int> _tempResults = {};
  final Map<String, int> _tempWhistles = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialMinigame != null) {
      _isEditing = true;
      _loadInitialData(widget.initialMinigame!);
    }
  }

  void _loadInitialData(Minigame game) {
    setState(() {
      _selectedMinigame = game;
      for (var p in widget.players) {
        if (game is Slag) {
          _tempResults[p.id] = game.basePoints[p.id] ?? 0;
          _tempWhistles[p.id] = game.whistles[p.id] ?? 0;
        } else {
          _tempResults[p.id] = game.results[p.id] ?? 0;
          _tempWhistles[p.id] = 0;
        }
      }
    });
  }

  void _onMinigameSelected(Minigame game) {
    if (_selectedMinigame?.shortName == game.shortName) return;

    setState(() {
      if (game.shortName == 'SLAG') {
        _selectedMinigame = Slag(
          callerId: widget.caller.id,
          playerIds: widget.players.map((p) => p.id).toList(),
        );
      } else {
        _selectedMinigame = game;
      }

      final int minVal = _selectedMinigame!.allowedScores.first;

      for (var p in widget.players) {
        _tempResults[p.id] = minVal;
        _tempWhistles[p.id] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Uredi igru' : 'Nova igra')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Odaberi igru:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildGameSelector(),
                const SizedBox(height: 30),

                if (_selectedMinigame != null) ...[
                  Text(
                    _selectedMinigame!.fullName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlayerNamesRow(),
                  const SizedBox(height: 10),
                  _buildScoreSelectorsRow(),

                  if (_selectedMinigame is Slag) ...[
                    const SizedBox(height: 50),
                    Text(
                      'Fućkanje',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPlayerNamesRow(),
                    const SizedBox(height: 10),
                    _buildWhistlesRow(),
                  ],
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _selectedMinigame != null
          ? _buildSaveButton()
          : null,
    );
  }

  Widget _buildPlayerNamesRow() {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: widget.players.map((player) {
        return Expanded(
          child: Text(
            player.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreSelectorsRow() {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: widget.players.map((player) {
        int currentScore =
            _tempResults[player.id] ?? _selectedMinigame!.allowedScores.first;
        int currentIndex = _selectedMinigame!.allowedScores.indexOf(
          currentScore,
        );

        return Expanded(
          child: Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                onPressed:
                    currentIndex < _selectedMinigame!.allowedScores.length - 1
                    ? () {
                        setState(() {
                          _tempResults[player.id] = _selectedMinigame!
                              .allowedScores[currentIndex + 1];
                        });
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
              Text(
                '$currentScore',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: currentIndex > 0
                    ? () {
                        setState(() {
                          _tempResults[player.id] = _selectedMinigame!
                              .allowedScores[currentIndex - 1];
                        });
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWhistlesRow() {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: widget.players.map((player) {
        int count = _tempWhistles[player.id] ?? 0;
        return Expanded(
          child: Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                onPressed: count < 12
                    ? () {
                        setState(() => _tempWhistles[player.id] = count + 1);
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
              Text(
                '$count',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: count > 0
                    ? () {
                        setState(() => _tempWhistles[player.id] = count - 1);
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: widget.allMinigames.map((game) {
        bool isAlreadyPlayed = widget.playedByThisPlayer.any(
          (p) => p.shortName == game.shortName,
        );
        bool isSelected = _selectedMinigame?.shortName == game.shortName;
        bool isCurrentEditTarget =
            widget.initialMinigame?.shortName == game.shortName;

        bool isDisabled = isAlreadyPlayed && !isCurrentEditTarget;

        return ChoiceChip(
          label: Text(game.shortName),
          selected: isSelected,
          onSelected: isDisabled
              ? null
              : (val) {
                  if (val) _onMinigameSelected(game);
                },
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(200, 40)),
            onPressed: () {
              if (_selectedMinigame == null) return;
              Minigame finalGame;

              if (_selectedMinigame is Slag) {
                final slagGame = _selectedMinigame as Slag;
                Map<String, int> calculatedResults = {};
                for (var p in widget.players) {
                  calculatedResults[p.id] =
                      (_tempResults[p.id] ?? 0) + (_tempWhistles[p.id] ?? 0);
                }
                finalGame = Slag(
                  callerId: widget.caller.id,
                  playerIds: slagGame.playerIds,
                  basePoints: Map<String, int>.from(_tempResults),
                  whistles: Map<String, int>.from(_tempWhistles),
                  results: calculatedResults,
                );
              } else {
                finalGame = _selectedMinigame!.copyWith(
                  callerId: widget.caller.id,
                  results: Map<String, int>.from(_tempResults),
                );
              }

              if (!finalGame.validateResults(finalGame.results)) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(finalGame.validationErrorMessage),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(context, finalGame);
            },
            child: Text(_isEditing ? 'Ažuriraj' : 'Spremi'),
          ),
        ],
      ),
    );
  }
}
