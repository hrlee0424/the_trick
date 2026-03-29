import 'package:cloud_firestore/cloud_firestore.dart';

class RankingModel {
  final String nickname;
  final int score;
  final int stage;
  final DateTime? createdAt;

  RankingModel({
    required this.nickname,
    required this.score,
    required this.stage,
    this.createdAt,
  });

  // 1. 서버에 저장할 때: 모델 -> Map 변환
  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'score': score,
      'stage': stage,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // 2. 서버에서 가져올 때: Map -> 모델 변환 (팩토리 생성자)
  factory RankingModel.fromMap(Map<String, dynamic> map) {
    return RankingModel(
      nickname: map['nickname'] ?? '무명술사',
      score: map['score'] ?? 0,
      stage: map['stage'] ?? 1,
      // Firestore의 Timestamp를 Dart의 DateTime으로 변환
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}