import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline stations and bulletins in Arabic and English', (
    tester,
  ) async {
    final sample = (await FixtureLoader(rootBundle).load()).accounts.first;
    app.main();
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      final appBar = tester.element(find.byType(AppBar).first);
      await tap(
        find.byTooltip(MaterialLocalizations.of(appBar).backButtonTooltip),
      );
    }

    await tap(find.byTooltip('اللغة'));
    await tap(find.text('English'));
    await tester.enterText(find.byKey(const Key('phone-field')), sample.phone);
    await tap(find.text('Send code'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(find.text('Not now'));

    await tap(find.byIcon(Icons.local_gas_station_outlined));
    final search = find.byKey(const Key('station-search'));
    await tester.enterText(search, 'depot road');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(find.byTooltip('Filter'));
    await tap(find.widgetWithText(ChoiceChip, 'Damascus'));
    await tap(find.widgetWithText(ChoiceChip, 'Diesel'));
    await tap(find.text('Apply filters'));
    expect(find.text('South Depot'), findsOneWidget);
    expect(find.text('Junction Station'), findsNothing);
    await tap(find.text('Station details'));
    expect(find.text('Fuel availability'), findsOneWidget);
    await tap(find.text('Directions'));
    expect(find.text('Demo directions'), findsOneWidget);
    expect(find.text('Follow Depot Road to the second gate.'), findsOneWidget);
    await back();
    await back();
    expect(find.text('depot road'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Damascus'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Diesel'), findsOneWidget);

    await tap(find.byTooltip('Filter'));
    await tap(find.text('Clear filters'));
    await tap(find.text('Apply filters'));
    expect(find.byType(InputChip), findsNothing);
    await tap(search);
    await tester.enterText(search, 'junction');
    await tester.pumpAndSettle();
    expect(find.text('junction'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Junction Station'), findsOneWidget);
    expect(find.text('Directions'), findsNothing);

    await tap(find.byIcon(Icons.dashboard_outlined));
    final pricesShortcut = find.text('Price bulletins');
    await tester.scrollUntilVisible(pricesShortcut, 140);
    await tap(pricesShortcut);
    expect(find.text('Current bulletin'), findsOneWidget);
    await tap(find.text('View bulletin'));
    expect(find.textContaining('Nov 24, 2026'), findsOneWidget);
    expect(find.textContaining('500.00 SYP'), findsOneWidget);
    await back();
    final previousDate = find.text('Nov 1, 2026');
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
    await tap(find.byIcon(Icons.local_gas_station_outlined));
    await tap(search);
    await tester.enterText(search, 'التقاطع الشرقي');
    await tester.pumpAndSettle();
    expect(find.text('محطة التقاطع'), findsOneWidget);
  });
}
