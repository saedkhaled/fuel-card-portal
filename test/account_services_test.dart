import 'dart:convert';

import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/account/account_data.dart';
import 'package:fleet_cards_demo/features/account/top_up_page.dart';
import 'package:fleet_cards_demo/features/auth/session_controller.dart';
import 'package:fleet_cards_demo/features/auth/session_repository.dart';
import 'package:fleet_cards_demo/features/finance/fleet_data.dart';
import 'package:fleet_cards_demo/features/notifications/inbox_controller.dart';
import 'package:fleet_cards_demo/features/stations/station_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fleet_cards_demo/features/notifications/notification_pages.dart';
import 'package:fleet_cards_demo/l10n/generated/app_localizations.dart';

import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FixtureLoader(rootBundle);

  Future<(DemoFixtures, AccountData)> read([String? scenario]) async {
    final fixtures = await loader.load(scenario: scenario);
    final fleet = await FleetData.load(loader, fixtures);
    return (fixtures, await AccountData.load(loader, fixtures, fleet));
  }

  test(
    'profile, invoice history and transfer notes use stable card IDs',
    () async {
      final (_, data) = await read();
      final profile = data.profiles['demo-fleet']!;
      expect(profile.subscriptions['fc-103']!.exempt, isTrue);
      expect(profile.subscriptions['fc-103']!.invoices, isEmpty);
      final billed = profile.subscriptions['fc-101']!;
      expect(billed.invoices.map((item) => item.paid), [false, true]);
      expect(billed.lastPayment!.issuedOn, DateTime.utc(2026, 11, 1));
      expect(profile.topUp.destination, 'DEMO-TRANSFER-104');
      expect(
        profile.topUp.note('FC-0102', 'ALP 3651'),
        'DEMO TOP-UP | FC-0102 | ALP 3651',
      );
      final (_, empty) = await read('empty');
      expect(empty.profiles['demo-fleet']!.subscriptions, isEmpty);
    },
  );

  test('rejects an actionable QR payload in the fixture', () async {
    final fixtures = await loader.load();
    final assets = FixtureAssets();
    for (final path in [FixtureLoader.manifestPath, ...fixtures.files.values]) {
      assets.files[path] = await rootBundle.loadString(path);
    }
    final accountPath = fixtures.files['account']!;
    final account = jsonDecode(assets.files[accountPath]!) as Map;
    account['profiles'][0]['topUp']['qrPayload'] =
        'https://example.invalid/transfer';
    assets.files[accountPath] = jsonEncode(account);
    final modified = FixtureLoader(assets);
    final fleet = await FleetData.load(modified, fixtures);
    await expectLater(
      AccountData.load(modified, fixtures, fleet),
      throwsA(isA<FixtureException>()),
    );
  });

  test(
    'one local alert is delivered, read state persists, logout clears memory',
    () async {
      final (fixtures, data) = await read();
      final preferences = MemoryPreferences();
      final repo = FixtureSessionRepository(
        fixtures,
        preferences,
        DateTime.now,
      );
      final session = SessionController(repo, 'demo-fleet');
      InboxController controller() =>
          InboxController(data, preferences, fixtures.scenario, session);
      Future<void> settle() => Future<void>.delayed(Duration.zero);

      final inbox = controller();
      await settle();
      expect(inbox.needsPrompt, isTrue);
      expect(inbox.unread, 1);
      await inbox.setAlerts(false);
      expect(inbox.items, hasLength(2));
      await inbox.setAlerts(true);
      expect(inbox.unread, 2);
      expect(inbox.items.first.stationId, 'dam-depot');
      await inbox.markRead(inbox.items.first.id);
      expect(inbox.unread, 1);
      await inbox.setAlerts(false);
      await inbox.setAlerts(true);
      expect(inbox.items, hasLength(3));
      inbox.dispose();
      final restored = controller();
      await settle();
      expect(restored.needsPrompt, isFalse);
      expect(restored.alerts, isTrue);
      expect(restored.unread, 1);
      await session.logout();
      expect(restored.items, isEmpty);
      expect(restored.ready, isFalse);
      restored.dispose();
      session.dispose();
    },
  );

  test('quiet inbox stays empty and seeded item links resolve', () async {
    final (fixtures, standard) = await read();
    final (_, quiet) = await read('quiet');
    expect(quiet.inboxes['demo-fleet']!.items, isEmpty);
    expect(quiet.inboxes['demo-fleet']!.stationAlert, isNull);
    final network = await NetworkRepository(
      loader,
      fixtures.files['network'],
    ).load();
    final inbox = standard.inboxes['demo-fleet']!;
    expect(network.stations, contains(inbox.stationAlert!.stationId));
    expect(network.bulletins, contains(inbox.items.first.bulletinId));
  });

  testWidgets('quiet scenario shows the empty inbox', (tester) async {
    final (fixtures, data) = (await tester.runAsync(() => read('quiet')))!;
    final preferences = MemoryPreferences();
    final repo = FixtureSessionRepository(fixtures, preferences, DateTime.now);
    final session = SessionController(repo, fixtures.accounts.first.id);
    final inbox = InboxController(
      data,
      preferences,
      fixtures.scenario,
      session,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: inbox,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    inbox.dispose();
    session.dispose();
  });

  testWidgets('demo QR encodes a PNG', (tester) async {
    final bytes = await tester.runAsync(
      () => encodeDemoQr('FLEET-CARDS-DEMO:TEST'),
    );
    expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final data = ByteData.sublistView(bytes);
    expect(data.getUint32(16), 512);
    expect(data.getUint32(20), 512);
  });
}
