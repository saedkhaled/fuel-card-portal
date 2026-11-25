import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../app/demo_preferences.dart';
import 'fleet_card.dart';

class CardNotes extends ChangeNotifier {
  CardNotes(this._preferences, this._scenario);

  static const limit = 500;

  final DemoPreferences _preferences;
  final String _scenario;
  final _loaded = <String, Future<String?>>{};

  String _key(FleetCard card) =>
      'demo.$_scenario.${Uri.encodeComponent(card.accountId)}.card.${Uri.encodeComponent(card.id)}.note';

  Future<String?> read(FleetCard card) =>
      _loaded.putIfAbsent(_key(card), () async {
        final raw = await _preferences.read(_key(card));
        if (raw == null) return card.seedNote;
        final decoded = jsonDecode(raw);
        if (decoded is String || decoded == null) return decoded as String?;
        throw const FormatException('Invalid card note');
      });

  Future<void> save(FleetCard card, String? note) async {
    final value = note?.trim();
    if (value != null && (value.isEmpty || value.characters.length > limit)) {
      throw ArgumentError('Invalid note length');
    }
    final key = _key(card);
    await _preferences.write(key, jsonEncode(value));
    _loaded[key] = Future.value(value);
    notifyListeners();
  }

  void retry(FleetCard card) {
    _loaded.remove(_key(card));
    notifyListeners();
  }
}
