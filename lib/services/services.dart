import 'package:flutter/services.dart';

/// All app services in one place, so tests and dev builds can swap in fakes.
/// Real SDK-backed versions (ads, purchases, analytics, persistent storage,
/// audio) arrive in later phases — see docs/GAME_PLAN.md §8.
class Services {
  Services({
    required this.storage,
    required this.haptics,
    required this.audio,
    required this.ads,
    required this.purchases,
    required this.analytics,
  });

  /// Development setup: in-memory storage, real haptics, everything else fake.
  factory Services.dev() => Services(
    storage: MemoryStorage(),
    haptics: SystemHaptics(),
    audio: FakeAudio(),
    ads: FakeAds(),
    purchases: FakePurchases(),
    analytics: FakeAnalytics(),
  );

  /// Everything fake (tests).
  factory Services.fake() => Services(
    storage: MemoryStorage(),
    haptics: FakeHaptics(),
    audio: FakeAudio(),
    ads: FakeAds(),
    purchases: FakePurchases(),
    analytics: FakeAnalytics(),
  );

  final StorageService storage;
  final HapticsService haptics;
  final AudioService audio;
  final AdsService ads;
  final PurchaseService purchases;
  final AnalyticsService analytics;
}

// ---------------------------------------------------------------- storage

/// Key-value storage for progress and settings.
abstract class StorageService {
  int? getInt(String key);
  void setInt(String key, int value);
  bool? getBool(String key);
  void setBool(String key, bool value);
}

class MemoryStorage implements StorageService {
  final Map<String, Object> _data = {};
  @override
  int? getInt(String key) => _data[key] as int?;
  @override
  void setInt(String key, int value) => _data[key] = value;
  @override
  bool? getBool(String key) => _data[key] as bool?;
  @override
  void setBool(String key, bool value) => _data[key] = value;
}

// ---------------------------------------------------------------- haptics

enum Haptic { light, medium, heavy, error }

abstract class HapticsService {
  void play(Haptic h);
}

class SystemHaptics implements HapticsService {
  @override
  void play(Haptic h) {
    switch (h) {
      case Haptic.light:
        HapticFeedback.selectionClick();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.heavy:
        HapticFeedback.heavyImpact();
      case Haptic.error:
        HapticFeedback.vibrate();
    }
  }
}

class FakeHaptics implements HapticsService {
  final List<Haptic> played = [];
  @override
  void play(Haptic h) => played.add(h);
}

// ---------------------------------------------------------------- audio

enum Sfx { move, eat, combo, win, lose, tap }

abstract class AudioService {
  void play(Sfx sfx);
}

class FakeAudio implements AudioService {
  final List<Sfx> played = [];
  @override
  void play(Sfx sfx) => played.add(sfx);
}

// ---------------------------------------------------------------- ads

/// Rewarded / interstitial ads. Child-directed settings are applied by the
/// real implementation based on the age gate (GAME_PLAN §6).
abstract class AdsService {
  /// Shows a rewarded ad; completes with true if the reward was earned.
  Future<bool> showRewarded(String placement);
}

class FakeAds implements AdsService {
  int shown = 0;
  @override
  Future<bool> showRewarded(String placement) async {
    shown++;
    return true;
  }
}

// ---------------------------------------------------------------- purchases

abstract class PurchaseService {
  bool owns(String productId);
  Future<bool> buy(String productId);
}

class FakePurchases implements PurchaseService {
  final Set<String> _owned = {};
  @override
  bool owns(String productId) => _owned.contains(productId);
  @override
  Future<bool> buy(String productId) async {
    _owned.add(productId);
    return true;
  }
}

// ---------------------------------------------------------------- analytics

abstract class AnalyticsService {
  void log(String event, [Map<String, Object> params = const {}]);
}

class FakeAnalytics implements AnalyticsService {
  final List<String> events = [];
  @override
  void log(String event, [Map<String, Object> params = const {}]) =>
      events.add(event);
}
