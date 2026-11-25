import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../app/demo_preferences.dart';
import '../account/account_data.dart';
import '../auth/session_controller.dart';

class InboxState {
  const InboxState({
    this.alerts = false,
    this.promptSeen = false,
    this.delivered = false,
    this.readIds = const {},
  });

  final bool alerts;
  final bool promptSeen;
  final bool delivered;
  final Set<String> readIds;

  factory InboxState.decode(String raw) {
    if (jsonDecode(raw) case {
      'alerts': final bool alerts,
      'promptSeen': final bool seen,
      'delivered': final bool delivered,
      'readIds': final List<dynamic> ids,
    } when ids.every((id) => id is String)) {
      return InboxState(
        alerts: alerts,
        promptSeen: seen,
        delivered: delivered,
        readIds: Set.unmodifiable(ids.cast<String>()),
      );
    }
    throw const FormatException('Invalid demo inbox state');
  }

  String encode() => jsonEncode({
    'alerts': alerts,
    'promptSeen': promptSeen,
    'delivered': delivered,
    'readIds': readIds.toList(),
  });
}

class InboxController extends ChangeNotifier {
  InboxController(
    this._data,
    this._preferences,
    this._scenario,
    this._session,
  ) {
    _session.addListener(_selectAccount);
    _selectAccount();
  }

  final AccountData _data;
  final DemoPreferences _preferences;
  final String _scenario;
  final SessionController _session;
  String? _accountId;
  int _generation = 0;
  InboxState? _state;
  bool _failed = false;
  bool _saving = false;

  bool get ready => _state != null;
  bool get failed => _failed;
  bool get saving => _saving;
  bool get alerts => _state?.alerts ?? false;
  bool get needsPrompt => _state?.promptSeen == false;

  List<InboxItem> get items {
    final state = _state;
    final inbox = _data.inboxes[_accountId];
    if (inbox == null || state == null) return const [];
    return [
      ...inbox.items,
      if (state.delivered && inbox.stationAlert != null) inbox.stationAlert!,
    ]..sort((a, b) => b.at.compareTo(a.at));
  }

  bool isRead(InboxItem item) =>
      item.initiallyRead || (_state?.readIds.contains(item.id) ?? false);
  int get unread => items.where((item) => !isRead(item)).length;
  bool hasItem(String id) => items.any((item) => item.id == id);

  String _key(String id) => 'demo.services.${jsonEncode([_scenario, id])}';

  void _selectAccount() {
    final id = _session.accountId;
    if (id == _accountId) return;
    _accountId = id;
    _state = null;
    _failed = false;
    _saving = false;
    final generation = ++_generation;
    notifyListeners();
    if (id != null) _restore(id, generation);
  }

  Future<void> retry() async {
    final id = _accountId;
    if (id == null || !_failed) return;
    _failed = false;
    notifyListeners();
    await _restore(id, ++_generation);
  }

  Future<void> _restore(String id, int generation) async {
    try {
      final saved = await _preferences.read(_key(id));
      final legacy = saved == null
          ? await _preferences.read('demo.$_scenario.$id.alertPrompt')
          : null;
      if (generation != _generation) return;
      _state = saved == null
          ? InboxState(
              alerts: legacy == 'enabled',
              promptSeen: legacy != null,
              delivered: legacy == 'enabled',
            )
          : InboxState.decode(saved);
    } catch (_) {
      if (generation != _generation) return;
      _failed = true;
    }
    notifyListeners();
  }

  Future<void> setAlerts(bool enabled) => _update(
    (state) => InboxState(
      alerts: enabled,
      promptSeen: true,
      delivered: state.delivered || enabled,
      readIds: state.readIds,
    ),
  );

  Future<void> markRead(String id) => _update(
    (state) => InboxState(
      alerts: state.alerts,
      promptSeen: state.promptSeen,
      delivered: state.delivered,
      readIds: {...state.readIds, id},
    ),
    onlyIf: () => hasItem(id),
  );

  Future<void> _update(
    InboxState Function(InboxState) change, {
    bool Function()? onlyIf,
  }) async {
    final accountId = _accountId;
    final state = _state;
    if (_saving ||
        state == null ||
        accountId == null ||
        onlyIf?.call() == false) {
      return;
    }
    final generation = _generation;
    final updated = change(state);
    _saving = true;
    notifyListeners();
    try {
      await _preferences.write(_key(accountId), updated.encode());
      if (generation == _generation) _state = updated;
    } finally {
      if (generation == _generation) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    _session.removeListener(_selectAccount);
    super.dispose();
  }
}
