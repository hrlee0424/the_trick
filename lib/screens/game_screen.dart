import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../model/cup_model.dart';
import '../model/ranking_model.dart';
import '../widgets/cup_widget.dart';
import '../services/ranking_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final int cupCount = 5;
  int currentStage = 1;
  int totalScore = 0;
  int? ballId;
  late List<CupModel> cups;

  bool isPreparing = true;
  bool isShuffling = false;
  bool isOpened = false;
  bool isWaitingForAnswer = false; // [추가] 카운트다운 표시 전용 변수
  int? userSelectedId;

  DateTime? startTime;

  Timer? _roundTimer;
  int _remainingTime = 5;

  @override
  void initState() {
    super.initState();
    _initStage();
  }

  void _initStage() {
    setState(() {
      ballId = null;
      userSelectedId = null;
      isPreparing = true;
      isShuffling = false;
      isOpened = false;
      isWaitingForAnswer = false; // [추가] 초기화
      cups = List.generate(cupCount, (i) => CupModel(id: i, currentSlot: i));
    });
  }

  void _onStartGame() async {
    setState(() {
      isPreparing = false;
      ballId = Random().nextInt(cupCount);
      isOpened = true;
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    setState(() {
      isOpened = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _startShuffle();
  }

  void _startCountDown() {
    _remainingTime = 5;
    _roundTimer?.cancel();

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel();
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (isOpened) return;

    setState(() {
      isOpened = true;
      isWaitingForAnswer = false; // [추가] 타임아웃 시 false
    });

    _showNamingDialog();
  }

  Future<void> _startShuffle() async {
    setState(() => isShuffling = true);

    int shuffleCount = 5 + (currentStage * 2);
    int speedMs = max(150, 600 - (currentStage * 40));

    final random = Random();
    for (int i = 0; i < shuffleCount; i++) {
      int idx1 = random.nextInt(cupCount);
      int idx2 = random.nextInt(cupCount);
      while (idx1 == idx2) idx2 = random.nextInt(cupCount);

      await Future.delayed(Duration(milliseconds: speedMs));
      if (!mounted) return;

      setState(() {
        int tempSlot = cups[idx1].currentSlot;
        cups[idx1].currentSlot = cups[idx2].currentSlot;
        cups[idx2].currentSlot = tempSlot;
      });
    }

    setState(() {
      isShuffling = false;
      startTime = DateTime.now();
      isWaitingForAnswer = true; // [추가] 섞기 완료 후 카운트다운 활성화
    });

    _startCountDown();
  }

  void _handleCupTap(int id) {
    if (isPreparing || isShuffling || isOpened) return;

    final duration = DateTime.now().difference(startTime!);
    _roundTimer?.cancel(); // [추가] 선택 즉시 타이머 취소

    setState(() {
      userSelectedId = id;
      isOpened = true;
      isWaitingForAnswer = false; // [추가] 선택 시 카운트다운 종료
    });

    if (id == ballId) {
      int timeBonus = max(0, (5000 - duration.inMilliseconds) ~/ 5);
      int earned = (currentStage * 1000) + timeBonus;
      totalScore += earned;
      _showResultDialog("🎉 Stage Clear!", "+$earned 점 획득!", false);
    } else {
      _showNamingDialog();
    }
  }

  void _showNamingDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                ),
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🏆 GAME OVER",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const Divider(height: 30, thickness: 1.5),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    const Text("MY SCORE", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Text("$totalScore",
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown)),
                                    Text("Stage $currentStage", style: TextStyle(color: Colors.brown[300])),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: controller,
                                maxLength: 8,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "닉네임 입력",
                                  errorText: errorText,
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                                ),
                                onChanged: (val) {
                                  if (val.isNotEmpty && errorText != null) setDialogState(() => errorText = null);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.leaderboard, size: 18, color: Colors.brown[400]),
                                  const SizedBox(width: 5),
                                  const Text("TOP 10", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FutureBuilder<List<dynamic>>(
                                  future: RankingService().getTopRankers(limit: 10),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                    return ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: snapshot.data!.length,
                                      separatorBuilder: (_, __) => const Divider(height: 8),
                                      itemBuilder: (context, index) {
                                        RankingModel ranker = snapshot.data![index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 25,
                                                child: Text(
                                                  "${index + 1}",
                                                  style: TextStyle(
                                                    fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                                                    color: index < 3 ? Colors.orange[800] : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ranker.nickname,
                                                      style: TextStyle(
                                                        fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                                                        fontSize: 14,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      "Stage ${ranker.stage} 도달",
                                                      style: TextStyle(fontSize: 10, color: Colors.brown[300]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                "${ranker.score}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () { Navigator.pop(ctx); _resetToHome(); },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("다시 하기", style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (controller.text.trim().isEmpty) {
                                setDialogState(() => errorText = "입력 필수!");
                                return;
                              }
                              await RankingService().saveScore(controller.text.trim(), totalScore, currentStage);
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              _resetToHome();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.brown,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("기록 등록", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResultDialog(String title, String content, bool isGameOver) {
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
                currentStage++;
                _initStage();
              });
            },
            child: const Text("다음 단계로"),
          ),
        ],
      ),
    );
  }

  void _resetToHome() {
    setState(() {
      currentStage = 1;
      totalScore = 0;
      ballId = null;
      userSelectedId = null;
      isPreparing = true;
      isShuffling = false;
      isOpened = false;
      isWaitingForAnswer = false; // [추가] 초기화
      startTime = null;
      _roundTimer?.cancel();
      _remainingTime = 5;
      cups = List.generate(cupCount, (i) => CupModel(id: i, currentSlot: i));
    });
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cupWidth = (screenWidth - 60) / cupCount;

    return Scaffold(
      appBar: AppBar(
        title: Text("STAGE $currentStage | SCORE: $totalScore"),
        centerTitle: true,
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Spacer(),
          Text(
            isPreparing ? "준비되셨나요?" : (isShuffling ? "눈 크게 뜨세요!" : "찾아보세요!"),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // [수정] Positioned → Center로 변경, 조건을 isWaitingForAnswer 하나로 단순화
          if (isWaitingForAnswer)
            Center(
              child: Text(
                "$_remainingTime",
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: _remainingTime <= 2 ? Colors.red : Colors.brown[800],
                ),
              ),
            )
          else
            const SizedBox(height: 70), // 레이아웃 높이 유지용

          const SizedBox(height: 10),

          SizedBox(
            height: 250,
            child: Stack(
              children: cups.map((cup) {
                return AnimatedPositioned(
                  duration: Duration(
                    milliseconds: max(100, 500 - (currentStage * 40)),
                  ),
                  curve: Curves.easeInOut,
                  left: 30 + (cup.currentSlot * cupWidth),
                  top: (isOpened || isPreparing) ? 50 : 130,
                  child: GestureDetector(
                    onTap: () => _handleCupTap(cup.id),
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

          const Spacer(),

          if (isPreparing)
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ElevatedButton(
                onPressed: _onStartGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  backgroundColor: Colors.brown[700],
                ),
                child: const Text(
                  "GAME START",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),

          const Spacer(),
        ],
      ),
    );
  }
}