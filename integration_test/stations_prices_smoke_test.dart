import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/app/portal_theme.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/memory_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline stations and bulletins in Arabic and English', (
    tester,
  ) async {
    final loader = FixtureLoader(rootBundle);
    final sample = (await loader.load()).accounts.first;
    const launchChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.url_launcher_android.UrlLauncherApi.launchUrl',
      StandardMessageCodec(),
    );
    final messenger = tester.binding.defaultBinaryMessenger;
    final launchedUrls = <Uri>[];
    messenger.setMockDecodedMessageHandler(launchChannel, (message) async {
      final arguments = message! as List<Object?>;
      launchedUrls.add(Uri.parse(arguments.first! as String));
      return [launchedUrls.length == 1];
    });
    addTearDown(
      () => messenger.setMockDecodedMessageHandler(launchChannel, null),
    );

    await tester.pumpWidget(
      PortalBootstrap(
        loader: loader,
        preferences: MemoryPreferences(),
        now: DateTime.now,
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      final appBar = tester.element(find.byType(AppBar).first);
      await tap(
        find.byTooltip(MaterialLocalizations.of(appBar).backButtonTooltip),
      );
    }

    void expectAvailability() {
      expect(find.text('Fuel availability'), findsOneWidget);
      for (final (label, color) in [
        ('Diesel · Available', 0xff14633b),
        ('Gasoline 90 · Running low', 0xff694a00),
        ('Gasoline 95 · Not available', 0xff9b2226),
      ]) {
        expect(
          tester.widget<Text>(find.text(label)).style?.color,
          Color(color),
        );
      }
    }

    void expectCardTint(Finder title, Color expected, {Color? divider}) {
      final card = find.ancestor(of: title, matching: find.byType(Card));
      final tint = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (widget) => switch (widget) {
            Ink(decoration: BoxDecoration(gradient: LinearGradient())) => true,
            _ => false,
          },
        ),
      );
      final decoration = tester.widget<Ink>(tint).decoration! as BoxDecoration;
      expect((decoration.gradient! as LinearGradient).colors.first, expected);
      if (divider != null) {
        expect((decoration.border! as Border).bottom.color, divider);
        expect(tester.widget<Text>(title).style?.color, Colors.white);
      }
    }

    await tap(find.byTooltip('اللغة'));
    await tap(find.text('English'));
    await tester.enterText(find.byKey(const Key('phone-field')), sample.phone);
    await tap(find.text('Send code'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(find.text('Not now'));

    await tap(
      find.widgetWithIcon(
        NavigationDestination,
        Icons.local_gas_station_outlined,
      ),
    );
    final goldenStation = find.text('Sheikh Najjar – Aleppo');
    final partnerStation = find.text('New Damascus – Damascus');
    expect(goldenStation.hitTestable(), findsOneWidget);
    expect(partnerStation.hitTestable(), findsNothing);
    expectCardTint(goldenStation, portalNavy, divider: portalGold);
    await tap(find.byTooltip('Filter'));
    await tap(find.widgetWithText(ChoiceChip, 'Taiba partner stations'));
    await tap(find.text('Apply filters'));
    expect(goldenStation.hitTestable(), findsNothing);
    expect(partnerStation.hitTestable(), findsOneWidget);
    expectCardTint(partnerStation, const Color(0xffe5f6ed));
    await tap(find.byTooltip('Filter'));
    await tap(find.widgetWithText(ChoiceChip, 'Golden Gate'));
    await tap(find.text('Apply filters'));
    expect(goldenStation.hitTestable(), findsOneWidget);
    expect(partnerStation.hitTestable(), findsNothing);

    final search = find.byKey(const Key('station-search'));
    await tester.enterText(search, 'marota city');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(find.byTooltip('Filter'));
    await tap(find.widgetWithText(ChoiceChip, 'Damascus'));
    await tap(find.widgetWithText(ChoiceChip, 'Diesel'));
    await tap(find.text('Apply filters'));
    expect(find.text('Marota City – Damascus'), findsOneWidget);
    expect(find.text('Hassia – Homs'), findsNothing);
    expectAvailability();
    await tap(find.text('Directions'));
    expect(launchedUrls.single.host, 'www.google.com');
    expect(launchedUrls.single.path, '/maps/dir/');
    expect(launchedUrls.single.queryParameters, {
      'api': '1',
      'destination': '33.4932607,36.2623043',
      'travelmode': 'driving',
    });
    expect(find.text('Demo directions'), findsNothing);
    await tap(find.text('Station details'));
    expectAvailability();
    await tap(find.text('Directions'));
    expect(launchedUrls, hasLength(2));
    expect(launchedUrls.last, launchedUrls.first);
    final launchError = find.text('Could not open Google Maps.');
    expect(launchError, findsOneWidget);
    ScaffoldMessenger.of(tester.element(launchError)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await back();
    expect(find.text('marota city'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Damascus'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Diesel'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Golden Gate'), findsOneWidget);

    await tap(find.byTooltip('Filter'));
    await tap(find.text('Clear filters'));
    await tap(find.text('Apply filters'));
    expect(find.byType(InputChip), findsNothing);
    await tap(search);
    await tester.enterText(search, 'hassia');
    await tester.pumpAndSettle();
    expect(find.text('hassia'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Hassia – Homs'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);

    await tap(find.byIcon(Icons.dashboard_outlined));
    final pricesShortcut = find.text('Price bulletins').hitTestable();
    await tester.scrollUntilVisible(pricesShortcut, 140);
    await tap(pricesShortcut);
    expect(find.text('Current bulletin'), findsOneWidget);
    await tap(find.text('View bulletin'));
    expect(find.textContaining('Nov 24, 2026'), findsOneWidget);
    expect(find.textContaining('500.00 SYP'), findsOneWidget);
    await back();
    final previousDate = find.text('Nov 1, 2026').hitTestable();
    await tester.scrollUntilVisible(previousDate, 140);
    await tap(previousDate);
    expect(find.text('Previous bulletin'), findsOneWidget);
    expect(find.textContaining('485.00 SYP'), findsOneWidget);
    await back();
    await back();

    await tap(find.byIcon(Icons.menu));
    final language = find.text('Language').hitTestable();
    await tester.scrollUntilVisible(language, 180);
    await tap(language);
    await tap(find.text('العربية'));
    final arabicPrices = find.text('نشرات الأسعار').hitTestable();
    await tester.scrollUntilVisible(arabicPrices, -120);
    await tap(arabicPrices);
    expect(find.text('النشرة الحالية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('النشرة الحالية'))),
      TextDirection.rtl,
    );
    await back();
    await tap(
      find.widgetWithIcon(
        NavigationDestination,
        Icons.local_gas_station_outlined,
      ),
    );
    await tap(search);
    await tester.enterText(search, 'حسياء');
    await tester.pumpAndSettle();
    expect(find.text('حسياء – حمص'), findsOneWidget);
    expect(find.text('حالة توفر المادة'), findsOneWidget);
  });
}
