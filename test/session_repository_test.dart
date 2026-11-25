import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/auth/session_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DemoFixtures fixtures;
  late FixtureSessionRepository repository;
  late MemoryPreferences preferences;
  late DateTime now;

  setUp(() async {
    fixtures = await FixtureLoader(rootBundle).load();
    preferences = MemoryPreferences();
    now = DateTime.utc(2026, 11, 25, 12);
    repository = FixtureSessionRepository(fixtures, preferences, () => now);
  });

  test('validates phone format, known phone and wrong code', () async {
    expect(() => repository.request('123'), throwsA(AuthFailure.invalidPhone));
    expect(
      () => repository.request('0912345678'),
      throwsA(AuthFailure.unknownPhone),
    );
    repository.request(repository.sample.phone);
    await expectLater(
      repository.verify('987654'),
      throwsA(AuthFailure.invalidCode),
    );
    expect(repository.challenge, isNotNull);
    expect(await repository.restore(), isNull);
  });

  test(
    'enforces exact resend and expiry boundaries and cancellation',
    () async {
      final first = repository.request(repository.sample.phone);
      now = first.resendAt.subtract(const Duration(milliseconds: 1));
      expect(repository.resend, throwsA(AuthFailure.cooldown));
      now = first.resendAt;
      final replacement = repository.resend();
      expect(replacement, isNot(same(first)));
      expect(replacement.expiresAt, now.add(fixtures.validity));
      now = replacement.expiresAt;
      await expectLater(
        repository.verify(repository.sample.code),
        throwsA(AuthFailure.expiredCode),
      );
      repository.cancelChallenge();
      await expectLater(
        repository.verify(repository.sample.code),
        throwsA(AuthFailure.noChallenge),
      );
    },
  );

  test('persists only account ID, restores and signs out', () async {
    repository.request(repository.sample.phone);
    final id = await repository.verify(repository.sample.code);
    expect(preferences.values.values, [id]);
    await expectLater(
      repository.verify(repository.sample.code),
      throwsA(AuthFailure.noChallenge),
    );
    final restarted = FixtureSessionRepository(
      fixtures,
      preferences,
      () => now,
    );
    expect(await restarted.restore(), id);
    await restarted.logout();
    expect(await repository.restore(), isNull);
  });

  test('recoverable scenario fails once and keeps sessions isolated', () async {
    final alternate = await FixtureLoader(
      rootBundle,
    ).load(scenario: 'recoverable_error');
    final recovering = FixtureSessionRepository(
      alternate,
      preferences,
      () => now,
    );
    expect(
      () => recovering.request(recovering.sample.phone),
      throwsA(AuthFailure.requestFailed),
    );
    expect(recovering.challenge, isNull);
    recovering.request(recovering.sample.phone);
    await recovering.verify(recovering.sample.code);
    expect(await recovering.restore(), recovering.sample.id);
    expect(await repository.restore(), isNull);
  });
}
