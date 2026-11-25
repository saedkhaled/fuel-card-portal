import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('account services and the inbox work offline in both locales', (
    tester,
  ) async {
    final fixtures = await FixtureLoader(rootBundle).load();
    final sample = fixtures.accounts.first;
    app.main();
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      final bar = tester.element(find.byType(AppBar).first);
      await tap(
        find.byTooltip(MaterialLocalizations.of(bar).backButtonTooltip),
      );
    }

    Future<void> tile(String name, {double delta = 150}) async {
      final target = find.widgetWithText(ListTile, name).hitTestable();
      await tester.scrollUntilVisible(target, delta);
      await tap(target);
    }

    Future<void> expectUnreadActivity() async {
      final unread = find.text('Unread · 1').hitTestable();
      await tester.scrollUntilVisible(unread, 145);
      expect(unread, findsOneWidget);
    }

    await tap(find.byTooltip('اللغة'));
    await tap(find.text('English'));
    await tester.enterText(find.byKey(const Key('phone-field')), sample.phone);
    await tap(find.text('Send code'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(find.text('Not now'));
    await expectUnreadActivity();
    await tap(find.byIcon(Icons.menu));
    expect(find.text('Cedar Fleet Logistics'), findsOneWidget);
    await tile('Monthly subscription');
    final card = find.textContaining('FC-0101');
    await tester.scrollUntilVisible(card, 150);
    await tap(card);
    expect(find.text('Invoice history'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
    await back();
    final exempt = find.textContaining('FC-0103');
    await tester.scrollUntilVisible(exempt, 150);
    await tap(exempt);
    expect(find.text('Exempt'), findsOneWidget);
    expect(find.text('No invoices to show.'), findsOneWidget);
    await back();
    await back();

    await tile('Top up balance');
    expect(find.text('Demo transfer QR'), findsOneWidget);
    final copyDestination = find.byTooltip('Copy destination').hitTestable();
    await tester.scrollUntilVisible(copyDestination, 150);
    await tap(copyDestination);
    expect(
      (await Clipboard.getData(Clipboard.kTextPlain))?.text,
      'DEMO-TRANSFER-104',
    );
    final copyNote = find.byTooltip('Copy transfer note').hitTestable();
    await tester.scrollUntilVisible(copyNote, 150);
    await tap(copyNote);
    expect(
      (await Clipboard.getData(Clipboard.kTextPlain))?.text,
      'DEMO TOP-UP | FC-0101 | DAM 1284',
    );
    await back();

    await tile('Important information');
    await tap(find.text('Where can I review card activity?'));
    expect(find.textContaining('export a report'), findsOneWidget);
    await back();
    await tile('Notification settings');
    await tap(find.byType(SwitchListTile));
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await back();
    await tap(find.byTooltip('Notifications'));
    expect(find.text('Diesel available at South Depot'), findsOneWidget);
    await tap(find.text('Diesel available at South Depot'));
    expect(find.text('Station details'), findsOneWidget);
    await back();
    expect(find.byTooltip('Mark as read'), findsOneWidget);
    await back();
    await tap(find.byIcon(Icons.dashboard_outlined));
    await expectUnreadActivity();
    final viewAll = find.widgetWithText(TextButton, 'View all').hitTestable();
    await tester.scrollUntilVisible(viewAll, -145);
    await tap(viewAll);
    expect(find.text('Fuel prices updated'), findsOneWidget);
    await back();
    await tap(find.byIcon(Icons.menu));
    await tile('Notifications');
    expect(find.text('Fuel prices updated'), findsOneWidget);
    await back();

    await tile('About');
    expect(find.text('App version'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    await tap(find.text('Support'));
    expect(find.text('Demo support contact'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await back();
    await tile('Language', delta: -100);
    await tap(find.text('العربية'));
    expect(find.text('حول التطبيق'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('حول التطبيق'))),
      TextDirection.rtl,
    );
    await tile('تسجيل الخروج');
    await tap(find.text('إلغاء'));
    await tile('تسجيل الخروج');
    await tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
    expect(find.byKey(const Key('phone-field')), findsOneWidget);
  });
}
