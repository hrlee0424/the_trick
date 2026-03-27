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

  GameState({
    this.currentStage = 1,
    this.totalScore = 0,
    this.ballId,
    this.userSelectedId,
    required this.cups,
    this.status = GameStatus.preparing,
    this.remainingTime = 5,
  });

  // 상태 변경을 위한 copyWith
  GameState copyWith({
    int? currentStage,
    int? totalScore,
    int? ballId,
    int? userSelectedId,
    List<CupModel>? cups,
    GameStatus? status,
    int? remainingTime,
  }) {
    return GameState(
      currentStage: currentStage ?? this.currentStage,
      totalScore: totalScore ?? this.totalScore,
      ballId: ballId ?? this.ballId,
      userSelectedId: userSelectedId ?? this.userSelectedId,
      cups: cups ?? this.cups,
      status: status ?? this.status,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}