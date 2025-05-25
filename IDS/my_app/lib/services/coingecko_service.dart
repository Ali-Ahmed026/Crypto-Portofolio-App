import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoApiException implements Exception {
  final String message;
  final dynamic originalError;
  final int? statusCode;

  CoinGeckoApiException(this.message, [this.originalError, this.statusCode]);

  @override
  String toString() =>
      'CoinGeckoApiException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static DateTime? _lastRequestTime;
  static const _minRequestInterval =
      Duration(seconds: 2); // Rate limit protection

  static Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  static Future<List<double>> getHistoricalPrices(
      String coinId, String timeframe) async {
    try {
      await _waitForRateLimit();

      final days = timeframe == '7d'
          ? '7'
          : timeframe == '30d'
              ? '30'
              : '90';

      final response = await http.get(Uri.parse(
          '$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data.containsKey('prices') || !(data['prices'] is List)) {
          throw CoinGeckoApiException(
              'Invalid response format: missing or invalid prices data');
        }
        final prices = (data['prices'] as List).map((price) {
          if (price is! List || price.length < 2 || price[1] == null) {
            throw CoinGeckoApiException(
                'Invalid price data format in response');
          }
          return (price[1] as num).toDouble();
        }).toList();
        return prices;
      } else if (response.statusCode == 429) {
        throw CoinGeckoApiException(
            'Rate limit exceeded. Please try again later.',
            null,
            response.statusCode);
      } else {
        throw CoinGeckoApiException(
            'Failed to load historical data: ${response.statusCode}',
            null,
            response.statusCode);
      }
    } catch (e) {
      if (e is CoinGeckoApiException) {
        rethrow;
      }
      throw CoinGeckoApiException('Failed to load historical data', e);
    }
  }

  static Future<Map<String, double>> getCurrentPrices(
      List<String> coinIds) async {
    try {
      if (coinIds.isEmpty) return {};

      await _waitForRateLimit();

      final response = await http.get(Uri.parse(
          '$_baseUrl/simple/price?ids=${coinIds.join(",")}&vs_currencies=usd'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = <String, double>{};

        for (final entry in data.entries) {
          try {
            final priceData = entry.value as Map<String, dynamic>;
            if (priceData.containsKey('usd')) {
              result[entry.key] = (priceData['usd'] as num).toDouble();
            }
          } catch (e) {
            // Skip invalid entries instead of failing completely
            continue;
          }
        }

        return result;
      } else if (response.statusCode == 429) {
        throw CoinGeckoApiException(
            'Rate limit exceeded. Please try again later.',
            null,
            response.statusCode);
      } else {
        throw CoinGeckoApiException(
            'Failed to load current prices: ${response.statusCode}',
            null,
            response.statusCode);
      }
    } catch (e) {
      if (e is CoinGeckoApiException) {
        rethrow;
      }
      throw CoinGeckoApiException('Failed to load current prices', e);
    }
  }
}
