import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../ranking/ranking_page.dart';
import '../favorites/favorites_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  bool _checkedToday = false;
  int _checkinStreak = 0;
  List<dynamic> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadCheckin();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _api.request('/badges/all') as List<dynamic>;
      if (mounted) setState(() => _badges = badges);
    } catch (_) {}
  }

  Future<void> _loadCheckin() async {
    try {
      final stats = await _api.request('/checkin/stats') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _checkinStreak = stats['currentStreak'] ?? 0;
          _checkedToday = _isToday(stats['lastCheckinDate'] as String?);
        });
      }
    } catch (_) {}
  }

  bool _isToday(String? date) {
    if (date == null) return false;
    final d = DateTime.tryParse(date);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _doCheckin() async {
    if (_checkedToday) return;
    try {
      final result = await _api.request('/checkin/daily', method: 'POST') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _checkedToday = true;
          _checkinStreak = (result['streak'] as int?) ?? _checkinStreak + 1;
        });
        context.read<AuthProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('签到成功！+${result['reward'] ?? 10}积分')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editNickname(context), tooltip: '修改昵称'),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 头部
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacingXl, AppTheme.spacingXl, AppTheme.spacingXl, AppTheme.spacingXxxl),
                    child: Column(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2), border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
                          alignment: Alignment.center,
                          child: Text(user.nickname?.isNotEmpty == true ? user.nickname![0] : '华', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(user.nickname ?? '匿名探索者', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),

                  // 签到按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, AppTheme.spacingLg, AppTheme.spacingLg, 0),
                    child: InkWell(
                      onTap: _doCheckin,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: _checkedToday ? Colors.grey.shade200 : AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 12)],
                        ),
                        child: Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: AppTheme.spacingMd),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('每日签到', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('连续签到 $_checkinStreak 天', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ]),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _checkedToday ? Colors.grey.shade400 : AppTheme.accent,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(_checkedToday ? '已签到' : '签到 +10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 统计
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Row(
                      children: [
                        _StatCard(icon: Icons.stars, label: '总积分', value: '${user.totalScore}', color: AppTheme.accent),
                        const SizedBox(width: AppTheme.spacingMd),
                        _StatCard(icon: Icons.check_circle_outline, label: '已通关', value: '${user.completedCount}/34', color: AppTheme.success),
                        const SizedBox(width: AppTheme.spacingMd),
                        _StatCard(icon: Icons.local_fire_department, label: '连胜', value: '${user.maxStreak}', color: const Color(0xff3498db)),
                      ],
                    ),
                  ),

                  // 勋章墙
                  if (_badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 0, AppTheme.spacingLg, AppTheme.spacingSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('🏅 勋章墙', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${_badges.where((b) => b['earned'] == true).length}/${_badges.length}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ]),
                          const SizedBox(height: AppTheme.spacingSm),
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: _badges.map((b) {
                              final earned = b['earned'] == true;
                              return Container(
                                width: 68,
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: earned ? AppTheme.surface : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(color: earned ? AppTheme.accent.withValues(alpha: 0.3) : Colors.grey.shade200),
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(earned ? (b['badgeIcon'] ?? '🏅') as String : '🔒', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(height: 2),
                                  Text(earned ? (b['badgeName'] ?? '') as String : '未解锁', style: TextStyle(fontSize: 9, color: earned ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: earned ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ]),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // 菜单
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Column(
                      children: [
                        _MenuItem(icon: Icons.emoji_events_outlined, title: '全国排行榜', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingPage()))),
                        _MenuItem(icon: Icons.favorite_border, title: '我的收藏', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()))),
                        _MenuItem(icon: Icons.emoji_events_outlined, title: '我的徽章', onTap: _showAllBadges),
                        _MenuItem(icon: Icons.edit_outlined, title: '修改昵称', onTap: () => _editNickname(context)),
                        _MenuItem(icon: Icons.share_outlined, title: '分享我的成就', onTap: _shareAchievement),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxxl),
                ],
              ),
            ),
    );
  }

  void _shareAchievement() {
    final user = context.read<AuthProvider>().user;
    final earnedCount = _badges.where((b) => b['earned'] == true).length;
    final text = '🏯 我在「华夏文化探索」中游览了 ${user?.completedCount ?? 0}/34 个地区，'
        '获得了 ${user?.totalScore ?? 0} 积分和 $earnedCount 枚徽章！\n'
        '快来一起探索中华文化吧！';

    Clipboard.setData(ClipboardData(text: text));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('分享我的成就'),
        content: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff8b1e2d), Color(0xffc0392b)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('华夏文化探索', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white30),
            _shareLine('🗺️ 已探索', '${user?.completedCount ?? 0} / 34 地区'),
            _shareLine('⭐ 总积分', '${user?.totalScore ?? 0} 分'),
            _shareLine('🏅 徽章', '$earnedCount / ${_badges.length}'),
            const SizedBox(height: 12),
            const Text('一起来探索中华文化吧！', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制分享文案！'), duration: Duration(seconds: 2)));
            },
            child: const Text('复制文案'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('完成')),
        ],
      ),
    );
  }

  Widget _shareLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showAllBadges() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('我的徽章'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingMd,
            children: _badges.map((b) {
              final earned = b['earned'] == true;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: earned ? AppTheme.surface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: earned ? AppTheme.accent.withValues(alpha: 0.3) : Colors.grey.shade200),
                    ),
                    alignment: Alignment.center,
                    child: Text(earned ? (b['badgeIcon'] ?? '🏅') as String : '🔒', style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 4),
                  Text(b['badgeName'] ?? '', style: TextStyle(fontSize: 11, color: earned ? AppTheme.textPrimary : AppTheme.textSecondary), textAlign: TextAlign.center),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }

  void _editNickname(BuildContext context) {
    final ctrl = TextEditingController(text: context.read<AuthProvider>().user?.nickname ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('设置昵称'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '请输入昵称'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () async {
            await context.read<AuthProvider>().updateProfile(nickname: ctrl.text.trim());
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('确定')),
        ],
      ),
    );
  }
}

// _StatCard 和 _MenuItem 保持不变
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: AppTheme.spacingSm),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingLg),
            child: Row(children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }
}


