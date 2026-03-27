import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../model/cup_model.dart';
import '../model/ranking_model.dart';
import '../widgets/cup_widget.dart';
import '../services/ranking_service.dart';
import 'ranking_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final int cupCount = 5;
  int currentStage = 1;
  int totalScore = 0;
  int? ballId;
  late List<CupModel> cups;

  bool isPreparing = true;
  bool isShuffling = false;
  bool isOpened = false;
  bool isWaitingForAnswer = false;
  int? userSelectedId;

  DateTime? startTime;

  Timer? _roundTimer;
  int _remainingTime = 5;

  bool _showScorePopup = false;
  int _lastBaseScore = 0;
  int _lastTimeBonus = 0;
  int _lastTotalEarned = 0;

  late AnimationController _popupController;
  late Animation<double> _popupFadeAnim;
  late Animation<Offset> _popupSlideAnim;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popupFadeAnim =
        CurvedAnimation(parent: _popupController, curve: Curves.easeOut);
    _popupSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _popupController, curve: Curves.easeOut));
    _initStage();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _popupController.dispose();
    super.dispose();
  }

  void _initStage() {
    setState(() {
      ballId = null;
      userSelectedId = null;
      isPreparing = true;
      isShuffling = false;
      isOpened = false;
      isWaitingForAnswer = false;
      _showScorePopup = false;
      cups = List.generate(cupCount, (i) => CupModel(id: i, currentSlot: i));
    });
  }

  void _onStartGame() async {
    setState(() {
      isPreparing = false;
      ballId = Random().nextInt(cupCount);
      isOpened = true;
      _showScorePopup = false;
    });
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() => isOpened = false);
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
      isWaitingForAnswer = false;
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
      isWaitingForAnswer = true;
    });
    _startCountDown();
  }

  Map<String, int> _calcScore() {
    final int base = 1000 * currentStage;
    final double timeRatio = _remainingTime / 5.0;
    final int bonus = (base * timeRatio).toInt();
    return {'base': base, 'bonus': bonus, 'total': base + bonus};
  }

  void _handleCupTap(int id) {
    if (isPreparing || isShuffling || isOpened) return;
    _roundTimer?.cancel();
    setState(() {
      userSelectedId = id;
      isOpened = true;
      isWaitingForAnswer = false;
    });
    if (id == ballId) {
      final score = _calcScore();
      totalScore += score['total']!;
      setState(() {
        _lastBaseScore   = score['base']!;
        _lastTimeBonus   = score['bonus']!;
        _lastTotalEarned = score['total']!;
        _showScorePopup  = true;
      });
      _popupController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() => _showScorePopup = false);
        _showResultDialog();
      });
    } else {
      _showNamingDialog();
    }
  }

  void _goToRankingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RankingScreen()),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🎉 Stage Clear!",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreRow("기본 점수", _lastBaseScore, Colors.brown),
            const SizedBox(height: 6),
            _scoreRow("⏱ 시간 보너스", _lastTimeBonus, Colors.orange),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("획득 점수",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("+$_lastTotalEarned",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.brown)),
              ],
            ),
            const SizedBox(height: 8),
            Text("누적 점수: $totalScore",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                currentStage++;
                _initStage();
              });
            },
            child: const Text("다음 단계로",
                style: TextStyle(
                    color: Colors.brown, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        Text("+$value",
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showNamingDialog() {
    final controller = TextEditingController();
    String? errorMessage; // [수정] errorText 대신 별도 변수로 관리
    int? myRank;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      // [수정] Dialog 대신 바텀시트 스타일로 전환 — 키보드가 올라와도
      // 다이얼로그가 키보드 위로 자연스럽게 밀려올라가 오버플로우 없음
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Padding(
            // [수정] 키보드 높이만큼 하단 패딩 자동 적용
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Dialog(
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              // [수정] ClipRect + ConstrainedBox로 최대 높이를 화면의 88%로 제한
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SingleChildScrollView(
                    // [수정] 키보드가 올라와도 스크롤 가능하도록
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ① GAME OVER 헤더
                        const Text(
                          "🏆 GAME OVER",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Stage $currentStage 도달",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: Colors.brown[300]),
                        ),
                        const Divider(height: 28, thickness: 1.5),

                        // ② 내 점수 카드
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "MY SCORE",
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "$totalScore",
                                style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown),
                              ),
                              if (myRank != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: myRank! <= 3
                                        ? Colors.orange
                                        : myRank! <= 10
                                        ? Colors.brown[400]
                                        : Colors.blueGrey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    myRank! <= 3
                                        ? ["🥇 1위", "🥈 2위",
                                      "🥉 3위"][myRank! - 1]
                                        : "🏅 $myRank위",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ③ 닉네임 입력
                        Text(
                          "닉네임",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[600]),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          enabled: myRank == null,
                          // [수정] errorText 제거 → 에러는 아래 Text로 표시
                          // errorText가 생기면 TextField 높이가 바뀌며 오버플로우 유발
                          decoration: InputDecoration(
                            hintText: "닉네임을 입력하세요 (최대 8자)",
                            filled: true,
                            fillColor: Colors.grey[100],
                            counterStyle: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.orange, width: 2)),
                            // [수정] 에러 상태일 때 테두리만 빨간색으로
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: errorMessage != null
                                  ? const BorderSide(
                                  color: Colors.red, width: 1.5)
                                  : BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && errorMessage != null) {
                              setDialogState(() => errorMessage = null);
                            }
                          },
                        ),
                        // [수정] 에러 메시지를 TextField 밖 고정 높이 영역에 표시
                        // → TextField 크기가 변하지 않아 오버플로우 없음
                        SizedBox(
                          height: 20,
                          child: errorMessage != null
                              ? Padding(
                            padding:
                            const EdgeInsets.only(left: 4, top: 2),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // ④ TOP 10 랭킹
                        Row(
                          children: [
                            Icon(Icons.leaderboard,
                                size: 16, color: Colors.brown[400]),
                            const SizedBox(width: 6),
                            const Text("TOP 10",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1),
                          ),
                          child: FutureBuilder<List<dynamic>>(
                            future: RankingService().getTopRankers(limit: 10),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final list = snapshot.data!;
                              final medals = ["🥇", "🥈", "🥉"];
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  RankingModel ranker = list[index];
                                  final isTop3 = index < 3;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7, horizontal: 4),
                                    decoration: BoxDecoration(
                                      border: index < list.length - 1
                                          ? Border(
                                          bottom: BorderSide(
                                              color: Colors.grey
                                                  .withOpacity(0.15),
                                              width: 1))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            isTop3
                                                ? medals[index]
                                                : "${index + 1}",
                                            style: TextStyle(
                                              fontSize: isTop3 ? 16 : 13,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ranker.nickname,
                                                style: TextStyle(
                                                  fontWeight: isTop3
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 14,
                                                  color: isTop3
                                                      ? Colors.brown[700]
                                                      : Colors.black87,
                                                ),
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Stage ${ranker.stage}",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                    Colors.brown[300]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "${ranker.score}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isTop3
                                                ? Colors.orange[700]
                                                : Colors.blueGrey,
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
                        const SizedBox(height: 16),

                        // ⑤ 전체 순위 보기
                        TextButton.icon(
                          onPressed: () => _goToRankingScreen(),
                          icon: const Icon(Icons.emoji_events_outlined,
                              size: 16, color: Colors.brown),
                          label: const Text(
                            "전체 순위 보기",
                            style: TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ⑥ 다시하기 / 기록 등록 버튼
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _resetToHome();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  side:
                                  const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                child: const Text("다시 하기",
                                    style:
                                    TextStyle(color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading || myRank != null
                                    ? null
                                    : () async {
                                  if (controller.text
                                      .trim()
                                      .isEmpty) {
                                    setDialogState(() =>
                                    errorMessage = "닉네임을 입력해주세요!");
                                    return;
                                  }
                                  setDialogState(
                                          () => isLoading = true);
                                  final rank =
                                  await RankingService()
                                      .saveScoreAndGetRank(
                                    controller.text.trim(),
                                    totalScore,
                                    currentStage,
                                  );
                                  if (!mounted) return;
                                  setDialogState(() {
                                    isLoading = false;
                                    myRank =
                                    rank > 0 ? rank : null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  backgroundColor: Colors.brown,
                                  disabledBackgroundColor:
                                  Colors.brown.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                                    : Text(
                                  myRank != null
                                      ? "등록 완료 ✓"
                                      : "기록 등록",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    ).then((_) {
      if (mounted) _resetToHome();
    });
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
      isWaitingForAnswer = false;
      _showScorePopup = false;
      startTime = null;
      _roundTimer?.cancel();
      _remainingTime = 5;
      cups = List.generate(cupCount, (i) => CupModel(id: i, currentSlot: i));
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: "전체 랭킹",
            onPressed: _goToRankingScreen,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Spacer(),
              Text(
                isPreparing
                    ? "준비되셨나요?"
                    : (isShuffling ? "눈 크게 뜨세요!" : "찾아보세요!"),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isWaitingForAnswer)
                Text(
                  "$_remainingTime",
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color:
                    _remainingTime <= 2 ? Colors.red : Colors.brown[800],
                  ),
                )
              else
                const SizedBox(height: 70),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: Stack(
                  children: cups.map((cup) {
                    return AnimatedPositioned(
                      duration: Duration(
                          milliseconds: max(100, 500 - (currentStage * 40))),
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
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _onStartGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          backgroundColor: Colors.brown[700],
                        ),
                        child: const Text(
                          "GAME START",
                          style:
                          TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _goToRankingScreen,
                        icon: Icon(Icons.emoji_events,
                            color: Colors.brown[400], size: 18),
                        label: Text(
                          "전체 랭킹 보기",
                          style: TextStyle(
                              color: Colors.brown[400],
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
            ],
          ),

          // 정답 시 점수 팝업 오버레이
          if (_showScorePopup)
            Center(
              child: FadeTransition(
                opacity: _popupFadeAnim,
                child: SlideTransition(
                  position: _popupSlideAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("🎯 정답!",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _popupScoreRow(
                          icon: Icons.star_outline,
                          label: "기본 점수",
                          value: "+$_lastBaseScore",
                          color: Colors.brown,
                        ),
                        const SizedBox(height: 8),
                        _popupScoreRow(
                          icon: Icons.timer_outlined,
                          label: "시간 보너스 ($_remainingTime초 남음)",
                          value: "+$_lastTimeBonus",
                          color: _remainingTime >= 4
                              ? Colors.green
                              : _remainingTime >= 2
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("이번 획득",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              "+$_lastTotalEarned",
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "누적 $totalScore점",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _popupScoreRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}