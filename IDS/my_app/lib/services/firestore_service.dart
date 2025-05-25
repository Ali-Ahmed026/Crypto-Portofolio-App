import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/portfolio_item.dart';

/// Exception thrown when a Firestore operation fails
class FirestoreException implements Exception {
  final String message;
  final dynamic originalError;

  FirestoreException(this.message, [this.originalError]);

  @override
  String toString() =>
      'FirestoreException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

/// Service class for handling Firestore operations
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Collection reference for user watchlists
  static final CollectionReference<Map<String, dynamic>> _watchlists =
      _db.collection('user_watchlists');

  /// Retrieves the user's watchlist of cryptocurrency IDs
  ///
  /// [uid] The user's ID
  /// Returns a list of coin IDs in the user's watchlist
  /// Throws [FirestoreException] if the operation fails
  static Future<List<String>> getUserWatchlist(String uid) async {
    try {
      if (uid.isEmpty) {
        throw FirestoreException('User ID cannot be empty');
      }

      final DocumentSnapshot<Map<String, dynamic>> doc = await _watchlists
          .doc(uid)
          .get() as DocumentSnapshot<Map<String, dynamic>>;

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null) {
        return [];
      }

      final List<dynamic>? coins = data['coins'];
      if (coins == null) {
        return [];
      }

      return coins.map((coin) => coin.toString()).toList();
    } catch (e) {
      if (e is FirestoreException) {
        rethrow;
      }
      throw FirestoreException('Failed to get watchlist', e);
    }
  }

  /// Adds a cryptocurrency to the user's watchlist
  ///
  /// [uid] The user's ID
  /// [coinId] The ID of the cryptocurrency to add
  /// Throws [FirestoreException] if the operation fails
  static Future<void> addCoinToWatchlist(String uid, String coinId) async {
    try {
      if (uid.isEmpty) {
        throw FirestoreException('User ID cannot be empty');
      }
      if (coinId.isEmpty) {
        throw FirestoreException('Coin ID cannot be empty');
      }

      final docRef = _watchlists.doc(uid);
      await docRef.set({
        'coins': FieldValue.arrayUnion([coinId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (e is FirestoreException) {
        rethrow;
      }
      throw FirestoreException('Failed to add coin to watchlist', e);
    }
  }

  /// Removes a cryptocurrency from the user's watchlist
  ///
  /// [uid] The user's ID
  /// [coinId] The ID of the cryptocurrency to remove
  /// Throws [FirestoreException] if the operation fails
  static Future<void> removeCoinFromWatchlist(String uid, String coinId) async {
    try {
      if (uid.isEmpty) {
        throw FirestoreException('User ID cannot be empty');
      }
      if (coinId.isEmpty) {
        throw FirestoreException('Coin ID cannot be empty');
      }

      final docRef = _watchlists.doc(uid);
      await docRef.update({
        'coins': FieldValue.arrayRemove([coinId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirestoreException) {
        rethrow;
      }
      throw FirestoreException('Failed to remove coin from watchlist', e);
    }
  }

  /// Checks if a coin exists in the user's watchlist
  ///
  /// [uid] The user's ID
  /// [coinId] The ID of the cryptocurrency to check
  /// Returns true if the coin is in the watchlist, false otherwise
  /// Throws [FirestoreException] if the operation fails
  static Future<bool> isInWatchlist(String uid, String coinId) async {
    try {
      if (uid.isEmpty) {
        throw FirestoreException('User ID cannot be empty');
      }
      if (coinId.isEmpty) {
        throw FirestoreException('Coin ID cannot be empty');
      }

      final List<String> watchlist = await getUserWatchlist(uid);
      return watchlist.contains(coinId);
    } catch (e) {
      if (e is FirestoreException) {
        rethrow;
      }
      throw FirestoreException('Failed to check watchlist', e);
    }
  }

  // Portfolio Operations
  static Future<List<PortfolioItem>> getUserPortfolio(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .get();

      return snapshot.docs
          .map((doc) => PortfolioItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to load portfolio', e);
    }
  }

  static Future<void> addTransaction(String userId, PortfolioItem item) async {
    try {
      // Check if the coin already exists in portfolio
      final existingDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .where('symbol', isEqualTo: item.symbol)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        // Update existing holding
        final doc = existingDoc.docs.first;
        final existing = PortfolioItem.fromJson(doc.data());

        final updatedItem = PortfolioItem(
          symbol: item.symbol,
          quantity: existing.quantity + item.quantity,
          investmentAmount: existing.investmentAmount + item.investmentAmount,
          currentValue: existing.currentValue + item.currentValue,
        );

        await doc.reference.update(updatedItem.toJson());
      } else {
        // Add new holding
        await _db
            .collection('users')
            .doc(userId)
            .collection('portfolio')
            .add(item.toJson());
      }

      // Update user's total portfolio value
      await _updateUserPortfolioValue(userId);
    } catch (e) {
      throw FirestoreException('Failed to add transaction', e);
    }
  }

  static Future<void> _updateUserPortfolioValue(String userId) async {
    try {
      final portfolio = await getUserPortfolio(userId);
      double totalValue = 0;
      double totalInvestment = 0;

      for (var item in portfolio) {
        totalValue += item.currentValue;
        totalInvestment += item.investmentAmount;
      }

      await _db.collection('users').doc(userId).update({
        'portfolioValue': totalValue,
        'totalInvestment': totalInvestment,
      });
    } catch (e) {
      throw FirestoreException('Failed to update portfolio value', e);
    }
  }
}
