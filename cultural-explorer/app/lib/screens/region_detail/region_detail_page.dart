import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../quiz/quiz_page.dart';

class RegionDetailPage extends StatefulWidget {
  final String id;
  const RegionDetailPage({super.key, required this.id});
  @override
  State<RegionDetailPage> createState() => _RegionDetailPageState();
}

class _RegionDetailPageState extends State<RegionDetailPage> {
  final _api = ApiService();
  Map<String, dynamic>? _region;
  bool _isFavorited = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.request('/regions/${widget.id}') as Map<String, dynamic>;
      if (mounted) setState(() {
        _region = data;
        _isFavorited = data['isFavorited'] == true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _api.request('/regions/${widget.id}/favorite', method: 'POST');
      setState(() => _isFavorited = !_isFavorited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited ? '已收藏 ❤️' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final r = _region;
    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? const Center(child: Text('加载失败'))
              : CustomScrollView(
                  slivers: [
                    // 自定义 AppBar，支持滚动
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primary,
                                AppTheme.primaryLight.withValues(alpha: 0.7),
                                AppTheme.background,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              r['shortName'] as String? ?? '华',
                              style: const TextStyle(
                                fontSize: 64,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 基本信息
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 20, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_city, size: 18, color: AppTheme.primary),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Text(
                                      '省会：${r['capital'] ?? '-'}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: AppTheme.spacingLg),
                                    const Icon(Icons.map, size: 18, color: AppTheme.primary),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Text(
                                      '面积：${r['area'] ?? '-'}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingXs),
                                Row(
                                  children: [
                                    const Icon(Icons.people, size: 18, color: AppTheme.primary),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Text(
                                      '人口：${r['population'] ?? '-'}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),

                          // 简介
                          Text(r['description'] ?? '', style: theme.textTheme.bodyLarge),

                          // 记忆口诀
                          if (r['mnemonic'] != null) ...[
                            const SizedBox(height: AppTheme.spacingXl),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: AppTheme.mnemonicBg,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text('🤖', style: TextStyle(fontSize: 20)),
                                      SizedBox(width: AppTheme.spacingSm),
                                      Text(
                                        'AI 记忆口诀',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    r['mnemonic'] as String,
                                    style: const TextStyle(fontSize: 16, height: 1.8),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 分类内容
                          const SizedBox(height: AppTheme.spacingXl),
                          _buildSection(context, '🏔', '地理', r['geography'] as String?),
                          _buildSection(context, '🏯', '历史', r['history'] as String?),
                          _buildSection(context, '🎭', '文化', r['culture'] as String?),

                          // 地标
                          if (r['landmarks'] != null && (r['landmarks'] as List).isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingXl),
                            Text(
                              '📍 著名地标',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            ...(r['landmarks'] as List<dynamic>).map((lm) {
                              final landmark = lm as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                                padding: const EdgeInsets.all(AppTheme.spacingLg),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 12, offset: Offset(0, 2))],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.temple_buddhist, color: AppTheme.primary, size: 24),
                                    const SizedBox(width: AppTheme.spacingMd),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            landmark['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                          ),
                                          if ((landmark['description'] as String?)?.isNotEmpty == true) ...[
                                            const SizedBox(height: AppTheme.spacingXs),
                                            Text(
                                              landmark['description'] as String,
                                              style: theme.textTheme.bodyMedium,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          // 开始闯关按钮
                          const SizedBox(height: AppTheme.spacingXxxl),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizPage(
                                  regionId: widget.id,
                                  regionName: r['name'] as String,
                                ),
                              ),
                            ).then((_) => _load()),
                            icon: const Icon(Icons.quiz_outlined),
                            label: Text(
                              '开始闯关（${r['questionCount'] ?? 0}题）',
                              style: const TextStyle(fontSize: 17),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection(BuildContext context, String icon, String title, String? content) {
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppTheme.spacingSm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
