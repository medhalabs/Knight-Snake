import 'package:flutter/services.dart';

import '../../core/level.dart';
import '../../services/services.dart';

/// Loads level JSON files from `assets/levels/` and tracks progress.
class LevelRepository {
  LevelRepository(this.storage, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final StorageService storage;
  final AssetBundle _bundle;

  Future<List<Level>> loadAll() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final paths =
        manifest
            .listAssets()
            .where((p) => p.startsWith('assets/levels/') && p.endsWith('.json'))
            .toList()
          ..sort();
    return [
      for (final p in paths) Level.fromJsonString(await _bundle.loadString(p)),
    ];
  }

  int bestScore(int id) => storage.getInt('best_$id') ?? 0;
  int stars(int id) => storage.getInt('stars_$id') ?? 0;
  bool isUnlocked(int id) => id == 1 || stars(id - 1) > 0;

  /// Saves a won level. Returns true if [score] beats the previous best.
  bool record(int id, {required int score, required int stars}) {
    if (stars <= 0) return false;
    if (stars > this.stars(id)) storage.setInt('stars_$id', stars);
    if (score <= bestScore(id)) return false;
    storage.setInt('best_$id', score);
    return true;
  }

  bool get reducedMotion => storage.getBool('reducedMotion') ?? false;
  set reducedMotion(bool v) => storage.setBool('reducedMotion', v);
}
