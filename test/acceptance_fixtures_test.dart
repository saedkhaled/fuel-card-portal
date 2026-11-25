import 'dart:convert';

import 'package:fleet_cards_demo/app/android_file_actions.dart';
import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/account/account_data.dart';
import 'package:fleet_cards_demo/features/auth/session_repository.dart';
import 'package:fleet_cards_demo/features/cards/card_notes.dart';
import 'package:fleet_cards_demo/features/finance/finance_export.dart';
import 'package:fleet_cards_demo/features/finance/finance_tables.dart';
import 'package:fleet_cards_demo/features/finance/fleet_data.dart';
import 'package:fleet_cards_demo/features/stations/station_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FixtureLoader(rootBundle);

  test(
    'all shipped scenarios resolve the cross-feature fixture joins',
    () async {
      final manifest = await loader.readObject(FixtureLoader.manifestPath);
      final scenarios = manifest['scenarios'] as Map<String, dynamic>;
      expect(
        scenarios.keys,
        containsAll([
          'standard',
          'recoverable_error',
          'quiet',
          'empty',
          'large_fleet',
        ]),
      );
      for (final name in scenarios.keys) {
        final selected = await loader.load(scenario: name);
        final fleet = await FleetData.load(loader, selected);
        final account = await AccountData.load(loader, selected, fleet);
        final network = await NetworkRepository(
          loader,
          selected.files['network'],
        ).load();
        for (final user in selected.accounts) {
          final data = fleet.forAccount(user.id);
          expect(
            account.profiles[user.id]!.subscriptions.keys.toSet(),
            data.cards.map((item) => item.id).toSet(),
          );
          for (final sale in data.sales) {
            expect(network.products, contains(sale.product));
            expect(network.stations, contains(sale.stationId));
          }
          final inbox = account.inboxes[user.id]!;
          for (final item in [...inbox.items, ?inbox.stationAlert]) {
            if (item.stationId case final id?) {
              expect(network.stations, contains(id));
            }
            if (item.bulletinId case final id?) {
              expect(network.bulletins, contains(id));
            }
          }
          if (name == 'large_fleet') {
            expect(data.cards, hasLength(180));
            final prefs = MemoryPreferences();
            final notes = CardNotes(prefs, name);
            final table = await cardsTable(data.cards, data, notes);
            expect(
              const LineSplitter().convert(
                utf8.decode(table.encode(FinanceExportFormat.csv)),
              ),
              hasLength(181),
            );
            expect(table.encode(FinanceExportFormat.xlsx), isNotEmpty);
            notes.dispose();
          }
        }
      }
    },
  );

  testWidgets(
    'a fixture-only amount change reaches Home, Card Details and export',
    (tester) async {
      final assets = FixtureAssets();
      final preferences = MemoryPreferences();
      await tester.runAsync(() async {
        final standard = await loader.load();
        for (final path in [
          FixtureLoader.manifestPath,
          ...standard.files.values,
        ]) {
          assets.files[path] = await rootBundle.loadString(path);
        }
        final path = standard.files['finance']!;
        final data = jsonDecode(assets.files[path]!) as Map<String, dynamic>;
        data['balances'][0]['amountMinor'] = 18770000;
        assets.files[path] = jsonEncode(data);

        final repository = FixtureSessionRepository(
          standard,
          preferences,
          DateTime.now,
        );
        repository.request(repository.sample.phone);
        await repository.verify(repository.sample.code);
        await preferences.write('demo.language', 'en');
      });
      final bus = tester.binding.defaultBinaryMessenger;
      MethodCall? exported;
      bus.setMockMethodCallHandler(AndroidFileActions.channel, (call) async {
        exported = call;
        return true;
      });
      addTearDown(
        () => bus.setMockMethodCallHandler(AndroidFileActions.channel, null),
      );

      await tester.pumpWidget(
        PortalBootstrap(
          loader: FixtureLoader(assets),
          preferences: preferences,
          now: DateTime.now,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.textContaining('381,700.00 SYP'), findsOneWidget);
      final tab = find.widgetWithIcon(
        NavigationDestination,
        Icons.credit_card_outlined,
      );
      await tester.tap(tab);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Card details').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('187,700.00 SYP'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();
      expect(exported?.method, 'save');
      final args = exported!.arguments as Map;
      expect(
        utf8.decode(args['bytes'] as List<int>),
        contains(
          '"fc-101","FC-0101","DAM 1284","active","diesel","monthly",450,187700.0',
        ),
      );
    },
  );
}
