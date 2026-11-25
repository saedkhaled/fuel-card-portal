import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads packaged standard and recoverable scenarios', () async {
    final loader = FixtureLoader(rootBundle);
    final standard = await loader.load();
    expect(standard.scenario, 'standard');
    expect(standard.accounts, isNotEmpty);
    expect(standard.validity, greaterThan(standard.resendDelay));
    expect(standard.resendDelay, greaterThan(Duration.zero));
    expect(standard.failFirstRequest, isFalse);
    final recoverable = await loader.load(scenario: 'recoverable_error');
    expect(recoverable.accounts.first.id, standard.accounts.first.id);
    expect(recoverable.failFirstRequest, isTrue);
  });

  test('reports missing and malformed asset context', () async {
    final assets = FixtureAssets();
    final loader = FixtureLoader(assets);
    await expectLater(
      loader.load(scenario: 'unrecognized'),
      throwsA(
        isA<FixtureException>().having(
          (e) => e.path,
          'path',
          FixtureLoader.manifestPath,
        ),
      ),
    );
    assets.files.remove(FixtureAssets.authPath);
    await expectLater(
      loader.load(),
      throwsA(
        isA<FixtureException>().having(
          (e) => e.reason,
          'reason',
          'asset unavailable',
        ),
      ),
    );
    assets.files[FixtureAssets.authPath] = '{';
    await expectLater(
      loader.load(),
      throwsA(
        isA<FixtureException>().having(
          (e) => e.reason,
          'reason',
          'malformed JSON',
        ),
      ),
    );
  });

  test('rejects duplicate synthetic account IDs', () async {
    final assets = FixtureAssets()
      ..files[FixtureAssets.authPath] = '''
      {"validitySeconds":300,"resendSeconds":60,"accounts":[
        {"id":"fleet","phone":"0900000000","code":"246810"},
        {"id":"fleet","phone":"0900000001","code":"123456"}
      ]}
      ''';
    await expectLater(
      FixtureLoader(assets).load(),
      throwsA(isA<FixtureException>()),
    );
  });
}
