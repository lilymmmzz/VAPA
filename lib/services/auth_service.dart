import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      rethrow; // <-- THIS IS REQUIRED
    } catch (e) {
      throw Exception("unknown-error");
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow; // <-- REQUIRED
    } catch (e) {
      throw Exception("unknown-error");
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow; // <-- REQUIRED
    } catch (e) {
      throw Exception("unknown-error");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
