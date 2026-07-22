import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCheckin();
  }

  Future<void> _loadCheckin() async {
    try {
      final stats = await _api.request('/checkin/stats') as Map<String, dynamic>;
      if (mounted) setState(() {
        _checkinStreak = stats['currentStreak'] ?? 0;
        _checkedToday = _isToday(stats['lastCheckinDate'] as String?);
      });
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.4), width: 3)),
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

                  // 菜单
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Column(
                      children: [
                        _MenuItem(icon: Icons.emoji_events_outlined, title: '全国排行榜', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingPage()))),
                        _MenuItem(icon: Icons.favorite_border, title: '我的收藏', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()))),
                        _MenuItem(icon: Icons.edit_outlined, title: '修改昵称', onTap: () => _editNickname(context)),
                        _MenuItem(icon: Icons.share_outlined, title: '分享给好友', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享功能开发中...')))),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxxl),
                ],
              ),
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
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]),
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


