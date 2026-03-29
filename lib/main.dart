import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async{
  // Flutter 엔진과 비동기 통신 준비
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: WhereIsBallApp(),
    ),
  );
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