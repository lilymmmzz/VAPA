import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Set initial user state
    _user = FirebaseAuth.instance.currentUser;

    // Listen to auth state changes but ONLY for sign-out events
    // Login success is handled manually in the login() method
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // Only process sign-out (user becomes null)
      // Sign-in is handled in login() to prevent reload on failed attempts
      if (user == null) {
        _user = null;
        notifyListeners();
      }
    });
  }

  // Register
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email, password);
      _user = FirebaseAuth.instance.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('=== REGISTER ERROR: ${e.code} ===');
      _errorMessage = e.code;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('=== REGISTER ERROR: $e ===');
      _errorMessage = e.toString();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login — manually sets user on success, keeps null on failure
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      // Only set user if login actually succeeded
      _user = FirebaseAuth.instance.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('=== LOGIN ERROR CODE: ${e.code} ===');
      // Keep _user as null — do NOT update it
      _errorMessage = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('=== LOGIN ERROR: $e ===');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
