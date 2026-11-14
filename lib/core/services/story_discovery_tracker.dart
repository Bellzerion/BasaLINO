import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class StoryDiscoveryTracker {
  static const _storageKey = 'story_discovery_ids';

  Future<SharedPreferences>? _preferencesFuture;
  Future<void>? _loadFuture;
  Set<String>? _discoveredIds;
  Future<void> _pendingWrite = Future<void>.value();

  Future<SharedPreferences> get _preferences =>
      _preferencesFuture ??= SharedPreferences.getInstance();

  Future<void> _load() => _loadFuture ??= _loadOnce();

  Future<void> _loadOnce() async {
    final preferences = await _preferences;
    _discoveredIds = (preferences.getStringList(_storageKey) ?? const [])
        .toSet();
  }

  Future<Set<String>> getDiscoveredIds() async {
    await _load();
    return Set.unmodifiable(_discoveredIds!);
  }

  Future<void> markDiscovered(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Discovery ID cannot be empty.');
    }

    await _load();
    if (!_discoveredIds!.add(normalizedId)) return;

    final previousWrite = _pendingWrite;
    final completer = Completer<void>();
    _pendingWrite = completer.future.catchError((Object _) {});
    try {
      await previousWrite;
      final preferences = await _preferences;
      final saved = await preferences.setStringList(
        _storageKey,
        _discoveredIds!.toList()..sort(),
      );
      if (!saved) {
        throw StateError('Story discovery could not be saved locally.');
      }
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
