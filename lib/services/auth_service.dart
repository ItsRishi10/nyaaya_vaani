import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple auth service storing users in SharedPreferences.
// NOTE: This is a lightweight local-only implementation for MVP/demo purposes.
// Do NOT use plaintext passwords or SharedPreferences for real production auth.

class AuthService extends ChangeNotifier {
  static const _prefsKeyUsers = 'nv_users';
  static const _prefsKeyCurrent = 'nv_current_user';

  Map<String, dynamic>? _currentUser;
  Map<String, Map<String, dynamic>> _users = {}; // username -> {password, isAdmin}

  AuthService() {
    _loadFromPrefs();
  }

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?['isAdmin'] == true;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsKeyUsers);
    if (usersJson != null) {
      final decoded = json.decode(usersJson) as Map<String, dynamic>;
      _users = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    }

    // Ensure a default admin user exists
    if (!_users.containsKey('Admin')) {
      _users['Admin'] = {'password': 'admin123', 'isAdmin': true};
      await _saveUsers(prefs);
    }

    if (!_users.containsKey('Rishi')) {
      _users['Rishi'] = {'password': 'rishi10', 'isAdmin': true};
      await _saveUsers(prefs);
    }

    final currentJson = prefs.getString(_prefsKeyCurrent);
    if (currentJson != null) {
      _currentUser = json.decode(currentJson) as Map<String, dynamic>;
    }

    notifyListeners();
  }

  Future<void> _saveUsers(SharedPreferences prefs) async {
    await prefs.setString(_prefsKeyUsers, json.encode(_users));
  }

  Future<void> _saveCurrent(SharedPreferences prefs) async {
    if (_currentUser == null) {
      await prefs.remove(_prefsKeyCurrent);
    } else {
      await prefs.setString(_prefsKeyCurrent, json.encode(_currentUser));
    }
  }

  Future<bool> register(String username, String password, {bool isAdmin = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_users.containsKey(username)) return false;
    _users[username] = {'password': password, 'isAdmin': isAdmin};
    await _saveUsers(prefs);
    // auto-login after registration
    _currentUser = {'username': username, 'isAdmin': isAdmin};
    await _saveCurrent(prefs);
    notifyListeners();
    return true;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = _users[username];
    if (entry == null) return false;
    if (entry['password'] != password) return false;
    _currentUser = {'username': username, 'isAdmin': entry['isAdmin'] == true};
    await _saveCurrent(prefs);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = null;
    await _saveCurrent(prefs);
    notifyListeners();
  }
}
