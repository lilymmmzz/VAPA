import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _displayName;
  bool _hasCompletedSetup = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String? get displayName => _displayName;
  bool get hasCompletedSetup => _hasCompletedSetup;

  String get greeting {
    if (_displayName != null && _displayName!.isNotEmpty) return _displayName!;
    final email = _user?.email ?? '';
    if (email.isNotEmpty) {
      final raw = email.split('@')[0].split('.')[0];
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return 'there';
  }

  AuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) _loadUserProfile();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _user = null;
        _displayName = null;
        _hasCompletedSetup = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _displayName = doc.data()?['displayName'] as String?;
        _hasCompletedSetup = doc.data()?['hasCompletedSetup'] as bool? ?? false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('=== LOAD PROFILE ERROR: $e ===');
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.register(email, password);
      _user = FirebaseAuth.instance.currentUser;
      _hasCompletedSetup = false;
      _displayName = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('=== REGISTER ERROR: ${e.code} ===');
      _errorMessage = e.code;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('=== REGISTER ERROR: $e ===');
      _errorMessage = e.toString();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.login(email, password);
      _user = FirebaseAuth.instance.currentUser;
      _isLoading = false;
      await _loadUserProfile();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('=== LOGIN ERROR CODE: ${e.code} ===');
      _errorMessage = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('=== LOGIN ERROR: $e ===');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'displayName': name,
        'hasCompletedSetup': true,
      }, SetOptions(merge: true));
      _displayName = name;
      _hasCompletedSetup = true;
      notifyListeners();
    } catch (e) {
      debugPrint('=== UPDATE NAME ERROR: $e ===');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _displayName = null;
    _hasCompletedSetup = false;
    notifyListeners();
  }
}