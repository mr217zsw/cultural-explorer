import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().request('/user/ranking?limit=100');
      if (mounted) setState(() {
        _users = (data as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.gold;
      case 2:
        return AppTheme.silver;
      case 3:
        return AppTheme.bronze;
      default:
        return AppTheme.textSecondary.withValues(alpha: 0.3);
    }
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 排行榜')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: AppTheme.spacingLg),
                      Text('暂无排名数据', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i] as Map<String, dynamic>;
                      final rank = i + 1;
                      final isTop3 = rank <= 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: isTop3
                              ? [
                                  BoxShadow(
                                    color: _rankColor(rank).withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                          border: isTop3
                              ? Border.all(color: _rankColor(rank), width: 1.5)
                              : Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg,
                            vertical: AppTheme.spacingXs,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: _rankColor(rank),
                            child: Text(
                              _rankEmoji(rank).isNotEmpty ? _rankEmoji(rank) : '$rank',
                              style: TextStyle(
                                fontSize: isTop3 ? 18 : 13,
                                fontWeight: FontWeight.bold,
                                color: isTop3 ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          title: Text(
                            u['nickname'] ?? '匿名用户',
                            style: TextStyle(
                              fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: isTop3 ? 16 : 14,
                            ),
                          ),
                          subtitle: Text(
                            '已通关 ${u['completedCount'] ?? 0} 地区',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${u['totalScore'] ?? 0}',
                                style: TextStyle(
                                  fontSize: isTop3 ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: isTop3 ? AppTheme.accent : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '分',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
