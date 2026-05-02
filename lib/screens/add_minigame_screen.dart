import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/minigame.dart';
import '../models/game_player.dart';

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

  @override
  void initState() {
    super.initState();
    for (var p in widget.players) {
      _tempResults[p.id] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("NOVA IGRA")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ODABERI IGRU:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildGameSelector(),
              const SizedBox(height: 30),
              if (_selectedMinigame != null) ...[
                Center(
                  child: Text(
                    _selectedMinigame!.fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildScorePickers(),
                const SizedBox(height: 40),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.allMinigames.map((game) {
        bool isPlayed = widget.playedByThisPlayer.any(
          (p) => p.shortName == game.shortName,
        );
        bool isSelected = _selectedMinigame?.shortName == game.shortName;

        return ChoiceChip(
          label: Text(game.shortName),
          selected: isSelected,
          onSelected: isPlayed
              ? null
              : (selected) {
                  setState(() {
                    _selectedMinigame = game;
                  });
                },
        );
      }).toList(),
    );
  }

  Widget _buildScorePickers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.players.map((player) {
        return Column(
          children: [
            Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              width: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _tempResults[player.id] =
                        index - 8; // Offset za range -8 do 12
                  });
                  HapticFeedback.selectionClick();
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    int val = index - 8;
                    if (val < -8 || val > 16) return null;
                    return Center(
                      child: Text(
                        "$val",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: _tempResults[player.id] == val
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          padding: const EdgeInsets.all(15),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: FilledButton(
            onPressed: () {
              if (_selectedMinigame != null) {
                final minigame = _selectedMinigame!.copyWith(
                  results: Map<String, int>.from(_tempResults),
                  callerId: widget.caller.id,
                );

                Navigator.pop(context, minigame);
              }
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(15)),
            child: const Text("SPREMI"),
          ),
        ),
      ],
    );
  }
}
