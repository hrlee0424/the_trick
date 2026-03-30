import '../model/cup_model.dart';

enum GameStatus { preparing, showingBall, shuffling, playing, opened, gameOver }

class GameState {
  final int currentStage;
  final int totalScore;
  final int? ballId;
  final int? userSelectedId;
  final List<CupModel> cups;
  final GameStatus status;
  final int remainingTime;

  // 콤보 시스템
  final int combo;

  // glow 연출
  final bool isBallGlowing;

  // 점수 팝업
  final bool showScorePopup;
  final int lastBaseScore;
  final int lastTimeBonus;
  final int lastComboBonus;
  final int lastTotalEarned;

  GameState({
    this.currentStage = 1,
    this.totalScore = 0,
    this.ballId,
    this.userSelectedId,
    required this.cups,
    this.status = GameStatus.preparing,
    this.remainingTime = 5,
    this.combo = 0,
    this.isBallGlowing = false,
    this.showScorePopup = false,
    this.lastBaseScore = 0,
    this.lastTimeBonus = 0,
    this.lastComboBonus = 0,
    this.lastTotalEarned = 0,
  });

  GameState copyWith({
    int? currentStage,
    int? totalScore,
    int? ballId,
    bool clearBallId = false,          // null로 명시 초기화할 때 사용
    int? userSelectedId,
    bool clearUserSelectedId = false,  // null로 명시 초기화할 때 사용
    List<CupModel>? cups,
    GameStatus? status,
    int? remainingTime,
    int? combo,
    bool? isBallGlowing,
    bool? showScorePopup,
    int? lastBaseScore,
    int? lastTimeBonus,
    int? lastComboBonus,
    int? lastTotalEarned,
  }) {
    return GameState(
      currentStage: currentStage ?? this.currentStage,
      totalScore: totalScore ?? this.totalScore,
      ballId: clearBallId ? null : (ballId ?? this.ballId),
      userSelectedId: clearUserSelectedId ? null : (userSelectedId ?? this.userSelectedId),
      cups: cups ?? this.cups,
      status: status ?? this.status,
      remainingTime: remainingTime ?? this.remainingTime,
      combo: combo ?? this.combo,
      isBallGlowing: isBallGlowing ?? this.isBallGlowing,
      showScorePopup: showScorePopup ?? this.showScorePopup,
      lastBaseScore: lastBaseScore ?? this.lastBaseScore,
      lastTimeBonus: lastTimeBonus ?? this.lastTimeBonus,
      lastComboBonus: lastComboBonus ?? this.lastComboBonus,
      lastTotalEarned: lastTotalEarned ?? this.lastTotalEarned,
    );
  }
}