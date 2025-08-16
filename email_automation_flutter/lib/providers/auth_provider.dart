import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _emailKey = 'gmail_email';
  static const String _passwordKey = 'gmail_password';

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userEmail;
  String? _userPassword;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userPassword => _userPassword;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if credentials exist in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);
      final password = prefs.getString(_passwordKey);

      if (email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        _userEmail = email;
        _userPassword = password;
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      debugPrint('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Store credentials in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);

      _userEmail = email;
      _userPassword = password;
      _isAuthenticated = true;

      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);

      _userEmail = null;
      _userPassword = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);

      _userEmail = email;
      _userPassword = password;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update credentials error: $e');
      return false;
    }
  }
}
