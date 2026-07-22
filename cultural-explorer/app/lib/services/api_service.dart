import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<dynamic> request(String path, {String method = 'GET', Object? body}) async {
    final token = await getToken();
    final req = http.Request(method, Uri.parse('$apiBaseUrl$path'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..body = body == null ? '' : jsonEncode(body);
    final streamed = await req.send();
    final text = await streamed.stream.bytesToString();
    final payload = jsonDecode(text) as Map<String, dynamic>;
    if (streamed.statusCode >= 400) {
      throw Exception(payload['message'] ?? '请求失败');
    }
    return payload['data'];
  }

  Future<void> ensureLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) return;
    var deviceId = prefs.getString('deviceId');
    deviceId ??= 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('deviceId', deviceId);
    final data = await request('/auth/anonymous', method: 'POST', body: {'deviceId': deviceId}) as Map<String, dynamic>;
    await setToken(data['token'] as String);
  }
}
