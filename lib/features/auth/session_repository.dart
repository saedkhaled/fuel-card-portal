import '../../app/demo_preferences.dart';
import '../../demo/demo_fixtures.dart';

enum AuthFailure implements Exception {
  invalidPhone,
  unknownPhone,
  requestFailed,
  invalidCode,
  expiredCode,
  cooldown,
  noChallenge,
}

class CodeChallenge {
  const CodeChallenge({
    required this.account,
    required this.expiresAt,
    required this.resendAt,
  });

  final DemoAccount account;
  String get phone => account.phone;
  final DateTime expiresAt;
  final DateTime resendAt;
}

abstract interface class SessionRepository {
  DemoAccount get sample;
  CodeChallenge? get challenge;

  Future<String?> restore();
  CodeChallenge request(String phone);
  CodeChallenge resend();
  Future<String> verify(String code);
  void cancelChallenge();
  Future<void> logout();
}

class FixtureSessionRepository implements SessionRepository {
  FixtureSessionRepository(this._fixtures, this._preferences, this._now)
    : _failNextRequest = _fixtures.failFirstRequest;

  final DemoFixtures _fixtures;
  final DemoPreferences _preferences;
  final DateTime Function() _now;
  bool _failNextRequest;
  CodeChallenge? _challenge;

  String get _sessionKey => 'demo.${_fixtures.scenario}.session';

  @override
  DemoAccount get sample => _fixtures.accounts.first;

  @override
  CodeChallenge? get challenge => _challenge;

  @override
  Future<String?> restore() async {
    final id = await _preferences.read(_sessionKey);
    return _fixtures.accounts.any((account) => account.id == id) ? id : null;
  }

  @override
  CodeChallenge request(String phone) {
    if (!demoPhonePattern.hasMatch(phone)) throw AuthFailure.invalidPhone;
    final account = _fixtures.accounts
        .where((account) => account.phone == phone)
        .firstOrNull;
    if (account == null) throw AuthFailure.unknownPhone;
    if (_failNextRequest) {
      _failNextRequest = false;
      throw AuthFailure.requestFailed;
    }
    return _issue(account);
  }

  @override
  CodeChallenge resend() {
    final current = _challenge ?? (throw AuthFailure.noChallenge);
    if (_now().isBefore(current.resendAt)) throw AuthFailure.cooldown;
    return _issue(current.account);
  }

  CodeChallenge _issue(DemoAccount account) {
    final now = _now();
    return _challenge = CodeChallenge(
      account: account,
      expiresAt: now.add(_fixtures.validity),
      resendAt: now.add(_fixtures.resendDelay),
    );
  }

  @override
  Future<String> verify(String code) async {
    final current = _challenge ?? (throw AuthFailure.noChallenge);
    if (!_now().isBefore(current.expiresAt)) throw AuthFailure.expiredCode;
    final account = current.account;
    if (account.code != code) throw AuthFailure.invalidCode;
    _challenge = null;
    try {
      await _preferences.write(_sessionKey, account.id);
    } catch (_) {
      _challenge ??= current;
      rethrow;
    }
    return account.id;
  }

  @override
  void cancelChallenge() => _challenge = null;

  @override
  Future<void> logout() async {
    await _preferences.remove(_sessionKey);
    cancelChallenge();
  }
}
