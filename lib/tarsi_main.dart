import 'package:flutter/material.dart';
import 'package:myapp/tarsi/screens/plan_screen.dart';

void main() {
  runApp(const TarsiApp());
}

class TarsiApp extends StatelessWidget {
  const TarsiApp({super.key});

  static const _background = Color(0xFFF7F8F6);
  static const _green = Color(0xFF39745A);
  static const _ink = Color(0xFF202521);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarsi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          surface: _background,
          onSurface: _ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
          ),
          titleMedium: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF707771),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
      home: const PlanScreen(),
    );
  }
}
