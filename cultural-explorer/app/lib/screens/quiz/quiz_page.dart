import 'dart:async';
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
  String _correctInfo = '';
  bool _quizFinished = false;
  String _grade = '';
  int? _difficulty;
  List<int> _multiSelected = [];
  Timer? _timer;
  int _timeLeft = 30;
  String? _hintText;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const _optColors = [Color(0xffe74c3c), Color(0xff3498db), Color(0xff2ecc71), Color(0xffe67e22)];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _timeLeft = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _autoSubmit();
        }
      });
    });
  }

  void _autoSubmit() {
    final q = _questions![_index] as Map<String, dynamic>;
    final qType = q['type'] as String? ?? 'single';
    if (qType == 'multiple') {
      _submitMultiAnswer();
    } else {
      _submit(-1);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _hintText = null;
  }

  Future<void> _start(int diff) async {
    setState(() => _difficulty = diff);
    try {
      final data = await _api.request('/quiz/startV2', method: 'POST', body: {'regionId': widget.regionId, 'difficulty': diff}) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _questions = data['questions'] as List<dynamic>;
          _lives = data['lives'] ?? 3;
        });
        final firstQ = _questions!.isNotEmpty ? _questions![0] as Map<String, dynamic> : null;
        _startTimer((data['questions'] as List).isNotEmpty ? ((firstQ?['timeLimit'] as int?) ?? 30) : 30);
      }
    } catch (_) {
      try {
        final data = await _api.request('/quiz/start', method: 'POST', body: {'regionId': widget.regionId});
        if (mounted) {
          setState(() {
            _questions = (data as Map<String, dynamic>)['questions'] as List<dynamic>;
            _lives = 3;
          });
          _startTimer(30);
        }
      } catch (_) { if (mounted) Navigator.pop(context); }
    }
  }

  Future<void> _submit(int answer) async {
    if (_showFeedback) return;
    _cancelTimer();
    try {
      final q = _questions![_index] as Map<String, dynamic>;
      final result = await _api.request('/quiz/submitV2', method: 'POST', body: {'questionId': q['id'], 'answer': answer}) as Map<String, dynamic>?;
      if (result != null) _handleResult(result);
    } catch (_) {
      if (_index + 1 < _questions!.length) {
        setState(() => _index++);
        _startNextTimer();
      } else {
        _finishQuiz();
      }
    }
  }

  void _toggleMulti(int i) {
    if (_showFeedback) return;
    setState(() {
      if (_multiSelected.contains(i)) { _multiSelected.remove(i); }
      else { _multiSelected.add(i); }
    });
  }

  Future<void> _submitMultiAnswer() async {
    if (_multiSelected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请至少选择 2 个选项')));
      return;
    }
    _cancelTimer();
    try {
      final q = _questions![_index] as Map<String, dynamic>;
      final result = await _api.request('/quiz/submitV2', method: 'POST', body: {'questionId': q['id'], 'answer': _multiSelected}) as Map<String, dynamic>?;
      if (result != null) _handleResult(result);
      _multiSelected = [];
    } catch (_) {
      if (_index + 1 < _questions!.length) {
        setState(() => _index++);
        _startNextTimer();
      } else {
        _finishQuiz();
      }
    }
  }

  Future<void> _getHint() async {
    if (_showFeedback) return;
    try {
      final q = _questions![_index] as Map<String, dynamic>;
      final result = await _api.request('/quiz/hint', method: 'POST', body: {'questionId': q['id']}) as Map<String, dynamic>?;
      if (result != null && mounted) {
        setState(() => _hintText = result['hint'] as String?);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提示消耗 ${result['cost']} 积分')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _startNextTimer() {
    final nextQ = _questions!.isNotEmpty && _index < _questions!.length ? _questions![_index] as Map<String, dynamic> : null;
    _startTimer((nextQ?['timeLimit'] as int?) ?? 30);
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
      if (r['correctAnswer'] != null) {
        final ca = r['correctAnswer'];
        _correctInfo = ca is int ? _letters[ca] : ca is List ? ca.map((i) => _letters[i as int]).join(', ') : '$ca';
      }
      _showFeedback = true;
      if (r['isGameOver'] == true) {
        _grade = r['grade'] ?? _calcGrade();
        _quizFinished = true;
      }
    });
  }

  void _next() {
    if (_quizFinished || _lives <= 0) { _finishQuiz(); return; }
    if (_index + 1 >= _questions!.length) { _finishQuiz(); return; }
    setState(() {
      _index++;
      _showFeedback = false;
      _lastCorrect = null;
      _multiSelected = [];
    });
    _startNextTimer();
  }

  void _finishQuiz() {
    _cancelTimer();
    setState(() { _quizFinished = true; _grade = _calcGrade(); });
  }

  String _calcGrade() {
    if (_questions == null || _questions!.isEmpty) return 'C';
    final r = _correctCount / _questions!.length;
    if (r >= 0.95) return 'S';
    if (r >= 0.85) return 'A';
    if (r >= 0.70) return 'B';
    return 'C';
  }

  // ── 难度选择 ──
  Widget _buildDifficultySelect() {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.regionName} 闯关')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('选择难度', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 8),
            const Text('每个难度对应不同的规则', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            _diffCard(1, '🌿 简单', '基础题目，30秒/题，适合入门'),
            const SizedBox(height: 12),
            _diffCard(2, '⚡ 中等', '3条命，25秒/题，挑战自我'),
            const SizedBox(height: 12),
            _diffCard(3, '🔥 困难', '3条命，20秒/题，考验真功夫'),
          ]),
        ),
      ),
    );
  }

  Widget _diffCard(int d, String title, String desc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _start(d),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(AppTheme.spacingLg), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }

  // ── 结果页 ──
  Widget _buildResult() {
    final gradeEmoji = {'S': '👑', 'A': '🏆', 'B': '💪', 'C': '📚'}[_grade] ?? '📚';
    final gradeColor = {'S': AppTheme.accent, 'A': AppTheme.success, 'B': const Color(0xff3498db), 'C': AppTheme.textSecondary}[_grade]!;
    return Scaffold(
      appBar: AppBar(title: const Text('闯关结果')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(gradeEmoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(_grade, style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: gradeColor)),
            const SizedBox(height: 24),
            _resultItem('答对', '$_correctCount/${_questions!.length}'),
            _resultItem('总得分', '$_totalScore 分'),
            _resultItem('最大连击', '$_maxCombo'),
            const SizedBox(height: 32),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('完成', style: TextStyle(fontSize: 16))),
          ]),
        ),
      ),
    );
  }

  Widget _resultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── 主页面 ──
  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) return _buildDifficultySelect();
    if (_quizFinished) return _buildResult();

    final list = _questions;
    if (list == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final q = list[_index] as Map<String, dynamic>;
    final progress = (_index + 1) / list.length;
    final qType = q['type'] as String? ?? 'single';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.regionName, style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: List.generate(3, (i) => Icon(i < _lives ? Icons.favorite : Icons.favorite_border, color: i < _lives ? Colors.red : Colors.grey.shade300, size: 18))),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: _timeLeft <= 5 ? Colors.red.shade400 : AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer, size: 14, color: _timeLeft <= 5 ? Colors.white : AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('${_timeLeft}s', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.white : AppTheme.primary)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
                  child: Text('$_totalScore 分', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                if (_combo > 1)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)), child: Text('$_combo连击', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress, minHeight: 3),
              const SizedBox(height: 2),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_index + 1}/${list.length}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text(qType == 'multiple' ? '多选' : qType == 'truefalse' ? '判断' : '单选', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ]),
          ),
        ),
      ),
      body: _showFeedback ? _buildFeedback(q) : _buildQuestion(q, qType),
    );
  }

  Widget _buildQuestion(Map q, String qType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // 题干
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: const [BoxShadow(color: Color(0x0d502814), blurRadius: 16, offset: Offset(0, 4))]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(AppTheme.spacingSm), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.radiusSm)), child: const Icon(Icons.help_outline, color: AppTheme.primary, size: 22)),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(child: Text(q['question'] as String, style: Theme.of(context).textTheme.headlineSmall)),
          ]),
        ),

        // 提示文字
        if (_hintText != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(color: const Color(0xfffff3cd), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Row(children: [const Text('💡 ', style: TextStyle(fontSize: 16)), Expanded(child: Text(_hintText!, style: const TextStyle(fontSize: 14, color: Color(0xff856404)))), IconButton(icon: const Icon(Icons.close, size: 16, color: Color(0xff856404)), onPressed: () => setState(() => _hintText = null), constraints: const BoxConstraints())]),
          ),
        ],

        const SizedBox(height: AppTheme.spacingXxl),

        // 选项
        if (qType == 'multiple')
          ..._buildMultiOptions(q)
        else
          ..._buildSingleOptions(q),

        // 提示按钮
        if (!_showFeedback) ...[
          const SizedBox(height: AppTheme.spacingXl),
          Center(
            child: TextButton.icon(
              onPressed: _getHint,
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('获取提示 (-5积分)', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            ),
          ),
        ],
      ]),
    );
  }

  List<Widget> _buildSingleOptions(Map q) {
    final options = q['options'] as List<dynamic>;
    return options.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _submit(e.key),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(gradient: LinearGradient(colors: [_optColors[e.key % 4], _optColors[e.key % 4].withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(AppTheme.radiusSm)), alignment: Alignment.center, child: Text(_letters[e.key], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: Text(e.value as String, style: const TextStyle(fontSize: 16, height: 1.5))),
              ]),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildMultiOptions(Map q) {
    final options = q['options'] as List<dynamic>;
    final widgets = options.asMap().entries.map((e) {
      final selected = _multiSelected.contains(e.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleMulti(e.key),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade200, width: selected ? 2 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: selected ? AppTheme.primary : _optColors[e.key % 4].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  alignment: Alignment.center,
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : Text(_letters[e.key], style: TextStyle(color: _optColors[e.key % 4], fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: Text(e.value as String, style: const TextStyle(fontSize: 16, height: 1.5))),
              ]),
            ),
          ),
        ),
      );
    }).toList();

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacingSm),
        child: FilledButton.icon(
          onPressed: _multiSelected.length >= 2 ? _submitMultiAnswer : null,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text('确认提交 (已选 ${_multiSelected.length} 项)', style: const TextStyle(fontSize: 16)),
        ),
      ),
    );

    return widgets;
  }

  Widget _buildFeedback(Map q) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Icon(_lastCorrect == true ? Icons.check_circle : Icons.cancel, size: 56, color: _lastCorrect == true ? AppTheme.success : Colors.red.shade400),
        const SizedBox(height: AppTheme.spacingLg),
        Text(_lastCorrect == true ? '回答正确！' : '回答错误', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _lastCorrect == true ? AppTheme.success : Colors.red.shade400)),
        if (_lastCorrect != true) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text('正确答案：$_correctInfo', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppTheme.success)),
        ],
        if (_lastExplanation.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingLg),
          Container(padding: const EdgeInsets.all(AppTheme.spacingLg), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(AppTheme.radiusMd)), child: Text(_lastExplanation, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6))),
        ],
        const SizedBox(height: AppTheme.spacingXxl),
        FilledButton(
          onPressed: _next,
          child: Text((_quizFinished || _lives <= 0 || _index + 1 >= (_questions?.length ?? 0)) ? '查看结果' : '下一题', style: const TextStyle(fontSize: 16)),
        ),
      ]),
    );
  }
}
