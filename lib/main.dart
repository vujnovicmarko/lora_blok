import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/player_list_screen.dart' as player_list;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoraBlok());
}

class LoraBlok extends StatefulWidget {
  const LoraBlok({super.key});

  @override
  State<LoraBlok> createState() => _LoraBlokState();
}

class _LoraBlokState extends State<LoraBlok> {
  var _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    _themeMode = brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.dark)
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lora Blok',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF98BB6c),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF98BB6c),
        brightness: Brightness.dark,
      ),
      home: MainLayout(themeMode: _themeMode, onThemeToggle: _toggleTheme),
    );
  }
}

class MainLayout extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const MainLayout({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          key: const ValueKey(0),
          themeMode: widget.themeMode,
          onThemeToggle: widget.onThemeToggle,
        );
      case 1:
        return player_list.PlayerListScreen(
          key: const ValueKey(1),
          themeMode: widget.themeMode,
          onThemeToggle: widget.onThemeToggle,
        );
      default:
        return HomeScreen(
          key: const ValueKey(0),
          themeMode: widget.themeMode,
          onThemeToggle: widget.onThemeToggle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildScreen(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: _BounceIcon(
              icon: Icons.sports_esports,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Partije',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: _BounceIcon(
              icon: Icons.people,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Igrači',
          ),
        ],
      ),
    );
  }
}

class _BounceIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _BounceIcon({required this.icon, required this.color});

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon, color: widget.color),
    );
  }
}
