import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline Android launch through JSON login and shell', (
    tester,
  ) async {
    final sample = (await FixtureLoader(rootBundle).load()).accounts.first;
    app.main();
    await tester.pumpAndSettle();
    final phone = find.byKey(const Key('phone-field'));
    expect(phone, findsOneWidget);
    expect(Directionality.of(tester.element(phone)), TextDirection.rtl);
    await tester.tap(find.byTooltip('اللغة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(phone)), TextDirection.ltr);
    await tester.enterText(phone, sample.phone);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Fleet overview'), findsOneWidget);
    await tester.tap(
      find.widgetWithIcon(NavigationDestination, Icons.credit_card_outlined),
    );
    await tester.pumpAndSettle();
    expect(find.text('Search card number or plate'), findsOneWidget);
    await tester.tap(
      find.widgetWithIcon(NavigationDestination, Icons.dashboard_outlined),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fleet overview'), findsOneWidget);
  });
}
