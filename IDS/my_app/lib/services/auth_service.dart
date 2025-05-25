import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Register with email, password, and username
  static Future<String?> register(
      String email, String password, String username) async {
    try {
      // Check if username is already taken
      final usernameDoc = await _db.collection('usernames').doc(username).get();
      if (usernameDoc.exists) {
        return 'Username is already taken';
      }

      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save username
      await _db.collection('usernames').doc(username).set({
        'uid': result.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save user profile
      await _db.collection('users').doc(result.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'portfolioValue': 0.0,
        'totalInvestment': 0.0,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Get username for current user
  static Future<String?> getCurrentUsername() async {
    try {
      if (currentUser == null) return null;

      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      return doc.data()?['username'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Failed to sign out: ${e.toString()}',
      );
    }
  }
}
