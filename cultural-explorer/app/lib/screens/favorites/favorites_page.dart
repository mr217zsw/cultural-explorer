import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../home/home_page.dart';
import '../region_detail/region_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _regions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ApiService().ensureLogin();
    try {
      final data = await ApiService().request('/regions?limit=100');
      if (mounted) {
        setState(() {
          _regions = ((data as Map<String, dynamic>)['items'] as List<dynamic>)
              .where((r) => (r as Map<String, dynamic>)['isFavorited'] == true)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('❤️ 收藏列表')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _regions.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary),
                          SizedBox(height: AppTheme.spacingLg),
                          Text('还没有收藏任何地区，快去探索吧！', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
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
    );
  }
}
