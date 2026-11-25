import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/app/portal_destinations.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';
import 'package:fleet_cards_demo/features/support/support_catalog.dart';

void main() {
  testWidgets('Arabic support tab answers and keeps draft until logout', (
    tester,
  ) async {
    final assets = FixtureAssets();
    final loader = FixtureLoader(assets);
    await tester.runAsync(() async {
      final bundleLoader = FixtureLoader(rootBundle);
      final standard = await bundleLoader.load();
      for (final path in [
        FixtureLoader.manifestPath,
        ...standard.files.values,
        SupportRepository.assetPath,
      ]) {
        assets.files[path] = await rootBundle.loadString(path);
      }
    });
    final sample = (await loader.load()).accounts.first;
    await tester.pumpWidget(
      PortalBootstrap(
        loader: loader,
        preferences: MemoryPreferences(),
        now: DateTime.now,
        initialLocation: PortalDestinations.support,
      ),
    );

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final phone = find.byKey(const Key('phone-field'));
    final composer = find.byType(TextField);
    Future<void> enterQuestion(String question) async {
      tester.widget<TextField>(composer).controller!.text = question;
      await tester.pumpAndSettle();
    }

    final support = find.widgetWithIcon(
      NavigationDestination,
      Icons.support_agent_outlined,
    );
    final cards = find.widgetWithIcon(
      NavigationDestination,
      Icons.credit_card_outlined,
    );
    final more = find.widgetWithIcon(NavigationDestination, Icons.menu);
    await tester.pumpAndSettle();
    expect(support, findsNothing);
    expect(Directionality.of(tester.element(phone)), TextDirection.rtl);
    await tester.enterText(phone, sample.phone);
    await tap(find.text('إرسال الرمز'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(find.text('ليس الآن'));

    await tap(cards);
    await tap(support);
    final bar = find.byType(NavigationBar);
    expect(tester.getCenter(support).dx, closeTo(tester.getCenter(bar).dx, 1));
    expect(tester.widget<NavigationBar>(bar).selectedIndex, 2);
    await tester.tap(
      find.widgetWithText(ActionChip, 'كيف أتحقق من رصيد بطاقتي؟'),
    );
    await tester.pump();
    expect(find.text('عم ببحث عن جواب…'), findsOneWidget);
    expect(find.textContaining('ستجد رصيد كل بطاقة'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('عم ببحث عن جواب…'), findsNothing);
    expect(find.textContaining('ستجد رصيد كل بطاقة'), findsOneWidget);
    await tap(find.widgetWithText(TextButton, 'الأرصدة'));
    expect(find.text('إجمالي الرصيد'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await enterQuestion('وين بلاقي محطة؟');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(bar).selectedIndex, 1);
    await tap(support);
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'وين بلاقي محطة؟',
    );
    await tap(find.byTooltip('إرسال السؤال'));
    expect(find.textContaining('صفِّ النتائج حسب المدينة'), findsOneWidget);

    await enterQuestion('شو دوام خدمة العملاء؟');
    await tap(find.byTooltip('إرسال السؤال'));
    expect(find.textContaining('ما لقيت جواب'), findsOneWidget);
    await tap(find.widgetWithText(TextButton, 'الأسئلة الشائعة'));
    expect(find.byType(ExpansionTile), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tap(more);
    final language = find.widgetWithText(ListTile, 'اللغة');
    await tester.scrollUntilVisible(language, 220);
    await tap(language);
    await tap(find.text('English'));
    await tap(support);
    expect(Directionality.of(tester.element(composer)), TextDirection.ltr);
    expect(tester.getCenter(support).dx, closeTo(tester.getCenter(bar).dx, 1));
    expect(find.textContaining('ما لقيت جواب'), findsOneWidget);
    await enterQuestion('رقم البوابة الذهبية');
    await tap(find.byTooltip('Send question'));
    expect(
      find.textContaining('info@goldengate.sy').hitTestable(),
      findsOneWidget,
    );
    expect(
      find.text('Source: Golden Gate website').hitTestable(),
      findsOneWidget,
    );
    await enterQuestion('check balance');
    await tap(find.byTooltip('Send question'));
    expect(
      find.textContaining('ستجد رصيد كل بطاقة').hitTestable(),
      findsOneWidget,
    );
    await enterQuestion('من وين بقدر استلم كرتي الجديد؟');
    await tap(find.byTooltip('Send question'));
    expect(find.textContaining('ماروتا سيتي').hitTestable(), findsOneWidget);
    expect(
      find.textContaining('Source: Customer guide').hitTestable(),
      findsOneWidget,
    );
    await enterQuestion('private draft');

    await tap(more);
    final logout = find.widgetWithText(ListTile, 'Sign out');
    await tester.scrollUntilVisible(logout, 220);
    await tap(logout);
    await tap(find.widgetWithText(FilledButton, 'Sign out'));
    expect(support, findsNothing);
    await tester.enterText(phone, sample.phone);
    await tap(find.text('Send code'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(support);
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
    expect(find.textContaining('ستجد رصيد كل بطاقة'), findsNothing);
  });
}
