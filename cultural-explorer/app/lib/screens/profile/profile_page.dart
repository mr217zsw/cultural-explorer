import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../ranking/ranking_page.dart';
import '../favorites/favorites_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: user != null ? () => _editNickname(context) : null,
            tooltip: '修改昵称',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 头部区域 - 渐变背景
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingXl,
                      AppTheme.spacingXl,
                      AppTheme.spacingXl,
                      AppTheme.spacingXxxl,
                    ),
                    child: Column(
                      children: [
                        // 头像
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.nickname?.isNotEmpty == true ? user.nickname![0] : '华',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          user.nickname ?? '匿名探索者',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (user.nickname?.isNotEmpty != true) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          GestureDetector(
                            onTap: () => _editNickname(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLg,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 14, color: Colors.white70),
                                  SizedBox(width: AppTheme.spacingXs),
                                  Text('点击设置昵称', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 统计卡片（上移形成叠加效果）
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingXl,
                    ),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.stars,
                          label: '总积分',
                          value: '${user.totalScore}',
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          label: '已通关',
                          value: '${user.completedCount}/34',
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        _StatCard(
                          icon: Icons.local_fire_department,
                          label: '最长连胜',
                          value: '${user.maxStreak}',
                          color: const Color(0xff3498db),
                        ),
                      ],
                    ),
                  ),

                  // 功能菜单
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Column(
                      children: [
                        _MenuItem(
                          icon: Icons.emoji_events_outlined,
                          title: '全国排行榜',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingPage())),
                        ),
                        _MenuItem(
                          icon: Icons.favorite_border,
                          title: '我的收藏',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
                        ),
                        _MenuItem(
                          icon: Icons.share_outlined,
                          title: '分享给好友',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('分享功能开发中...')),
                            );
                          },
                        ),
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
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '请输入昵称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await context.read<AuthProvider>().updateProfile(nickname: ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingLg,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 22),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


