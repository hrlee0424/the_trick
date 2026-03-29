import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/game_state.dart';
import '../model/cup_model.dart';

final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});

class GameNotifier extends Notifier<GameState> {
  static const int _cupCount = 5;
  Timer? _roundTimer;

  @override
  GameState build() {
    return GameState(
      cups: List.generate(_cupCount, (i) => CupModel(id: i, currentSlot: i)),
    );
  }

  // ── 게임 시작 ───────────────────────────────────────
  Future<void> startGame() async {
    state = state.copyWith(
      status: GameStatus.showingBall,
      ballId: Random().nextInt(_cupCount),
      userSelectedId: null,
      showScorePopup: false,
      isBallGlowing: false,
    );

    // C 연출: 공 반짝임
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!ref.mounted) return;
    state = state.copyWith(isBallGlowing: true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!ref.mounted) return;
    state = state.copyWith(isBallGlowing: false);

    await Future.delayed(const Duration(milliseconds: 100));
    if (!ref.mounted) return;

    await _startShuffle();
  }

  // ── 셔플 ────────────────────────────────────────────
  Future<void> _startShuffle() async {
    state = state.copyWith(status: GameStatus.shuffling);

    final int shuffleCount = 5 + (state.currentStage * 2);
    final int speedMs = max(150, 600 - (state.currentStage * 40));
    final random = Random();

    for (int i = 0; i < shuffleCount; i++) {
      int idx1 = random.nextInt(_cupCount);
      int idx2 = random.nextInt(_cupCount);
      while (idx1 == idx2) idx2 = random.nextInt(_cupCount);

      await Future.delayed(Duration(milliseconds: speedMs));
      if (!ref.mounted) return;

      final newCups = List<CupModel>.from(state.cups);
      final tempSlot = newCups[idx1].currentSlot;
      newCups[idx1].currentSlot = newCups[idx2].currentSlot;
      newCups[idx2].currentSlot = tempSlot;
      state = state.copyWith(cups: newCups);
    }

    state = state.copyWith(
      status: GameStatus.playing,
      remainingTime: 5,
    );
    _startTimer();
  }

  // ── 타이머 ───────────────────────────────────────────
  void _startTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        return;
      }
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (state.status == GameStatus.opened) return;
    state = state.copyWith(status: GameStatus.gameOver);
  }

  // ── 컵 탭 ────────────────────────────────────────────
  void tapCup(int id) {
    if (state.status != GameStatus.playing) return;
    _roundTimer?.cancel();

    state = state.copyWith(
      userSelectedId: id,
      status: GameStatus.opened,
    );

    if (id == state.ballId) {
      final newCombo = state.combo + 1;
      final score = _calcScore(newCombo);
      state = state.copyWith(
        combo: newCombo,
        totalScore: state.totalScore + score['total']!,
        lastBaseScore: score['base']!,
        lastTimeBonus: score['bonus']!,
        lastComboBonus: score['combo']!,
        lastTotalEarned: score['total']!,
        showScorePopup: true,
      );
    } else {
      state = state.copyWith(
        combo: 0,
        status: GameStatus.gameOver,
      );
    }
  }

  // ── 팝업 닫기 ────────────────────────────────────────
  void hideScorePopup() {
    state = state.copyWith(showScorePopup: false);
  }

  // ── 다음 스테이지 ─────────────────────────────────────
  void nextStage() {
    state = state.copyWith(
      currentStage: state.currentStage + 1,
      ballId: null,
      userSelectedId: null,
      status: GameStatus.preparing,
      showScorePopup: false,
      isBallGlowing: false,
      cups: List.generate(_cupCount, (i) => CupModel(id: i, currentSlot: i)),
    );
  }

  // ── 게임 리셋 ────────────────────────────────────────
  void resetGame() {
    _roundTimer?.cancel();
    ref.invalidateSelf();
  }

  // ── 점수 계산 ─────────────────────────────────────────
  // base  = 500 * stage²
  // bonus = 100 * 남은시간 (최대 500)
  // combo = base * 0.1 * (콤보-1)
  Map<String, int> _calcScore(int combo) {
    final int base = 500 * state.currentStage * state.currentStage;
    final int bonus = state.remainingTime * 100;
    final int comboBonus = combo > 1 ? (base * 0.1 * (combo - 1)).toInt() : 0;
    return {
      'base': base,
      'bonus': bonus,
      'combo': comboBonus,
      'total': base + bonus + comboBonus,
    };
  }
}