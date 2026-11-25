import 'package:flutter/foundation.dart';

import 'session_repository.dart';

enum AuthIssue {
  invalidPhone,
  unknownPhone,
  requestFailed,
  invalidCode,
  expired,
  saveFailed,
}

class SessionController extends ChangeNotifier {
  SessionController(this.repository, [this._accountId]);

  final SessionRepository repository;
  String? _accountId;
  String? get accountId => _accountId;
  CodeChallenge? get challenge => repository.challenge;
  AuthIssue? issue;
  bool busy = false;

  void request(String phone) {
    if (busy) return;
    _challengeOperation(() => repository.request(phone));
  }

  void resend() {
    if (busy) return;
    _challengeOperation(repository.resend);
  }

  void _challengeOperation(CodeChallenge Function() operation) {
    issue = null;
    try {
      operation();
    } on AuthFailure catch (error) {
      issue = _issueFor(error);
    }
    notifyListeners();
  }

  void cancelChallenge() {
    if (busy) return;
    repository.cancelChallenge();
    issue = null;
  }

  void clearIssue() {
    if (issue == null) return;
    issue = null;
    notifyListeners();
  }

  Future<void> verify(String code) async {
    if (busy) return;
    busy = true;
    issue = null;
    notifyListeners();
    try {
      _accountId = await repository.verify(code);
    } on AuthFailure catch (error) {
      issue = _issueFor(error);
    } catch (_) {
      issue = AuthIssue.saveFailed;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (busy) return;
    busy = true;
    issue = null;
    notifyListeners();
    try {
      await repository.logout();
      _accountId = null;
    } catch (_) {
      issue = AuthIssue.saveFailed;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static AuthIssue? _issueFor(AuthFailure error) => switch (error) {
    AuthFailure.invalidPhone => AuthIssue.invalidPhone,
    AuthFailure.unknownPhone => AuthIssue.unknownPhone,
    AuthFailure.requestFailed => AuthIssue.requestFailed,
    AuthFailure.invalidCode => AuthIssue.invalidCode,
    AuthFailure.expiredCode => AuthIssue.expired,
    AuthFailure.cooldown || AuthFailure.noChallenge => null,
  };
}
