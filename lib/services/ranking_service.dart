import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ranking_model.dart';

class RankingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 점수 저장
  Future<void> saveScore(String nickname, int totalScore, int stage) async {
    try {
      final ranking = RankingModel(
        nickname: nickname,
        score: totalScore,
        stage: stage,
        createdAt: null,
      );
      await _db.collection('rankings').add(ranking.toMap());
      print("✅ 랭킹 등록 완료: $nickname - $totalScore점");
    } catch (e) {
      print("❌ 랭킹 등록 실패: $e");
    }
  }

  // 2. 점수 저장 + 내 순위 반환
  // 저장 후 내 점수보다 높은 도큐먼트 수를 세어 순위를 계산합니다.
  // (동점자는 먼저 등록한 사람이 앞 순위 — createdAt ascending 기준)
  Future<int> saveScoreAndGetRank(
      String nickname, int totalScore, int stage) async {
    try {
      final ranking = RankingModel(
        nickname: nickname,
        score: totalScore,
        stage: stage,
        createdAt: null,
      );

      // 저장
      await _db.collection('rankings').add(ranking.toMap());
      print("✅ 랭킹 등록 완료: $nickname - $totalScore점");

      // 내 점수보다 높은 사람 수 조회 → +1 = 내 순위
      final higherSnapshot = await _db
          .collection('rankings')
          .where('score', isGreaterThan: totalScore)
          .count()
          .get();

      final rank = (higherSnapshot.count ?? 0) + 1;
      print("🏅 내 순위: $rank위");
      return rank;
    } catch (e) {
      print("❌ 랭킹 등록 실패: $e");
      return -1; // 오류 시 -1 반환 → UI에서 순위 표시 숨김
    }
  }

  // 3. 실시간 랭킹 스트림 (Stream<List<RankingModel>>)
  Stream<List<RankingModel>> getTopRankings() {
    return _db
        .collection('rankings')
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RankingModel.fromMap(doc.data()))
        .toList());
  }

  // 4. 일회성 랭킹 가져오기 (Future<List<RankingModel>>)
  Future<List<RankingModel>> getTopRankers({int limit = 10}) async {
    final snapshot = await _db
        .collection('rankings')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => RankingModel.fromMap(doc.data()))
        .toList();
  }
}