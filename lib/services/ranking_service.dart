import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ranking_model.dart';

class RankingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 점수 저장 (모델 활용)
  Future<void> saveScore(String nickname, int totalScore, int stage) async {
    try {
      final ranking = RankingModel(
        nickname: nickname,
        score: totalScore,
        stage: stage,
        createdAt: null, // toMap에서 serverTimestamp로 처리됨
      );

      await _db.collection('rankings').add(ranking.toMap());
      print("✅ 랭킹 등록 완료: $nickname - $totalScore점");
    } catch (e) {
      print("❌ 랭킹 등록 실패: $e");
    }
  }

  // 2. 실시간 랭킹 (Stream<List<RankingModel>>)
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

  // 3. 일회성 랭킹 가져오기 (Future<List<RankingModel>>)
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