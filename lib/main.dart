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
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        _themeMode = ThemeMode.light;
      } else if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
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
