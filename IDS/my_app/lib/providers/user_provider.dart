import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  String? _username;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void setUsername(String? username) {
    _username = username;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _username = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with email and password
  Future<String?> register(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }
}
