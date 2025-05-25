import 'dart:async';
import 'package:flutter/material.dart';
import '../services/coingecko_service.dart';

class CoinProvider extends ChangeNotifier {
  Map<String, double> _prices = {};
  Map<String, double> _displayPrices = {}; // Prices shown to the user
  String? _error;
  Timer? _refreshTimer;
  bool _isUpdating = false;
  static const _updateInterval = Duration(minutes: 1);
  DateTime? _lastUpdateTime;
  int _consecutiveErrors = 0;
  static const _maxConsecutiveErrors = 3;

  Map<String, double> get prices =>
      _displayPrices; // Return display prices instead
  String? get error => _error;
  bool get isUpdating => _isUpdating;

  CoinProvider() {
    // Start periodic price updates
    _refreshTimer = Timer.periodic(_updateInterval, (_) {
      if (_prices.isNotEmpty) {
        _updatePrices();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _updatePrices() async {
    if (_isUpdating) return; // Prevent concurrent updates
    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!) <
            const Duration(seconds: 30)) {
      return; // Prevent too frequent updates
    }

    _isUpdating = true;
    // Don't notify listeners here to avoid UI flicker

    try {
      await fetchCoinPrices(_prices.keys.toList());
      _consecutiveErrors = 0; // Reset error counter on successful update
    } finally {
      _isUpdating = false;
      _lastUpdateTime = DateTime.now();
      // Only notify if there was an actual change
      if (_hasDisplayPricesChanged()) {
        notifyListeners();
      }
    }
  }

  bool _hasDisplayPricesChanged() {
    if (_prices.length != _displayPrices.length) return true;
    for (final entry in _prices.entries) {
      final currentDisplay = _displayPrices[entry.key];
      if (currentDisplay == null || currentDisplay != entry.value) {
        return true;
      }
    }
    return false;
  }

  Future<void> fetchCoinPrices(List<String> coinIds) async {
    if (coinIds.isEmpty) return;

    try {
      _error = null;
      final newPrices = await CoinGeckoService.getCurrentPrices(coinIds);

      // Verify we have data for all requested coins before updating display
      bool hasAllPrices = coinIds.every((id) => newPrices.containsKey(id));

      if (hasAllPrices) {
        // Update internal prices first
        _prices = Map.from(newPrices);
        // Then update display prices only if we have all data
        _displayPrices = Map.from(newPrices);
        _consecutiveErrors = 0;
      } else {
        // Keep previous prices if we don't have complete data
        _consecutiveErrors++;
        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          _error =
              'Unable to fetch complete price data. Some prices may be outdated.';
        }
      }
    } on CoinGeckoApiException catch (e) {
      _consecutiveErrors++;
      if (e.statusCode == 429) {
        // Don't show rate limit errors unless persistent
        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          _error = 'Rate limit reached. Prices may be delayed.';
        }
      } else {
        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          _error = e.message;
        }
      }
    } catch (e) {
      _consecutiveErrors++;
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _error = 'Failed to update prices. Using last known values.';
      }
    }
  }

  double? getPrice(String coinId) {
    return _displayPrices[coinId];
  }

  // Force an immediate update
  Future<void> refreshPrices() async {
    if (_prices.isEmpty) return;
    _consecutiveErrors = 0; // Reset error counter on manual refresh
    await _updatePrices();
  }
}
