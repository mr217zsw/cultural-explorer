import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');

void main() => runApp(const CulturalExplorerApp());

class ApiClient {
  String? token;

  Future<dynamic> request(String path, {String method = 'GET', Object? body}) async {
    final response = http.Request(method, Uri.parse('$apiBaseUrl$path'))
      ..headers.addAll({'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'})
      ..body = body == null ? '' : jsonEncode(body);
    final streamed = await response.send();
    final text = await streamed.stream.bytesToString();
    final payload = jsonDecode(text) as Map<String, dynamic>;
    if (streamed.statusCode >= 400) throw Exception(payload['message'] ?? '请求失败');
    return payload['data'];
  }

  Future<void> ensureLogin() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString('token');
    if (token != null) return;
    var deviceId = preferences.getString('deviceId');
    deviceId ??= 'flutter-${DateTime.now().microsecondsSinceEpoch}';
    await preferences.setString('deviceId', deviceId);
    final data = await request('/auth/anonymous', method: 'POST', body: {'deviceId': deviceId}) as Map<String, dynamic>;
    token = data['token'] as String;
    await preferences.setString('token', token!);
  }
}

final api = ApiClient();

class CulturalExplorerApp extends StatelessWidget {
  const CulturalExplorerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '华夏文化探索', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8b1e2d)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xfffffbf3)),
    home: const RegionListPage(),
  );
}

class RegionListPage extends StatefulWidget {
  const RegionListPage({super.key});
  @override State<RegionListPage> createState() => _RegionListPageState();
}

class _RegionListPageState extends State<RegionListPage> {
  final search = TextEditingController();
  List<dynamic> regions = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() => loading = true);
    await api.ensureLogin();
    final keyword = Uri.encodeQueryComponent(search.text.trim());
    final data = await api.request('/regions?limit=50&keyword=$keyword') as Map<String, dynamic>;
    if (mounted) setState(() { regions = data['items'] as List<dynamic>; loading = false; });
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('华夏文化探索'), centerTitle: true),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: SearchBar(controller: search, hintText: '搜索地区', leading: const Icon(Icons.search), onSubmitted: (_) => load(), trailing: [IconButton(onPressed: load, icon: const Icon(Icons.arrow_forward))])),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: regions.length,
        itemBuilder: (context, index) { final region = regions[index] as Map<String, dynamic>; return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegionDetailPage(id: region['id'] as String))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(region['shortName'] ?? '华', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xff8b1e2d))), const Spacer(), Text(region['name'], style: Theme.of(context).textTheme.titleLarge), Text(region['capital'] ?? '', style: Theme.of(context).textTheme.bodySmall)])))); },
      )))
    ]),
  );
}

class RegionDetailPage extends StatefulWidget {
  final String id;
  const RegionDetailPage({super.key, required this.id});
  @override State<RegionDetailPage> createState() => _RegionDetailPageState();
}

class _RegionDetailPageState extends State<RegionDetailPage> {
  Map<String, dynamic>? region;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final data = await api.request('/regions/${widget.id}') as Map<String, dynamic>; if (mounted) setState(() => region = data); }
  @override Widget build(BuildContext context) {
    final data = region;
    return Scaffold(appBar: AppBar(title: Text(data?['name'] ?? '地区详情')), body: data == null ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
      Text('${data['shortName'] ?? ''} · ${data['name']}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xff8b1e2d))),
      const SizedBox(height: 8), Text('省会：${data['capital'] ?? '-'}　面积：${data['area'] ?? '-'}'), const SizedBox(height: 20), Text(data['description']),
      const SectionTitle('地理'), Text(data['geography']), const SectionTitle('历史'), Text(data['history']), const SectionTitle('文化'), Text(data['culture']),
      if (data['mnemonic'] != null) ...[const SectionTitle('记忆口诀'), Card(color: const Color(0xffffefd2), child: Padding(padding: const EdgeInsets.all(16), child: Text(data['mnemonic'])))],
      const SectionTitle('代表地标'), ...(data['landmarks'] as List<dynamic>).map((item) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.temple_buddhist), title: Text(item['name']), subtitle: Text(item['description']))),
      const SizedBox(height: 20), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(regionId: widget.id, regionName: data['name']))), icon: const Icon(Icons.quiz), label: Text('开始闯关（${data['questionCount']}题）')),
    ]));
  }
}

class SectionTitle extends StatelessWidget {
  final String text; const SectionTitle(this.text, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleLarge));
}

class QuizPage extends StatefulWidget {
  final String regionId, regionName;
  const QuizPage({super.key, required this.regionId, required this.regionName});
  @override State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic>? questions; int index = 0; final answers = <Map<String, dynamic>>[]; final started = DateTime.now();
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final data = await api.request('/quiz/start', method: 'POST', body: {'regionId': widget.regionId}) as Map<String, dynamic>; if (mounted) setState(() => questions = data['questions']); }
  Future<void> answer(int selected) async {
    final question = questions![index] as Map<String, dynamic>;
    answers.add({'questionId': question['id'], 'selectedIndex': selected});
    if (index + 1 < questions!.length) { setState(() => index++); return; }
    final result = await api.request('/quiz/complete', method: 'POST', body: {'regionId': widget.regionId, 'answers': answers, 'timeSpent': DateTime.now().difference(started).inSeconds}) as Map<String, dynamic>;
    if (!mounted) return;
    await showDialog(context: context, builder: (_) => AlertDialog(title: Text(result['isCompleted'] ? '闯关成功' : '继续加油'), content: Text('答对 ${result['correctCount']}/${result['totalQuestions']} 题\n获得 ${result['reward']['earnedScore']} 积分'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('完成'))]));
    if (mounted) Navigator.pop(context);
  }
  @override Widget build(BuildContext context) {
    final list = questions;
    if (list == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final question = list[index] as Map<String, dynamic>;
    return Scaffold(appBar: AppBar(title: Text('${widget.regionName}闯关 ${index + 1}/${list.length}')), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(question['question'], style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 24), ...(question['options'] as List<dynamic>).asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 12), child: OutlinedButton(onPressed: () => answer(entry.key), child: Padding(padding: const EdgeInsets.all(14), child: Text(entry.value)))))])));
  }
}
