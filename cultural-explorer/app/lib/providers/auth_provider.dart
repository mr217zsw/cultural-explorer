import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserInfo? _user;
  bool _loading = false;

  UserInfo? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      await _api.ensureLogin();
      await fetchProfile();
    } catch (_) {
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _api.request('/user/profile') as Map<String, dynamic>;
      _user = UserInfo.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfile({String? nickname}) async {
    try {
      final data = await _api.request('/user/profile', method: 'PUT', body: {'nickname': nickname});
      _user = UserInfo.fromJson(data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
