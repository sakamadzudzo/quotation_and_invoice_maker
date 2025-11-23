import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract cache manager interface for different caching implementations.
abstract class CacheManager {
  /// Retrieves a value from cache by key.
  ///
  /// Returns null if the key doesn't exist or has expired.
  Future<T?> get<T>(String key);

  /// Stores a value in cache with optional time-to-live.
  ///
  /// [key] - Unique identifier for the cached item
  /// [value] - Value to cache
  /// [ttl] - Optional time-to-live duration
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// Removes a specific item from cache.
  Future<void> remove(String key);

  /// Clears all cached items.
  Future<void> clear();

  /// Checks if a key exists in cache (and hasn't expired).
  Future<bool> contains(String key);
}

/// SharedPreferences-based cache manager with memory caching and TTL support.
///
/// Features:
/// - Two-level caching (memory + persistent)
/// - Time-to-live (TTL) support for cache expiration
/// - Automatic cleanup of expired items
/// - JSON serialization for complex objects
class SharedPreferencesCacheManager implements CacheManager {
  final SharedPreferences _prefs;

  /// In-memory cache for faster access
  final Map<String, dynamic> _memoryCache = {};

  /// Expiry times for TTL management
  final Map<String, DateTime> _expiryTimes = {};

  SharedPreferencesCacheManager(this._prefs);

  @override
  Future<T?> get<T>(String key) async {
    // Check if expired and clean up if necessary
    if (_isExpired(key)) {
      await remove(key);
      return null;
    }

    // Check memory cache first for better performance
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key] as T;
    }

    // Check persistent cache
    final cached = _prefs.getString(key);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as T;
        // Store in memory cache for future access
        _memoryCache[key] = decoded;
        return decoded;
      } catch (e) {
        // Invalid cache data, remove it
        await remove(key);
      }
    }

    return null;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    // Store in memory cache
    _memoryCache[key] = value;

    // Set expiry time if TTL is specified
    if (ttl != null) {
      _expiryTimes[key] = DateTime.now().add(ttl);
    }

    // Store in persistent cache
    await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _expiryTimes.remove(key);
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    _memoryCache.clear();
    _expiryTimes.clear();
    await _prefs.clear();
  }

  @override
  Future<bool> contains(String key) async {
    if (_isExpired(key)) {
      await remove(key);
      return false;
    }

    return _memoryCache.containsKey(key) || _prefs.containsKey(key);
  }

  /// Checks if a cache key has expired.
  bool _isExpired(String key) {
    final expiryTime = _expiryTimes[key];
    return expiryTime != null && DateTime.now().isAfter(expiryTime);
  }
}

/// Cache keys used throughout the application.
class CacheKeys {
  static const String companiesList = 'companies_list';
  static const String clientsList = 'clients_list';
  static const String quotationsList = 'quotations_list';
  static const String invoicesList = 'invoices_list';
  static const String taxNamesList = 'tax_names_list';
  static const String settings = 'app_settings';
}

/// Cache duration constants.
class CacheDuration {
  static const Duration short = Duration(minutes: 5);
  static const Duration medium = Duration(minutes: 30);
  static const Duration long = Duration(hours: 1);
  static const Duration veryLong = Duration(hours: 24);
}