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
  List<dynamic> _chapters = [];
  List<dynamic> _timeline = [];
  List<dynamic> _cuisines = [];
  List<dynamic> _heritages = [];
  bool _isFavorited = false;
  bool _loading = true;

  final _tabIcons = {
    '印象': '🌄', '地理': '🏔', '历史': '🏯', '时光': '🏯',
    '文化': '🎭', '传承': '🎭', '风物': '🏔', '初见': '🌄',
    '探索': '📍', '足迹': '📍',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.request('/regions/${widget.id}') as Future<Map<String, dynamic>>,
        _api.request('/regions/${widget.id}/chapters') as Future<List<dynamic>>,
        _api.request('/regions/${widget.id}/timeline') as Future<List<dynamic>>,
        _api.request('/regions/${widget.id}/cuisine') as Future<List<dynamic>>,
        _api.request('/regions/${widget.id}/heritage') as Future<List<dynamic>>,
      ]);
      if (mounted) {
        setState(() {
          _region = results[0] as Map<String, dynamic>;
          _chapters = (results[1] as List<dynamic>?) ?? [];
          _timeline = (results[2] as List<dynamic>?) ?? [];
          _cuisines = (results[3] as List<dynamic>?) ?? [];
          _heritages = (results[4] as List<dynamic>?) ?? [];
          _isFavorited = _region!['isFavorited'] == true;
          _loading = false;
        });
      }
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
          SnackBar(content: Text(_isFavorited ? '已收藏 ❤️' : '已取消收藏'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: const Center(child: CircularProgressIndicator()));
    final r = _region;
    if (r == null) return Scaffold(body: const Center(child: Text('加载失败')),);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(r),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildBasicInfo(r),
                const SizedBox(height: AppTheme.spacingXl),
                if (_chapters.isNotEmpty) _buildChapters(),
                if (_timeline.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildTimeline(),
                ],
                if (r['famousPeople'] != null && (r['famousPeople'] as List).isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildFamousPeople(r['famousPeople'] as List),
                ],
                if (_cuisines.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildCuisines(),
                ],
                if (_heritages.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildHeritages(),
                ],
                if (r['mnemonic'] != null && (r['mnemonic'] as String).isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildMnemonic(r),
                ],
                const SizedBox(height: AppTheme.spacingXl),
                _buildAudioSection(r),
                const SizedBox(height: AppTheme.spacingXl),
                _buildQuizButton(r),
                const SizedBox(height: AppTheme.spacingXxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar ──
  Widget _buildSliverAppBar(Map<String, dynamic> r) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (r['heroImage'] != null)
              Image.network(r['heroImage'] as String, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: Center(
                  child: Text(
                    (r['shortName'] ?? '华') as String,
                    style: const TextStyle(fontSize: 72, color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)]))),
          ],
        ),
      ),
      actions: [
        if (r['audioGuide'] != null || r['audioShort'] != null)
          IconButton(icon: const Icon(Icons.headphones), tooltip: 'AI 导览', onPressed: () => _showAudioDialog(r)),
        IconButton(icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border, color: _isFavorited ? Colors.red : Colors.white), onPressed: _toggleFavorite),
      ],
    );
  }

  // ── 基本信息卡片 ──
  Widget _buildBasicInfo(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r['description'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: [
              if (r['capital'] != null) _infoChip('📍', '${r['capital']}'),
              if (r['area'] != null) _infoChip('🗺️', '${r['area']}'),
              if (r['population'] != null) _infoChip('👥', '${r['population']}'),
              if (r['region'] != null) _infoChip('🧭', '${r['region']}'),
              if (r['ancientName'] != null) _infoChip('📜', '古称 ${r['ancientName']}'),
              if (r['foundingYear'] != null) _infoChip('🏛️', '建制 ${r['foundingYear']}'),
              if (r['dialects'] != null) _infoChip('🗣️', '${r['dialects']}'.length > 20 ? '${r['dialects']}'.substring(0, 20) : '${r['dialects']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      child: Text('$icon $text', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  // ── 章节 ──
  Widget _buildChapters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('📖', style: TextStyle(fontSize: 20)), const SizedBox(width: AppTheme.spacingSm), Text('内容章节', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: AppTheme.spacingMd),
        ...(_chapters).map((ch) {
          final c = ch as Map<String, dynamic>;
          final title = c['title'] as String? ?? '';
          String icon = '📄';
          for (final entry in _tabIcons.entries) {
            if (title.contains(entry.key)) { icon = entry.value; break; }
          }
          return _chapterCard(icon, title, c['subtitle'] as String?, c['content'] as String?, c['audioUrl'] as String?);
        }),
      ],
    );
  }

  Widget _chapterCard(String icon, String title, String? subtitle, String? content, String? audioUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primary))),
              if (audioUrl != null) IconButton(icon: const Icon(Icons.volume_up, color: AppTheme.accent, size: 22), onPressed: () => _playAudio(audioUrl), constraints: const BoxConstraints()),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(content, style: Theme.of(context).textTheme.bodyLarge, maxLines: 6, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ── 历史时间轴 ──
  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('⏳', style: TextStyle(fontSize: 20)), const SizedBox(width: AppTheme.spacingSm), Text('历史时间轴', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: AppTheme.spacingMd),
        ..._timeline.map((ev) {
          final e = ev as Map<String, dynamic>;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: AppTheme.accent, width: 2))),
                    Container(width: 2, height: 60, color: AppTheme.primary.withValues(alpha: 0.2)),
                  ],
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4)), child: Text(e['year'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                            if (e['dynasty'] != null) ...[const SizedBox(width: AppTheme.spacingSm), Text('${e['dynasty']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))],
                          ]),
                          const SizedBox(height: 4),
                          Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          if (e['description'] != null) ...[
                            const SizedBox(height: 2),
                            Text(e['description'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        // Last dot without line
        Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)), const SizedBox(width: AppTheme.spacingMd), const Text('至今', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))]),
      ],
    );
  }

  // ── 历史名人 ──
  Widget _buildFamousPeople(List people) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('⭐', style: TextStyle(fontSize: 20)), const SizedBox(width: AppTheme.spacingSm), Text('人物·星光', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingMd),
            itemBuilder: (_, i) {
              final p = people[i] as Map<String, dynamic>;
              return SizedBox(
                width: 160,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 8)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: Text((p['name'] as String? ?? '?')[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                      if (p['title'] != null) Text('${p['title']}', style: const TextStyle(fontSize: 11, color: AppTheme.accent), textAlign: TextAlign.center),
                      if (p['dynasty'] != null) Text('${p['dynasty']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                      if (p['description'] != null) ...[
                        const SizedBox(height: 4),
                        Expanded(child: Text(p['description'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 美食 ──
  Widget _buildCuisines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('🍜', style: TextStyle(fontSize: 20)), const SizedBox(width: AppTheme.spacingSm), Text('特色美食', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: AppTheme.spacingMd),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: _cuisines.map((cu) {
            final c = cu as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              width: (MediaQuery.of(context).size.width - AppTheme.spacingXl * 2 - AppTheme.spacingSm) / 2,
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 4)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (c['category'] != null) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text('${c['category']}', style: const TextStyle(fontSize: 10, color: AppTheme.accent)))],
                  ]),
                  const SizedBox(height: 4),
                  Text(c['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 非物质文化遗产 ──
  Widget _buildHeritages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('🏛️', style: TextStyle(fontSize: 20)), const SizedBox(width: AppTheme.spacingSm), Text('非物质文化遗产', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: AppTheme.spacingMd),
        ..._heritages.map((h) {
          final item = h as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 4)]),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.radiusSm)), alignment: Alignment.center, child: Text('${item['name']}'[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary))),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (item['level'] != null) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(4)), child: Text('${item['level']}', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)))],
                      ]),
                      const SizedBox(height: 2),
                      Text(item['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── AI 记忆口诀 ──
  Widget _buildMnemonic(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(color: AppTheme.mnemonicBg, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('🤖', style: TextStyle(fontSize: 20)), SizedBox(width: AppTheme.spacingSm), Text('AI 记忆口诀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
          const SizedBox(height: AppTheme.spacingMd),
          Text(r['mnemonic'] as String, style: const TextStyle(fontSize: 16, height: 1.8)),
        ],
      ),
    );
  }

  // ── 音频导览 ──
  Widget _buildAudioSection(Map<String, dynamic> r) {
    final fullAudio = r['audioGuide'] as String?;
    final shortAudio = r['audioShort'] as String?;
    if (fullAudio == null && shortAudio == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 12)]),
      child: Row(children: [
        const Icon(Icons.headphones, color: AppTheme.primary, size: 32),
        const SizedBox(width: AppTheme.spacingMd),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI 语音导览', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('了解这片土地的故事', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))])),
        if (shortAudio != null)
          TextButton.icon(onPressed: () => _playAudio(shortAudio), icon: const Icon(Icons.play_circle_outline, size: 20), label: const Text('精华版', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: AppTheme.primary)),
        if (fullAudio != null)
          TextButton.icon(onPressed: () => _playAudio(fullAudio), icon: const Icon(Icons.play_circle_filled, size: 20), label: const Text('完整版', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: AppTheme.accent)),
      ]),
    );
  }

  void _showAudioDialog(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI 语音导览'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (r['audioShort'] != null)
            ListTile(leading: const Icon(Icons.play_circle_outline, color: AppTheme.primary), title: const Text('精华版 (1-2分钟)'), onTap: () { Navigator.pop(context); _playAudio(r['audioShort'] as String); }),
          if (r['audioGuide'] != null)
            ListTile(leading: const Icon(Icons.play_circle_filled, color: AppTheme.accent), title: const Text('完整版 (5-8分钟)'), onTap: () { Navigator.pop(context); _playAudio(r['audioGuide'] as String); }),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }

  void _playAudio(String url) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('音频播放功能开发中，URL已就绪'), duration: Duration(seconds: 2)));
  }

  // ── 开始闯关 ──
  Widget _buildQuizButton(Map<String, dynamic> r) {
    return FilledButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(regionId: widget.id, regionName: r['name'] as String))).then((_) => _load()),
      icon: const Icon(Icons.quiz_outlined),
      label: Text('开始闯关 (${r['questionCount'] ?? 0}题)', style: const TextStyle(fontSize: 17)),
    );
  }
}
