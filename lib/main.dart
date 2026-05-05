import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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
      home: HomeScreen(themeMode: _themeMode, onThemeToggle: _toggleTheme),
    );
  }
}
