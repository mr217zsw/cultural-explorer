import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class QuizPage extends StatefulWidget {
  final String regionId, regionName;
  const QuizPage({super.key, required this.regionId, required this.regionName});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _api = ApiService();
  List<dynamic>? _questions;
  int _index = 0;
  final _answers = <Map<String, dynamic>>[];
  late final DateTime _started;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.request('/quiz/start', method: 'POST', body: {'regionId': widget.regionId}) as Map<String, dynamic>;
      if (mounted) setState(() => _questions = data['questions'] as List<dynamic>);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    }
  }

  Future<void> _answer(int selected) async {
    final q = _questions![_index] as Map<String, dynamic>;
    _answers.add({'questionId': q['id'], 'selectedIndex': selected});
    if (_index + 1 < _questions!.length) {
      setState(() => _index++);
      return;
    }
    try {
      final result = await _api.request('/quiz/complete', method: 'POST', body: {
        'regionId': widget.regionId,
        'answers': _answers,
        'timeSpent': DateTime.now().difference(_started).inSeconds,
      }) as Map<String, dynamic>;

      if (!mounted) return;
      final isCompleted = result['isCompleted'] == true;
      final correct = result['correctCount'] ?? 0;
      final total = result['totalQuestions'] ?? 0;
      final score = result['reward']?['earnedScore'] ?? 0;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Column(
            children: [
              Text(isCompleted ? '🏆' : '💪', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                isCompleted ? '闯关成功！' : '继续加油！',
                style: TextStyle(color: isCompleted ? AppTheme.success : AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('答对 $correct/$total 题', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: AppTheme.accent, size: 20),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text('+$score 积分', style: const TextStyle(fontSize: 16, color: AppTheme.accent, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
    }
  }

  List<Color> _optionColors(int index) {
    const colors = [
      Color(0xffe74c3c),
      Color(0xff3498db),
      Color(0xff2ecc71),
      Color(0xffe67e22),
    ];
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final list = _questions;
    if (list == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final q = list[_index] as Map<String, dynamic>;
    final progress = (_index + 1) / list.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.regionName} 闯关', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Column(
            children: [
              LinearProgressIndicator(value: progress, minHeight: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingSm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('第 ${_index + 1}/${list.length} 题', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 题干卡片
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.help_outline, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      q['question'] as String,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXxl),

            // 选项
            ...(q['options'] as List<dynamic>).asMap().entries.map((e) {
              final colors = _optionColors(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _answer(e.key),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [BoxShadow(color: Color(0x08d0c0a0), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors[e.key], colors[e.key].withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + e.key),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(
                              e.value as String,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
