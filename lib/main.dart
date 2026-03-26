import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const WhereIsBallApp());
}

class WhereIsBallApp extends StatelessWidget {
  const WhereIsBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trick?',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}