import 'package:flutter/material.dart';
import '../model/ranking_model.dart';
import '../services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingModel>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = RankingService().getTopRankers(limit: 100);
  }

  void _refresh() {
    setState(() {
      _rankingFuture = RankingService().getTopRankers(limit: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "🏆 전체 랭킹",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "새로고침",
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<RankingModel>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          // 로딩
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          }

          // 에러
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text("랭킹을 불러오지 못했어요",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown),
                    child: const Text("다시 시도",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // 데이터 없음
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text("아직 등록된 기록이 없어요 👀",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ranker = list[index];
              final rank = index + 1;
              final isTop3 = rank <= 3;
              final medals = ["🥇", "🥈", "🥉"];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isTop3
                      ? Colors.orange.withOpacity(0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isTop3
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // 순위
                      SizedBox(
                        width: 36,
                        child: isTop3
                            ? Text(medals[index],
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center)
                            : Text(
                          "$rank",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 닉네임 + 스테이지
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ranker.nickname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isTop3
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isTop3
                                    ? Colors.brown[800]
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Stage ${ranker.stage} 도달",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.brown[300]),
                            ),
                          ],
                        ),
                      ),

                      // 점수
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${ranker.score}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTop3
                                  ? Colors.orange[700]
                                  : Colors.blueGrey[600],
                            ),
                          ),
                          Text(
                            "점",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
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
      ),
    );
  }
}