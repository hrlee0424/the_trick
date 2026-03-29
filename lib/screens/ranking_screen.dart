import 'package:flutter/material.dart';
import '../model/ranking_model.dart';
import '../services/ranking_service.dart';
import 'game_screen.dart' show AppColors;

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text("🏆 전체 랭킹",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.amber),
            tooltip: "새로고침",
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<RankingModel>>(
        future: _rankingFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.amber, strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.red),
                  const SizedBox(height: 12),
                  const Text("랭킹을 불러오지 못했어요",
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: AppColors.bg),
                    child: const Text("다시 시도",
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text("아직 등록된 기록이 없어요 👀",
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ranker = list[index];
              final rank   = index + 1;
              final isTop3 = rank <= 3;
              final medals = ["🥇", "🥈", "🥉"];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isTop3
                      ? AppColors.amber.withOpacity(0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTop3
                        ? AppColors.amber.withOpacity(0.25)
                        : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      // 순위
                      SizedBox(
                        width: 36,
                        child: isTop3
                            ? Text(medals[index],
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center)
                            : Text("$rank",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 12),

                      // 닉네임 + 스테이지
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ranker.nickname,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isTop3
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isTop3
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text("Stage ${ranker.stage} 도달",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),

                      // 점수
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${ranker.score}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isTop3
                                      ? AppColors.amber
                                      : AppColors.textMuted)),
                          const Text("pt",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
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