import 'package:flutter/material.dart';
import '../models/dame.dart';
import '../models/dpp.dart';
import '../models/herc.dart';
import '../models/khzs.dart';
import '../models/manje.dart';
import '../models/minigame.dart';
import '../models/prog.dart';
import '../models/slag.dart';
import '../models/vise.dart';
import '../models/game_player.dart';
import 'scoreboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GamePlayer> _players = [
    const GamePlayer(id: '1', name: 'Igrač 1'),
    const GamePlayer(id: '2', name: 'Igrač 2'),
    const GamePlayer(id: '3', name: 'Igrač 3'),
    const GamePlayer(id: '4', name: 'Igrač 4'),
  ];
  late List<Minigame> _allMinigames;

  @override
  void initState() {
    super.initState();
    _allMinigames = [
      Dpp(),
      Dame(),
      // Khzs(),
      // Herc(),
      // Manje(),
      // Vise(),
      // Prog(),
      // Slag(playerIds: _players.map((p) => p.id).toList()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partije'),
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScoreboardScreen(
                players: _players,
                allMinigames: _allMinigames,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: const SafeArea(child: Text('Temp')),
    );
  }
}
