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
  int _lives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  bool _showFeedback = false;
  bool? _lastCorrect;
  String _lastExplanation = '';
  bool _quizFinished = false;
  String _grade = '';
  int? _difficulty;
  List<int> _multiSelected = [];

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const _optColors = [Color(0xffe74c3c), Color(0xff3498db), Color(0xff2ecc71), Color(0xffe67e22)];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _start(int diff) async {
    setState(() => _difficulty = diff);
    try {
      final data = await _api.request('/quiz/startV2', method: 'POST', body: {
        'regionId': widget.regionId,
        'difficulty': diff,
      }) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _questions = data['questions'] as List<dynamic>;
          _lives = data['lives'] ?? 3;
        });
      }
    } catch (_) {
      // fallback V1
      try {
        final data = await _api.request('/quiz/start', method: 'POST', body: {'regionId': widget.regionId});
        if (mounted) setState(() {
          _questions = (data as Map<String, dynamic>)['questions'] as List<dynamic>;
          _lives = 3;
        });
      } catch (_) { if (mounted) { Navigator.pop(context); } }
    }
  }

  void _submit(int answer) async {
    if (_showFeedback) return;
    try {
      final result = await _api.request('/quiz/submitV2', method: 'POST', body: {
        'questionId': (_questions![_index] as Map)['id'],
        'answer': answer,
      }) as Map<String, dynamic>?;
      if (result != null) _handleResult(result);
    } catch (_) {
      // V1 fallback
      _finishOld();
    }
  }

  void _handleResult(Map<String, dynamic> r) {
    final correct = r['isCorrect'] == true;
    setState(() {
      _lastCorrect = correct;
      _totalScore = (r['totalScore'] as int?) ?? _totalScore;
      _lives = (r['lives'] as int?) ?? _lives;
      _combo = (r['combo'] as int?) ?? _combo;
      if (_combo > _maxCombo) _maxCombo = _combo;
      if (correct) _correctCount++;
      _lastExplanation = r['explanation'] ?? '';
      _showFeedback = true;
      if (r['isGameOver'] == true) {
        _grade = r['grade'] ?? _calcGrade();
        _quizFinished = true;
      }
    });
  }

  void _next() {
    if (_quizFinished || _lives <= 0) {
      _finishQuiz();
      return;
    }
    if (_index + 1 >= _questions!.length) {
      _finishQuiz();
      return;
    }
    setState(() {
      _index++;
      _showFeedback = false;
      _lastCorrect = null;
      _multiSelected = [];
    });
  }

  void _finishOld() {
    if (_index + 1 < _questions!.length) { setState(() => _index++); return; }
    _finishQuiz();
  }

  void _finishQuiz() {
    setState(() {
      _quizFinished = true;
      _grade = _calcGrade();
    });
  }

  String _calcGrade() {
    if (_questions == null || _questions!.isEmpty) return 'C';
    final r = _correctCount / _questions!.length;
    if (r >= 0.95) return 'S';
    if (r >= 0.85) return 'A';
    if (r >= 0.70) return 'B';
    return 'C';
  }

  Widget _buildDifficultySelect() {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.regionName} 闯关')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择难度', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 8),
              const Text('每个难度对应不同的题量和规则', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              _diffCard(1, '🌿 简单', '基础题目，无生命限制，适合初学者'),
              const SizedBox(height: 12),
              _diffCard(2, '⚡ 中等', '3条命，答错扣命，挑战自我'),
              const SizedBox(height: 12),
              _diffCard(3, '🔥 困难', '经典模式，考验真功夫'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffCard(int d, String title, String desc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _start(d),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final emoji = {'S': '👑', 'A': '🏆', 'B': '💪', 'C': '📚'}[_grade] ?? '📚';
    final color = {'S': AppTheme.accent, 'A': AppTheme.success, 'B': Color(0xff3498db), 'C': AppTheme.textSecondary}[_grade]!;

    return Scaffold(
      appBar: AppBar(title: const Text('闯关结果')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(_grade, style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 24),
              _resultItem('答对', '$_correctCount/${_questions!.length}'),
              _resultItem('总得分', '$_totalScore 分'),
              _resultItem('最大连击', '$_maxCombo'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) return _buildDifficultySelect();
    if (_quizFinished) return _buildResult();

    final list = _questions;
    if (list == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final q = list[_index] as Map<String, dynamic>;
    final progress = (_index + 1) / list.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.regionName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: List.generate(3, (i) => Icon(i < _lives ? Icons.favorite : Icons.favorite_border, color: i < _lives ? Colors.red : Colors.grey.shade300, size: 18))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
                      child: Text('$_totalScore 分', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    if (_combo > 1) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                      child: Text('$_combo连击', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress, minHeight: 3),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_index + 1}/${list.length}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(q['type'] == 'multiple' ? '多选' : q['type'] == 'truefalse' ? '判断' : '单选', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _showFeedback ? _buildFeedback(q) : _buildQuestion(q),
    );
  }

  Widget _buildQuestion(Map q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  child: const Icon(Icons.help_outline, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: Text(q['question'] as String, style: Theme.of(context).textTheme.headlineSmall)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXxl),
          ...(q['options'] as List<dynamic>).asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _submit(e.key),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_optColors[e.key % 4], _optColors[e.key % 4].withOpacity(0.7)]),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          alignment: Alignment.center,
                          child: Text(_letters[e.key], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(child: Text(e.value as String, style: const TextStyle(fontSize: 16, height: 1.5))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedback(Map q) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _lastCorrect == true ? Icons.check_circle : Icons.cancel,
            size: 56,
            color: _lastCorrect == true ? AppTheme.success : Colors.red.shade400,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            _lastCorrect == true ? '回答正确！' : '回答错误',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _lastCorrect == true ? AppTheme.success : Colors.red.shade400),
          ),
          if (_lastCorrect != true) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '正确答案：${_letters[q['correctAnswer'] as int? ?? 0]}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.success),
            ),
          ],
          if (_lastExplanation.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(_lastExplanation, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
            ),
          ],
          const SizedBox(height: AppTheme.spacingXxl),
          FilledButton(
            onPressed: _next,
            child: Text((_quizFinished || _lives <= 0 || _index + 1 >= (_questions?.length ?? 0)) ? '查看结果' : '下一题', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
