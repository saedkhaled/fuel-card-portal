import 'dart:convert';

import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/cards/fleet_card.dart';
import 'package:fleet_cards_demo/features/finance/fleet_data.dart';
import 'package:fleet_cards_demo/features/prices/price_pages.dart';
import 'package:fleet_cards_demo/features/stations/station_network.dart';
import 'package:fleet_cards_demo/features/stations/station_pages.dart';
import 'package:fleet_cards_demo/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fixture_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FixtureLoader(rootBundle);
  const path = 'assets/demo/standard/network.json';

  Future<StationNetwork> load([String? scenario]) async {
    final fixtures = await loader.load(scenario: scenario);
    return NetworkRepository(loader, fixtures.files['network']).load();
  }

  test(
    'combines localized name and address search with city and product',
    () async {
      final data = await load();
      const filter = StationFilter(
        cityId: 'damascus',
        product: FuelProduct.benzene,
      );
      expect(
        filter
            .results(data, language: 'en', search: '  MAROTA   CITY ')
            .single
            .id,
        'dam-depot',
      );
      expect(
        filter.results(data, language: 'ar', search: 'ماروتا').single.id,
        'dam-depot',
      );
      expect(
        filter.results(data, language: 'ar', search: 'حسياء – حمص'),
        isEmpty,
      );
      final station = data.stations['dam-depot']!;
      expect(station.availability, {
        FuelProduct.diesel: FuelAvailability.available,
        FuelProduct.benzene: FuelAvailability.low,
        FuelProduct.premium: FuelAvailability.unavailable,
      });
      for (final station in data.stations.values) {
        expect(
          station.productNames.keys.toSet(),
          station.availability.keys.toSet(),
        );
        expect(
          station.availability.values,
          isNot(contains(FuelAvailability.listed)),
        );
      }
      expect(station.directions, isEmpty);
      expect(data.stations, hasLength(21));
      expect(station.operator, StationOperator.goldenGate);
      expect(data.stations['hms-junction']!.directions, isEmpty);
      expect(data.stations['hms-junction']!.googleMapsDirections, isNotNull);
      expect(
        data
            .stations['alp-yard']!
            .googleMapsDirections!
            .queryParameters['destination'],
        '36.272924,37.2400115',
      );
      expect(
        const StationFilter(
          product: FuelProduct.premium,
        ).results(data, language: 'en').map((item) => item.id),
        containsAll(['dam-depot', 'aleppo2']),
      );
    },
  );

  test(
    'station and product IDs line up with sales and bulletin history',
    () async {
      final data = await load();
      final fixtures = await loader.load();
      final finance = (await FleetData.load(
        loader,
        fixtures,
      )).forAccount(fixtures.accounts.first.id);
      for (final sale in finance.sales) {
        expect(data.stations.containsKey(sale.stationId), isTrue);
        expect(data.products.containsKey(sale.product), isTrue);
      }
      expect(data.current!.effectiveOn, DateTime.utc(2026, 11, 24));
      expect(data.current!.prices[FuelProduct.diesel], 50000);
      expect(data.history.map((item) => item.effectiveOn), [
        DateTime.utc(2026, 11, 1),
        DateTime.utc(2026, 10, 15),
      ]);
      final empty = await load('empty');
      expect(empty.current, isNull);
      expect(empty.history, isEmpty);
      expect(empty.stations, isEmpty);
    },
  );

  test(
    'prioritizes Golden Gate and combines partner, city, and fuel filters',
    () async {
      final original = await load();
      final shuffled = StationNetwork(
        cities: original.cities,
        products: original.products,
        stations: Map.fromEntries(original.stations.entries.toList().reversed),
        bulletins: original.bulletins,
        currentBulletinId: original.currentBulletinId,
      );
      final all = const StationFilter().results(shuffled, language: 'en');
      expect(
        all.take(8).map((station) => station.operator),
        everyElement(StationOperator.goldenGate),
      );
      expect(
        all.skip(8).map((station) => station.operator),
        everyElement(StationOperator.taiba),
      );
      const filter = StationFilter(
        operator: StationOperator.taiba,
        cityId: 'idlib',
        product: FuelProduct.diesel,
      );
      expect(
        filter.results(shuffled, language: 'en', search: 'ariha').single.id,
        'taiba-ariha',
      );
    },
  );

  test('rejects broken joins and invalid calendar dates', () async {
    final encoded = await rootBundle.loadString(path);
    for (final mutation in [
      encoded.replaceFirst('"cityId": "damascus"', '"cityId": "unknown"'),
      encoded.replaceFirst(
        '"effectiveDate": "2026-10-15"',
        '"effectiveDate": "2026-02-31"',
      ),
      encoded.replaceFirst('"premium": 56000', '"premium": -1'),
      encoded.replaceFirst(
        '"availability": "available"',
        '"availability": "unknown"',
      ),
    ]) {
      expect(jsonDecode(mutation), isA<Map>());
      final assets = FixtureAssets()..files[path] = mutation;
      await expectLater(
        NetworkRepository(FixtureLoader(assets), path).load(),
        throwsA(isA<FixtureException>()),
      );
    }
  });

  testWidgets(
    'retries an unavailable network fixture and renders empty screens',
    (tester) async {
      final emptyJson = await tester.runAsync(
        () => rootBundle.loadString('assets/demo/standard/empty_network.json'),
      );
      final assets = FixtureAssets();
      final repo = NetworkRepository(FixtureLoader(assets), path);
      Widget surface(Widget page) => Provider.value(
        value: repo,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: page),
        ),
      );

      await tester.pumpWidget(surface(const StationsPage()));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not load stations or price bulletins.'),
        findsOneWidget,
      );
      assets.files[path] = emptyJson!;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No stations match your search.'), findsOneWidget);
      await tester.pumpWidget(surface(const PriceBulletinsPage()));
      await tester.pumpAndSettle();
      expect(find.text('No price bulletins to show.'), findsOneWidget);
    },
  );
  testWidgets('fuel availability uses the same three colors in both views', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() => rootBundle.loadString(path));
    final assets = FixtureAssets()..files[path] = fixture!;
    final repo = NetworkRepository(FixtureLoader(assets), path);

    for (final page in [
      const Scaffold(body: StationsPage()),
      const StationDetailsPage(stationId: 'dam-depot'),
    ]) {
      await tester.pumpWidget(
        Provider.value(
          value: repo,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (page is Scaffold) {
        await tester.enterText(
          find.byKey(const Key('station-search')),
          'marota city',
        );
        await tester.pumpAndSettle();
      }
      for (final (label, background, foreground) in [
        ('Diesel · Available', 0xffdff5e7, 0xff14633b),
        ('Gasoline 90 · Running low', 0xffffefad, 0xff694a00),
        ('Gasoline 95 · Not available', 0xffffe2e0, 0xff9b2226),
      ]) {
        final text = find.text(label);
        expect(tester.widget<Text>(text).style?.color, Color(foreground));
        expect(
          find.ancestor(
            of: text,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color ==
                      Color(background),
            ),
          ),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets(
    'clearing filters lets a replacement search show a different station',
    (tester) async {
      final fixture = await tester.runAsync(() => rootBundle.loadString(path));
      final assets = FixtureAssets()..files[path] = fixture!;
      await tester.pumpWidget(
        Provider(
          create: (_) => NetworkRepository(FixtureLoader(assets), path),
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: StationsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      final search = find.byKey(const Key('station-search'));
      await tester.enterText(search, 'marota city');
      await tester.pumpAndSettle();
      await tap(find.byTooltip('Filter'));
      await tap(find.widgetWithText(ChoiceChip, 'Damascus'));
      await tap(find.widgetWithText(ChoiceChip, 'Diesel'));
      await tap(find.text('Apply filters'));
      expect(find.text('Marota City – Damascus'), findsOneWidget);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      await tap(find.byTooltip('Filter'));
      await tap(find.text('Clear filters'));
      await tap(find.text('Apply filters'));
      expect(find.byType(InputChip), findsNothing);
      await tester.enterText(search, 'hassia');
      await tester.pumpAndSettle();
      expect(find.text('Hassia – Homs'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    },
  );
}
