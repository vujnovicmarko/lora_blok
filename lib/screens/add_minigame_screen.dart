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

  const AddMinigameScreen({
    super.key,
    required this.players,
    required this.allMinigames,
    required this.playedByThisPlayer,
    required this.caller,
  });

  @override
  State<AddMinigameScreen> createState() => _AddMinigameScreenState();
}

class _AddMinigameScreenState extends State<AddMinigameScreen> {
  Minigame? _selectedMinigame;

  final Map<String, int> _tempResults = {};
  final Map<String, int> _tempWhistles = {};

  void _onMinigameSelected(Minigame game) {
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

    return Scaffold(
      appBar: AppBar(title: const Text("Nova igra")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Odaberi igru:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildGameSelector(),
              const SizedBox(height: 30),

              if (_selectedMinigame != null) ...[
                Text(
                  _selectedMinigame!.fullName,
                  style: TextStyle(
                    fontSize: 20,
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
                    "FUĆKANJE",
                    style: TextStyle(
                      fontSize: 20,
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
      bottomNavigationBar: _selectedMinigame != null
          ? _buildSaveButton()
          : null,
    );
  }

  Widget _buildPlayerNamesRow() {
    return Row(
      children: widget.players.map((player) {
        return Expanded(
          child: Text(
            player.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreSelectorsRow() {
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
                "$currentScore",
                style: const TextStyle(
                  fontSize: 22,
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
                "$count",
                style: const TextStyle(
                  fontSize: 22,
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
        bool isPlayed = widget.playedByThisPlayer.any(
          (p) => p.shortName == game.shortName,
        );
        bool isSelected = _selectedMinigame?.shortName == game.shortName;
        return ChoiceChip(
          label: Text(game.shortName),
          selected: isSelected,
          onSelected: isPlayed ? null : (val) => _onMinigameSelected(game),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FilledButton(
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
          child: const Text(
            "SPREMI",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
