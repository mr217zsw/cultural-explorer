import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../region_detail/region_detail_page.dart';
import '../profile/profile_page.dart';
import '../ranking/ranking_page.dart';
import '../favorites/favorites_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  final _api = ApiService();
  List<dynamic> _regions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final keyword = Uri.encodeQueryComponent(_searchCtrl.text.trim());
      final data = await _api.request('/regions?limit=50&keyword=$keyword') as Map<String, dynamic>;
      if (mounted) setState(() { _regions = (data['items'] as List<dynamic>?) ?? []; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏮', style: TextStyle(fontSize: 20)),
            SizedBox(width: AppTheme.spacingSm),
            Text('华夏文化探索', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
              ),
              if (auth.user != null && auth.user!.totalScore > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${auth.user!.totalScore}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingPage())),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingSm,
            ),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: '搜索地区...',
              leading: const Icon(Icons.search, color: AppTheme.textSecondary),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(AppTheme.surface),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  side: BorderSide(color: colors.outline.withValues(alpha: 0.15)),
                ),
              ),
              onSubmitted: (_) => _load(),
              trailing: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.search, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _regions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.explore_outlined, size: 64, color: AppTheme.textSecondary),
                                    SizedBox(height: AppTheme.spacingLg),
                                    Text('暂无地区数据', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spacingLg,
                              AppTheme.spacingSm,
                              AppTheme.spacingLg,
                              AppTheme.spacingXxl,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.05,
                              crossAxisSpacing: AppTheme.spacingMd,
                              mainAxisSpacing: AppTheme.spacingMd,
                            ),
                            itemCount: _regions.length,
                            itemBuilder: (_, i) {
                              final r = _regions[i] as Map<String, dynamic>;
                              return RegionCard(
                                name: r['name'] ?? '',
                                shortName: r['shortName'] ?? '',
                                capital: r['capital'] ?? '',
                                completed: r['userProgress']?['isCompleted'] == true,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RegionDetailPage(id: r['id'] as String)),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 可复用的地区卡片组件
class RegionCard extends StatelessWidget {
  final String name, shortName, capital;
  final bool completed;
  final VoidCallback onTap;

  const RegionCard({
    super.key,
    required this.name,
    required this.shortName,
    required this.capital,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                AppTheme.background,
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortName.isNotEmpty ? shortName : '华',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  if (capital.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(capital, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
              if (completed)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text('已通关', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
