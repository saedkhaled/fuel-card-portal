import 'package:fleet_cards_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'home, card details and balances use the same offline finance data',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.byTooltip('اللغة'));
      await tap(find.text('English'));
      await tester.enterText(
        find.byKey(const Key('phone-field')),
        '0900000000',
      );
      await tap(find.text('Send code'));
      await tester.enterText(find.byKey(const Key('code-field')), '246810');
      await tester.pumpAndSettle();
      await tap(find.text('Not now'));
      expect(find.text('Total balance'), findsOneWidget);
      await tap(
        find.ancestor(
          of: find.text('Cards'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
      );
      await tap(find.widgetWithText(ChoiceChip, 'Active'));
      final search = find.byKey(const Key('card-search'));
      await tester.enterText(search, 'dam 1284');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.textContaining('FC-0101'), findsOneWidget);
      expect(find.textContaining('FC-0104'), findsNothing);
      await tap(find.widgetWithText(FilledButton, 'Card details'));

      await tap(find.text('Note'));
      final editor = find.byKey(const Key('card-note-editor'));
      await tester.enterText(editor, 'QA note');
      await tap(find.text('Save note'));
      expect(find.text('QA note'), findsOneWidget);
      await tap(find.text('Financial operations'));
      final log = find.text('Operations log');
      await tester.scrollUntilVisible(log, 200);
      await tap(log);
      expect(find.text('Withdrawal'), findsNothing);
      expect(find.text('Deposit'), findsOneWidget);
      await tap(find.text('Filter'));
      await tap(find.widgetWithText(ChoiceChip, 'Deposit'));
      await tap(find.text('Apply filters'));
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Refill'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('dam 1284'), findsOneWidget);

      await tap(find.byIcon(Icons.menu));
      final balances = find.widgetWithText(ListTile, 'Balances');
      await tester.scrollUntilVisible(balances, 200);
      await tap(balances);
      expect(find.text('Total balance'), findsOneWidget);
      await tap(find.byTooltip('Export'));
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('XLSX'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(find.text('Operations log').first);
      expect(find.textContaining('FC-0101'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Refill'), findsOneWidget);
      expect(find.text('Withdrawal'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sales'), 180);
      await tap(find.text('Sales'));
      expect(find.textContaining('RC-3104'), findsOneWidget);
      await tap(find.text('Filter'));
      await tap(find.widgetWithText(ChoiceChip, 'Diesel'));
      await tap(find.text('Apply filters'));
      expect(find.textContaining('RC-3104'), findsOneWidget);
      expect(find.textContaining('RC-3091'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(
        find.widgetWithIcon(NavigationDestination, Icons.dashboard_outlined),
      );
      final salesShortcut = find.text('Sales');
      await tester.scrollUntilVisible(salesShortcut, 145);
      await tap(salesShortcut);
      expect(find.textContaining('RC-3104'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(
        find.widgetWithIcon(NavigationDestination, Icons.credit_card_outlined),
      );
      await tap(find.widgetWithText(ChoiceChip, 'Stopped'));
      await tester.enterText(search, 'HMS 4902');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.textContaining('FC-0103'), findsOneWidget);
      expect(find.text('This card has no activation date.'), findsOneWidget);
    },
  );
}
