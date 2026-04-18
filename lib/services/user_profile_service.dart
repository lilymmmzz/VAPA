import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the user's display name from Firestore
  /// Falls back to email prefix if not set
  static Future<String> getDisplayName(String userId, {String? email}) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['firstName'] != null && (data['firstName'] as String).isNotEmpty) {
          return data['firstName'] as String;
        }
      }
    } catch (e) {
      // Fall through to email fallback
    }
    // Fallback to email prefix
    if (email != null && email.isNotEmpty) {
      final raw = email.split('@')[0].split('.')[0];
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return 'there';
  }

  /// Get full user profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Check if onboarding is complete
  static Future<bool> isOnboardingComplete(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['onboardingComplete'] == true;
      }
    } catch (e) {
      return true; // Don't block existing users
    }
    return false;
  }
}