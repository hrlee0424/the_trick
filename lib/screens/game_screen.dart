import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';
import '../model/game_state.dart';
import '../widgets/cup_widget.dart';
import '../services/ranking_service.dart';
import '../model/ranking_model.dart';
import 'ranking_screen.dart';

// ─────────────────────────────────────────────────────
// 디자인 토큰 — 앱 전체 공유 색상 상수
// ─────────────────────────────────────────────────────
class AppColors {
  static const bg         = Color(0xFF0D0D14);
  static const surface    = Color(0xFF16161F);
  static const surfaceAlt = Color(0xFF1E1E2A);
  static const amber      = Color(0xFFFFB627);
  static const amberGlow  = Color(0x33FFB627);
  static const red        = Color(0xFFFF4D6D);
  static const green      = Color(0xFF4DFF9E);
  static const textPrimary= Color(0xFFF0EAD6);
  static const textMuted  = Color(0xFF6B6880);
  static const divider    = Color(0xFF2A2A38);
}

// ─────────────────────────────────────────────────────
// GameScreen
// ─────────────────────────────────────────────────────
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _popupController;
  late Animation<double>   _popupFade;
  late Animation<Offset>   _popupSlide;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popupFade = CurvedAnimation(
        parent: _popupController, curve: Curves.easeOut);
    _popupSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _popupController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
  }

  // 상태 변화 감지 → 팝업 애니메이션 & 다이얼로그 트리거
  void _onStateChanged(GameState? prev, GameState next) {
    if (prev == null) return;

    // 점수 팝업 등장
    if (!prev.showScorePopup && next.showScorePopup) {
      _popupController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        ref.read(gameProvider.notifier).hideScorePopup();
        _showResultDialog(next);
      });
    }

    // 게임오버 감지
    if (prev.status != GameStatus.gameOver &&
        next.status == GameStatus.gameOver) {
      // 팝업이 없을 때만 (오답일 때) 즉시 다이얼로그
      if (!next.showScorePopup) {
        _showNamingDialog(next);
      }
    }
  }

  void _goToRanking() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const RankingScreen()));

  // ── 빌드 ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    ref.listen<GameState>(gameProvider, _onStateChanged);

    final sw         = MediaQuery.of(context).size.width;
    final cupWidth   = (sw - 60) / 5;
    final isOpened   = state.status == GameStatus.showingBall ||
        state.status == GameStatus.opened ||
        state.status == GameStatus.gameOver;
    final isPreparing = state.status == GameStatus.preparing;
    final isShuffling = state.status == GameStatus.shuffling;
    final isPlaying   = state.status == GameStatus.playing;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 별빛 배경
          Positioned.fill(child: CustomPaint(painter: _StarfieldPainter())),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state, notifier),
                const Spacer(),
                _buildStatusText(isPreparing, isShuffling),
                const SizedBox(height: 16),
                _buildTimer(isPlaying, state.remainingTime),
                const SizedBox(height: 24),
                _buildCupArea(state, cupWidth, isOpened, isPreparing),
                const Spacer(),
                if (isPreparing) _buildStartSection(notifier),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 점수 팝업
          if (state.showScorePopup) _buildScorePopup(state),
        ],
      ),
    );
  }

  // ── 상단 바 ────────────────────────────────────────
  Widget _buildTopBar(GameState state, GameNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(
        children: [
          _badge("STAGE ${state.currentStage}",
              AppColors.amber, AppColors.amberGlow,
              letterSpacing: 1.5, fontSize: 12),
          if (state.combo > 1) ...[
            const SizedBox(width: 8),
            _badge("🔥 ${state.combo}콤보",
                AppColors.red, AppColors.red.withOpacity(0.15)),
          ],
          const Spacer(),
          Text("${state.totalScore}",
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(width: 3),
          const Text("pt",
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _goToRanking,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppColors.amber, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, Color bg,
      {double fontSize = 12, double letterSpacing = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: letterSpacing)),
    );
  }

  // ── 상태 텍스트 ────────────────────────────────────
  Widget _buildStatusText(bool isPreparing, bool isShuffling) {
    final text = isPreparing
        ? "눈을 크게 뜨세요 👀"
        : isShuffling
        ? "따라올 수 있겠어?"
        : "공은 어디에?";
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(text,
          key: ValueKey(text),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3)),
    );
  }

  // ── 타이머 ─────────────────────────────────────────
  Widget _buildTimer(bool isPlaying, int remainingTime) {
    if (!isPlaying) return const SizedBox(height: 64);
    final isUrgent = remainingTime <= 2;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text("$remainingTime",
          key: ValueKey(remainingTime),
          style: TextStyle(
              color: isUrgent ? AppColors.red : AppColors.amber,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              shadows: [
                Shadow(
                    color: (isUrgent ? AppColors.red : AppColors.amber)
                        .withOpacity(0.5),
                    blurRadius: 20)
              ])),
    );
  }

  // ── 컵 영역 ────────────────────────────────────────
  Widget _buildCupArea(GameState state, double cupWidth,
      bool isOpened, bool isPreparing) {
    final dur =
    Duration(milliseconds: max(100, 500 - (state.currentStage * 40)));
    return SizedBox(
      height: 220,
      child: Stack(
        children: state.cups.map((cup) {
          final hasBall = state.ballId == cup.id;
          return AnimatedPositioned(
            duration: dur,
            curve: Curves.easeInOut,
            left: 30 + (cup.currentSlot * cupWidth),
            top: (isOpened || isPreparing) ? 30 : 110,
            child: GestureDetector(
              onTap: () => ref.read(gameProvider.notifier).tapCup(cup.id),
              child: SizedBox(
                width: cupWidth,
                child: CupWidget(
                  size: cupWidth * 0.9,
                  isOpened: isOpened || isPreparing,
                  hasBall: hasBall,
                  isSelected: state.userSelectedId == cup.id,
                  isBallGlowing: hasBall && state.isBallGlowing,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 시작 섹션 ──────────────────────────────────────
  Widget _buildStartSection(GameNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: notifier.startGame,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFB627), Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.amber.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 6))
                ],
              ),
              child: const Text("GAME START",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.bg,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _goToRanking,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                const Text("전체 랭킹 보기",
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 점수 팝업 오버레이 ──────────────────────────────
  Widget _buildScorePopup(GameState state) {
    final headerText = state.combo >= 5
        ? "🔥 ${state.combo}콤보!!"
        : state.combo >= 3
        ? "✨ ${state.combo}콤보!"
        : "🎯 정답!";

    return Center(
      child: FadeTransition(
        opacity: _popupFade,
        child: SlideTransition(
          position: _popupSlide,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: AppColors.amber.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(headerText,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                _popupRow(Icons.star_outline, "기본 점수",
                    "+${state.lastBaseScore}", AppColors.amber),
                const SizedBox(height: 8),
                _popupRow(
                  Icons.timer_outlined,
                  "시간 보너스 (${state.remainingTime}초)",
                  "+${state.lastTimeBonus}",
                  state.remainingTime >= 4
                      ? AppColors.green
                      : state.remainingTime >= 2
                      ? AppColors.amber
                      : AppColors.red,
                ),
                if (state.lastComboBonus > 0) ...[
                  const SizedBox(height: 8),
                  _popupRow(Icons.local_fire_department_outlined,
                      "콤보 보너스 (${state.combo}콤보)",
                      "+${state.lastComboBonus}", AppColors.red),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.divider, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("이번 획득",
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text("+${state.lastTotalEarned}",
                        style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("누적 ${state.totalScore}pt",
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _popupRow(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ]),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Stage Clear 다이얼로그 ─────────────────────────
  void _showResultDialog(GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎉 Stage Clear!",
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _dialogRow("기본 점수", state.lastBaseScore, AppColors.amber),
              const SizedBox(height: 8),
              _dialogRow("⏱ 시간 보너스", state.lastTimeBonus, AppColors.green),
              if (state.lastComboBonus > 0) ...[
                const SizedBox(height: 8),
                _dialogRow("🔥 콤보 (${state.combo}콤보)",
                    state.lastComboBonus, AppColors.red),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: AppColors.divider),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("획득 점수",
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text("+${state.lastTotalEarned}",
                      style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 4),
              Text("누적 ${state.totalScore}pt",
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(gameProvider.notifier).nextStage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("다음 단계로",
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        Text("+$value",
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }

  // ── GAME OVER / 닉네임 다이얼로그 ─────────────────
  void _showNamingDialog(GameState gameState) {
    final controller = TextEditingController();
    String? errorMessage;
    int? myRank;
    bool isLoading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.93, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final keyboardH = MediaQuery.of(context).viewInsets.bottom;
          final screenH   = MediaQuery.of(context).size.height;

          return Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: Center(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardH),
                constraints:
                BoxConstraints(maxHeight: screenH - 32 - keyboardH),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // 헤더
                        const Text("GAME OVER",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3)),
                        const SizedBox(height: 4),
                        Text("Stage ${gameState.currentStage} 도달",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 20),

                        // 점수 카드
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppColors.amber.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              const Text("MY SCORE",
                                  style: TextStyle(
                                      color: AppColors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2)),
                              const SizedBox(height: 8),
                              Text("${gameState.totalScore}",
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2)),
                              if (gameState.combo > 1) ...[
                                const SizedBox(height: 4),
                                Text("🔥 최고 콤보 ${gameState.combo}",
                                    style: const TextStyle(
                                        color: AppColors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                              if (myRank != null) ...[
                                const SizedBox(height: 10),
                                _rankBadge(myRank!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 닉네임 입력
                        const Text("닉네임",
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          enabled: myRank == null,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "닉네임 입력 (최대 8자)",
                            hintStyle: const TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            counterStyle: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.amber, width: 1.5)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: errorMessage != null
                                  ? const BorderSide(
                                  color: AppColors.red, width: 1.5)
                                  : BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && errorMessage != null) {
                              setDialogState(() => errorMessage = null);
                            }
                          },
                        ),
                        SizedBox(
                          height: 20,
                          child: errorMessage != null
                              ? Text(errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.red, fontSize: 12))
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // TOP 10
                        const Row(children: [
                          Icon(Icons.leaderboard,
                              size: 15, color: AppColors.amber),
                          SizedBox(width: 6),
                          Text("TOP 10",
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: FutureBuilder<List<RankingModel>>(
                            future:
                            RankingService().getTopRankers(limit: 10),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.amber,
                                        strokeWidth: 2));
                              }
                              final list = snapshot.data!;
                              final medals = ["🥇", "🥈", "🥉"];
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final r      = list[index];
                                  final isTop3 = index < 3;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5),
                                    child: Row(children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          isTop3
                                              ? medals[index]
                                              : "${index + 1}",
                                          style: TextStyle(
                                              fontSize: isTop3 ? 16 : 13,
                                              color: AppColors.textMuted),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(r.nickname,
                                                style: TextStyle(
                                                    color: isTop3
                                                        ? AppColors.textPrimary
                                                        : AppColors.textMuted,
                                                    fontWeight: isTop3
                                                        ? FontWeight.w700
                                                        : FontWeight.w400,
                                                    fontSize: 13),
                                                overflow:
                                                TextOverflow.ellipsis),
                                            Text("Stage ${r.stage}",
                                                style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text("${r.score}",
                                          style: TextStyle(
                                              color: isTop3
                                                  ? AppColors.amber
                                                  : AppColors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ]),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 전체 랭킹
                        GestureDetector(
                          onTap: _goToRanking,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events_outlined,
                                    size: 14, color: AppColors.textMuted),
                                SizedBox(width: 6),
                                Text("전체 순위 보기",
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 버튼 행
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref
                                    .read(gameProvider.notifier)
                                    .resetGame();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                side: const BorderSide(
                                    color: AppColors.divider),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12)),
                              ),
                              child: const Text("다시 하기",
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading || myRank != null
                                  ? null
                                  : () async {
                                if (controller.text.trim().isEmpty) {
                                  setDialogState(() => errorMessage =
                                  "닉네임을 입력해주세요!");
                                  return;
                                }
                                setDialogState(
                                        () => isLoading = true);
                                final rank =
                                await RankingService()
                                    .saveScoreAndGetRank(
                                  controller.text.trim(),
                                  gameState.totalScore,
                                  gameState.currentStage,
                                );
                                if (!mounted) return;
                                setDialogState(() {
                                  isLoading = false;
                                  myRank = rank > 0 ? rank : null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                backgroundColor: AppColors.amber,
                                foregroundColor: AppColors.bg,
                                disabledBackgroundColor:
                                AppColors.amber.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: AppColors.bg,
                                      strokeWidth: 2))
                                  : Text(
                                  myRank != null
                                      ? "등록 완료 ✓"
                                      : "기록 등록",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ),
                        ]),
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
      if (mounted) ref.read(gameProvider.notifier).resetGame();
    });
  }

  Widget _rankBadge(int rank) {
    final color = rank <= 3
        ? AppColors.amber
        : rank <= 10
        ? AppColors.green
        : AppColors.textMuted;
    final label = rank <= 3
        ? ["🥇 1위", "🥈 2위", "🥉 3위"][rank - 1]
        : "🏅 ${rank}위";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
    );
  }
}

// ─────────────────────────────────────────────────────
// 별빛 배경 페인터
// ─────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng   = Random(42);
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x       = rng.nextDouble() * size.width;
      final y       = rng.nextDouble() * size.height;
      final r       = rng.nextDouble() * 1.2 + 0.3;
      final opacity = rng.nextDouble() * 0.35 + 0.05;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}