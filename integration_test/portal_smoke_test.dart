import 'package:fleet_cards_demo/app/demo_preferences.dart';
import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/auth/session_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_services_smoke_test.dart' as account;
import 'cards_finance_smoke_test.dart' as finance;
import 'foundation_smoke_test.dart' as foundation;
import 'stations_prices_smoke_test.dart' as network;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This suite runs against the disposable test installation.
  setUp(() => SharedPreferencesAsync().clear());

  group('Foundation', foundation.main);
  group('Cards and finance', finance.main);
  group('Stations and prices', network.main);
  group('Account services', account.main);

  testWidgets('large fleet scrolls and filters through the bundled scenario', (
    tester,
  ) async {
    final loader = FixtureLoader(rootBundle);
    final fixtures = await loader.load(scenario: 'large_fleet');
    final preferences = AndroidDemoPreferences(SharedPreferencesAsync());
    await preferences.write('demo.language', 'en');
    final repository = FixtureSessionRepository(
      fixtures,
      preferences,
      DateTime.now,
    );
    repository.request(repository.sample.phone);
    await repository.verify(repository.sample.code);

    runApp(
      PortalBootstrap(
        loader: loader,
        preferences: preferences,
        now: DateTime.now,
        scenario: 'large_fleet',
        initialLocation: '/cards',
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    expect(find.textContaining('FC-0101'), findsOneWidget);
    expect(find.textContaining('FC-0279'), findsNothing);
    await tester.fling(list, const Offset(0, -580), 1000);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels,
      greaterThan(0),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('card-search'));
    await tester.enterText(search, 'FC-0279');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: list, matching: find.textContaining('FC-0279')),
      findsOneWidget,
    );
    expect(find.textContaining('FC-0101'), findsNothing);
  });
}
