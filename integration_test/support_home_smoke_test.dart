import 'dart:convert';

import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/finance/finance_widgets.dart';
import 'package:fleet_cards_demo/features/stations/station_network.dart';
import 'package:fleet_cards_demo/features/support/support_gemini.dart';
import 'package:fleet_cards_demo/features/support/support_stations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/memory_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home counts and official station actions on Android', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    const launchChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.url_launcher_android.UrlLauncherApi.launchUrl',
      StandardMessageCodec(),
    );
    final opened = <Uri>[];
    messenger.setMockDecodedMessageHandler(launchChannel, (message) async {
      opened.add(Uri.parse((message! as List<Object?>).first! as String));
      return [true];
    });
    var lookups = 0;
    final settings = <bool>[];
    messenger.setMockMethodCallHandler(stationLocationChannel, (call) async {
      if (call.method == 'openSettings') {
        settings.add(call.arguments['permission'] as bool);
        return true;
      }
      expect(call.method, 'currentLocation');
      if (++lookups == 2) throw PlatformException(code: 'permission_denied');
      if (lookups == 3) throw PlatformException(code: 'services_disabled');
      return {'latitude': 35.807, 'longitude': 36.595};
    });
    addTearDown(() {
      messenger.setMockDecodedMessageHandler(launchChannel, null);
      messenger.setMockMethodCallHandler(stationLocationChannel, null);
    });

    final loader = FixtureLoader(rootBundle);
    final sample = (await loader.load()).accounts.first;
    final sentToGemini = <String>[];
    await tester.pumpWidget(
      PortalBootstrap(
        loader: loader,
        preferences: MemoryPreferences(),
        now: DateTime.now,
        supportGemini: SupportGemini((request) async {
          final question = (jsonDecode(request) as Map)['question'] as String;
          sentToGemini.add(question);
          return switch (question) {
            'وين بلاقي محطة؟' => 'شوف الخريطة الرسمية: $officialStationsMap',
            'كيف فيني اشحن البطاقة؟' => 'افتح شحن الرصيد واختار البطاقة.',
            'كيف فيني اشحن الكرت؟' => 'حوّل على الرقم ٠٩٩٩١٢٣٤٥٦.',
            _ => null,
          };
        }),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(Finder finder) async {
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byKey(const Key('phone-field')), sample.phone);
    await tap(find.text('إرسال الرمز'));
    await tester.enterText(find.byKey(const Key('code-field')), sample.code);
    await tester.pumpAndSettle();
    await tap(find.text('ليس الآن'));
    final hero = find.byType(BalanceHero);
    for (final label in ['بطاقات الوقود', '4', 'الحركات', '9']) {
      expect(
        find.descendant(of: hero, matching: find.text(label)),
        findsOneWidget,
      );
    }
    final activity = tester.getTopLeft(find.text('النشاط الأخير')).dy;
    for (final shortcut in ['المبيعات', 'نشرات الأسعار']) {
      expect(tester.getBottomLeft(find.text(shortcut)).dy, lessThan(activity));
    }

    await tap(find.byIcon(Icons.support_agent_outlined));
    expect(find.text('المساعد الذكي'), findsOneWidget);
    await tap(find.widgetWithText(ActionChip, 'دلّني على أقرب محطة'));
    expect(lookups, 1);
    expect(opened, isEmpty);
    expect(find.textContaining('أريحا – إدلب'), findsOneWidget);
    await tap(find.text('الاتجاهات على خرائط Google').hitTestable().first);
    expect(opened.single.queryParameters['destination'], '35.808446,36.594742');
    expect(opened.single.queryParameters.containsKey('origin'), isFalse);

    Future<void> send(String question) async {
      await tester.enterText(find.byType(TextField), question);
      await tester.pumpAndSettle();
      await tap(find.byTooltip('إرسال السؤال'));
    }

    await send('وين بلاقي محطة؟');
    await tap(find.text(officialStationsMap.toString()).hitTestable().first);
    expect(opened.last, officialStationsMap);
    await send('محطات التطبيق');
    expect(find.textContaining('نفس محطات ووحدات غولدن غيت'), findsOneWidget);
    expect(lookups, 1);

    await send('كيف فيني اشحن البطاقة؟');
    expect(find.text('افتح شحن الرصيد واختار البطاقة.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'شحن الرصيد'), findsOneWidget);
    await send('كيف فيني اشحن الكرت؟');
    expect(find.textContaining('لتشحن بطاقتك'), findsOneWidget);
    await send('وين رمز التحقق 123456؟');
    expect(find.textContaining('خارج المحادثة'), findsOneWidget);

    await send('جيبلي أقرب كازية');
    expect(lookups, 2);
    expect(find.textContaining('اسمح بالوصول لموقعك'), findsOneWidget);
    expect(opened, hasLength(2));
    await tap(find.text('إعدادات الموقع').hitTestable().first);
    expect(settings, [true]);
    await tap(
      find.text('ابحث عن المحطات على خرائط Google').hitTestable().first,
    );
    expect(opened.last, stationSearchInGoogleMaps);
    await tap(find.text('جرّب تحديد الموقع مرة تانية').hitTestable().first);
    expect(lookups, 3);
    expect(find.textContaining('خدمة الموقع مطفّاة'), findsOneWidget);
    await tap(find.text('إعدادات الموقع').hitTestable().first);
    expect(settings, [true, false]);
    expect(sentToGemini, [
      'وين بلاقي محطة؟',
      'كيف فيني اشحن البطاقة؟',
      'كيف فيني اشحن الكرت؟',
    ]);
  });
}
