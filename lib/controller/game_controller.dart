import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/game_state.dart';
import '../model/cup_model.dart';

// 1. 프로바이더 선언 (NotifierProvider 사용)
final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});

// 2. 클래스 정의 (Notifier 상속)
class GameNotifier extends Notifier<GameState> {

  @override
  GameState build() {
    // 초기 상태를 반환합니다. (기존의 super(initialState) 역할)
    return GameState(
      cups: List.generate(5, (i) => CupModel(id: i, currentSlot: i)),
      currentStage: 1,
      totalScore: 0,
    );
  }

  Timer? _roundTimer;
  DateTime? _startTime;

  // --- 게임 로직들 ---

  Future<void> startGame() async {
    // state = ... 방식으로 상태 업데이트
    state = state.copyWith(
      status: GameStatus.showingBall,
      ballId: Random().nextInt(5),
      userSelectedId: null,
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!ref.mounted) return;

    await startShuffle();
  }

  Future<void> startShuffle() async {
    state = state.copyWith(status: GameStatus.shuffling);

    // ... 기존 섞기 로직 동일 ...
    // 로직 완료 후
    state = state.copyWith(status: GameStatus.playing, remainingTime: 5);
    _startTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        timer.cancel();
        handleTimeOut();
      }
    });
  }

  void handleTimeOut() {
    state = state.copyWith(status: GameStatus.gameOver);
  }

  void tapCup(int id) {
    if (state.status != GameStatus.playing) return;
    _roundTimer?.cancel();

    final duration = DateTime.now().difference(_startTime!);
    state = state.copyWith(userSelectedId: id, status: GameStatus.opened);

    if (id == state.ballId) {
      // 성공 로직 (점수 계산 등)
    } else {
      state = state.copyWith(status: GameStatus.gameOver);
    }
  }

  void resetGame() {
    _roundTimer?.cancel();
    ref.invalidateSelf(); // 현재 Notifier의 상태를 초기 build() 값으로 리셋
  }
}