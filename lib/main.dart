import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: LevelShellGame()));

enum GameLevel { easy, medium, hard }

class LevelShellGame extends StatefulWidget {
  const LevelShellGame({super.key});

  @override
  State<LevelShellGame> createState() => _LevelShellGameState();
}

class _LevelShellGameState extends State<LevelShellGame> {
  final int cupCount = 5;
  int? ballIndex;
  late List<int> displayOrder;

  GameLevel? selectedLevel; // 현재 선택된 난이도
  bool isPreparing = false;
  bool isShuffling = false;
  bool isOpened = false;
  int? userSelectedIndex;

  @override
  void initState() {
    super.initState();
    displayOrder = List.generate(cupCount, (index) => index);
  }

  // 게임 초기화 (난이도 선택 화면으로 이동)
  void _resetToHome() {
    setState(() {
      selectedLevel = null;
      ballIndex = null;
      isPreparing = false;
      isShuffling = false;
      isOpened = false;
      userSelectedIndex = null;
      displayOrder = List.generate(cupCount, (index) => index);
    });
  }

  // 난이도 선택 후 공 넣기 단계로 진입
  void _selectLevel(GameLevel level) {
    setState(() {
      selectedLevel = level;
      isPreparing = true;
    });
  }

  // 공 넣기
  void _setBall(int index) {
    setState(() {
      ballIndex = index;
      isPreparing = false;
    });
    Future.delayed(const Duration(milliseconds: 1000), () => _startShuffle());
  }

  // 난이도별 섞기 로직
  Future<void> _startShuffle() async {
    setState(() => isShuffling = true);

    int count;
    Duration speed;

    // 난이도별 설정
    switch (selectedLevel!) {
      case GameLevel.easy:
        count = 8;
        speed = const Duration(milliseconds: 700); // 아주 느림
        break;
      case GameLevel.medium:
        count = 15;
        speed = const Duration(milliseconds: 400); // 중간
        break;
      case GameLevel.hard:
        count = 25;
        speed = const Duration(milliseconds: 200); // 매우 빠름
        break;
    }

    for (int i = 0; i < count; i++) {
      int idx1 = Random().nextInt(cupCount);
      int idx2 = Random().nextInt(cupCount);
      while (idx1 == idx2) idx2 = Random().nextInt(cupCount);

      await Future.delayed(speed);
      setState(() {
        int temp = displayOrder[idx1];
        displayOrder[idx1] = displayOrder[idx2];
        displayOrder[idx2] = temp;
      });
    }

    setState(() => isShuffling = false);
  }

  void _onCupTap(int index) {
    if (isShuffling || isOpened || isPreparing) return;
    setState(() {
      userSelectedIndex = index;
      isOpened = true;
    });
    _showResult(index == ballIndex);
  }

  void _showResult(bool win) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(win ? "🎉 성공!" : "💥 실패!"),
        content: Text(win ? "정답입니다!" : "공은 다른 곳에 있었네요."),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _resetToHome(); }, child: const Text("처음으로")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 초기 난이도 선택 화면
    if (selectedLevel == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("The Trick"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("난이도를 선택하세요", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _levelButton("하 (천천히)", Colors.green, GameLevel.easy),
              _levelButton("중 (보통)", Colors.orange, GameLevel.medium),
              _levelButton("상 (빠르게)", Colors.red, GameLevel.hard),
            ],
          ),
        ),
      );
    }

    // 2. 게임 실행 화면
    double screenWidth = MediaQuery.of(context).size.width;
    double cupSize = (screenWidth - 60) / cupCount;

    return Scaffold(
      appBar: AppBar(
        title: Text("${selectedLevel == GameLevel.easy ? '하' : selectedLevel == GameLevel.medium ? '중' : '상'} 난이도"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _resetToHome),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isPreparing ? "공을 넣을 컵을 선택하세요" : (isShuffling ? "섞는 중..." : "공을 찾으세요!"),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 80),
          SizedBox(
            height: 200,
            child: Stack(
              children: List.generate(cupCount, (index) {
                int currentPos = displayOrder[index];
                return AnimatedPositioned(
                  duration: _getDuration(),
                  curve: Curves.easeInOut,
                  left: 30 + (currentPos * cupSize),
                  top: (isPreparing || (isOpened && userSelectedIndex == index)) ? 50 : (isShuffling ? 90 : 130),
                  child: GestureDetector(
                    onTap: () => isPreparing ? _setBall(index) : _onCupTap(index),
                    child: SizedBox(
                      width: cupSize,
                      child: Column(
                        children: [
                          Icon(Icons.local_cafe, size: cupSize * 0.9, color: Colors.brown[600]),
                          if (ballIndex == index && (isOpened || isPreparing))
                            const Icon(Icons.circle, color: Colors.red, size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelButton(String label, Color color, GameLevel level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(200, 50)),
        onPressed: () => _selectLevel(level),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Duration _getDuration() {
    if (selectedLevel == GameLevel.easy) return const Duration(milliseconds: 600);
    if (selectedLevel == GameLevel.medium) return const Duration(milliseconds: 350);
    return const Duration(milliseconds: 180);
  }
}