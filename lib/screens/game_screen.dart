import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../model/cup_model.dart';
import '../widgets/cup_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final int cupCount = 5;
  int currentStage = 1;
  int? ballId; // 공이 든 컵의 고유 ID
  late List<CupModel> cups;

  bool isPreparing = true;
  bool isShuffling = false;
  bool isOpened = false;
  int? userSelectedId;

  @override
  void initState() {
    super.initState();
    _initStage();
  }

  void _initStage() {
    ballId = null;
    userSelectedId = null;
    isPreparing = true;
    isShuffling = false;
    isOpened = false;
    // 컵들을 0~4번 위치에 초기화
    cups = List.generate(cupCount, (i) => CupModel(id: i, currentSlot: i));
  }

  void _setBall(int id) {
    setState(() {
      ballId = id;
      isPreparing = false;
    });
    Future.delayed(const Duration(milliseconds: 800), _startShuffle);
  }

  Future<void> _startShuffle() async {
    setState(() => isShuffling = true);

    int shuffleCount = 5 + (currentStage * 3);
    int speedMs = max(150, 600 - (currentStage * 45));

    final random = Random();
    for (int i = 0; i < shuffleCount; i++) {
      int idx1 = random.nextInt(cupCount);
      int idx2 = random.nextInt(cupCount);
      while (idx1 == idx2) idx2 = random.nextInt(cupCount);

      await Future.delayed(Duration(milliseconds: speedMs));
      if (!mounted) return;

      setState(() {
        // 두 컵의 슬롯(위치)만 교체
        int tempSlot = cups[idx1].currentSlot;
        cups[idx1].currentSlot = cups[idx2].currentSlot;
        cups[idx2].currentSlot = tempSlot;
      });
    }

    setState(() => isShuffling = false);
  }

  void _handleCupTap(int id) {
    if (isPreparing || isShuffling || isOpened) return;
    setState(() {
      userSelectedId = id;
      isOpened = true;
    });

    if (id == ballId) {
      currentStage == 10 ? _showDialog("🏆 챔피언!", "정복 완료!", true) : _showDialog("🎉 Clear!", "$currentStage단계 통과!", false);
    } else {
      _showDialog("💥 Game Over", "$currentStage단계에서 탈락!", true);
    }
  }

  void _showDialog(String title, String content, bool resetAll) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (resetAll) {
                  currentStage = 1;
                } else {
                  currentStage++;
                }
                _initStage();
              });
            },
            child: Text(resetAll ? "다시 시작" : "다음 단계로"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cupWidth = (screenWidth - 60) / cupCount;

    return Scaffold(
      appBar: AppBar(
        title: Text("STAGE $currentStage / 10"),
        centerTitle: true,
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: currentStage / 10, color: Colors.redAccent),
          const Spacer(),
          Text(isPreparing ? "공을 넣으세요" : (isShuffling ? "눈 크게 뜨세요!" : "찾아보세요!"),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          SizedBox(
            height: 250,
            child: Stack(
              children: cups.map((cup) {
                return AnimatedPositioned(
                  duration: Duration(milliseconds: max(100, 500 - (currentStage * 40))),
                  curve: Curves.easeInOut,
                  left: 30 + (cup.currentSlot * cupWidth),
                  top: (isPreparing || (isOpened && userSelectedId == cup.id)) ? 50 : (isShuffling ? 90 : 130),
                  child: GestureDetector(
                    onTap: () => isPreparing ? _setBall(cup.id) : _handleCupTap(cup.id),
                    child: SizedBox(
                      width: cupWidth,
                      child: CupWidget(
                        size: cupWidth * 0.9,
                        isOpened: isOpened || isPreparing,
                        hasBall: ballId == cup.id,
                        isSelected: userSelectedId == cup.id,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}