import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';
import '../models/slag.dart';
import '../utils/app_sizes.dart';
import '../widgets/player_names_row.dart';
import '../widgets/score_selector_row.dart';
import '../widgets/game_selector.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p24),
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
                const SizedBox(height: AppSizes.p16),
                GameSelector(
                  allMinigames: widget.allMinigames,
                  playedByThisPlayer: widget.playedByThisPlayer,
                  selectedMinigame: _selectedMinigame,
                  initialMinigame: widget.initialMinigame,
                  onSelected: _onMinigameSelected,
                ),
                const SizedBox(height: AppSizes.p32),

                if (_selectedMinigame != null) ...[
                  Text(
                    _selectedMinigame!.fullName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  PlayerNamesRow(players: widget.players),
                  const SizedBox(height: AppSizes.p8),
                  ScoreSelectorRow(
                    players: widget.players,
                    values: _tempResults,
                    allowedScores: _selectedMinigame!.allowedScores,
                    onChanged: (playerId, newValue) {
                      setState(() {
                        _tempResults[playerId] = newValue;
                      });
                    },
                  ),

                  if (_selectedMinigame is Slag) ...[
                    const SizedBox(height: AppSizes.p32),
                    Text(
                      'Fućkanje',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                    PlayerNamesRow(players: widget.players),
                    const SizedBox(height: AppSizes.p8),
                    ScoreSelectorRow(
                      players: widget.players,
                      values: _tempWhistles,
                      allowedScores: null, // null indicates 0-12 range for whistles
                      onChanged: (playerId, newValue) {
                        setState(() {
                          _tempWhistles[playerId] = newValue;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: AppSizes.p32),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _selectedMinigame != null
          ? _buildSaveButton(colorScheme)
          : null,
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
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
