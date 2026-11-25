import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/app/portal_destinations.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/support/support_catalog.dart';
import 'package:fleet_cards_demo/features/support/support_gemini.dart';
import 'package:fleet_cards_demo/features/support/support_page.dart';
import 'package:fleet_cards_demo/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';

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
    expect(find.text('المساعد'), findsOneWidget);
    expect(find.text('مساعد البوابة الذهبية الذكي'), findsOneWidget);
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
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Golden Gate AI Assistant'), findsOneWidget);
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
      findsNothing,
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
      findsNothing,
    );
    await enterQuestion('Who are you?');
    await tap(find.byTooltip('Send question'));
    expect(
      find.textContaining('I’m Golden Gate AI Assistant.'),
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

  testWidgets('shows clean replies, scope messages and offline fallback', (
    tester,
  ) async {
    final catalog = await tester.runAsync(
      () => rootBundle.loadString(SupportRepository.assetPath),
    );
    final assets = FixtureAssets()
      ..files[SupportRepository.assetPath] = catalog!;
    var calls = 0;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => SupportRepository(FixtureLoader(assets))),
          Provider<SupportGemini?>.value(
            value: SupportGemini((_) async {
              calls++;
              if (calls == 5) return null;
              if (calls == 4) {
                return '{"status":"out_of_scope","text":"","sourceId":""}';
              }
              if (calls == 3) {
                return '{"status":"no_answer","text":"","sourceId":""}';
              }
              if (calls == 2) {
                return '{"status":"answer","text":"يُضاف الرصيد خلال 24 ساعة عمل.","sourceId":"guide-transfer-time"}';
              }
              return '{"status":"answer","text":"جواب تجريبي من Gemini","sourceId":"company-card"}';
            }),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SupportPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ActionChip, 'كيف بتشتغل بطاقة البوابة الذهبية؟'),
    );
    await tester.pump();
    expect(find.text('عم ببحث عن جواب…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('جواب تجريبي من Gemini'), findsOneWidget);
    expect(find.text('إجابة عبر Gemini'), findsNothing);
    expect(find.text('المصدر: موقع البوابة الذهبية'), findsNothing);

    final composer = tester.widget<TextField>(find.byType(TextField));
    composer.controller!.text = 'إذا بعت حوالة شام كاش إمتى بيظهر الرصيد؟';
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إرسال السؤال'));
    await tester.pumpAndSettle();
    expect(find.text('يُضاف الرصيد خلال 24 ساعة عمل.'), findsOneWidget);
    expect(find.textContaining('المصدر: دليل خدمة العملاء'), findsNothing);

    composer.controller!.text = 'هل في محطة النور بتقبل بطاقة البوابة الذهبية؟';
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إرسال السؤال'));
    await tester.pumpAndSettle();
    expect(find.text('ما عندي جواب مؤكد لهالسؤال.'), findsOneWidget);
    expect(find.text('بحث محلي'), findsNothing);

    composer.controller!.text = 'احكيلي وصفة كيك';
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إرسال السؤال'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('فيني ساعدك بأسئلة عن البوابة الذهبية'),
      findsOneWidget,
    );
    expect(find.text('بحث محلي'), findsNothing);

    composer.controller!.text = 'كيف بتشتغل بطاقة البوابة الذهبية؟';
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إرسال السؤال'));
    await tester.pumpAndSettle();
    expect(find.textContaining('هي بطاقة وقود مسبقة الدفع'), findsOneWidget);
    expect(find.text('بحث محلي'), findsNothing);
    expect(calls, 5);
  });
}
