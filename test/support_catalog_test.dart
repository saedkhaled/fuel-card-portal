import 'dart:convert';
import 'dart:io';

import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/stations/station_network.dart';
import 'package:fleet_cards_demo/features/support/support_catalog.dart';
import 'package:fleet_cards_demo/features/support/support_stations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> sampleCatalog() =>
    jsonDecode(File(SupportRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sample catalog matches Arabic variants and a known English alias', () {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    expect(
      catalog.findAnswer('كيف أتحقق من رصيد بطاقتي؟')?.id,
      'check-balance',
    );
    expect(
      catalog.findAnswer('مرحبا، وين بشُوف الرصيد تبعي؟')?.id,
      'check-balance',
    );
    expect(
      catalog.requestsNearestStation('I need the NEAREST STATION.'),
      isTrue,
    );
    expect(catalog.findAnswer('كيف عبّي رصيدي؟')?.id, 'top-up');
    expect(catalog.findAnswer('كيف فيني اشحن البطاقة؟')?.id, 'top-up');
    expect(catalog.findAnswer('وين الفواتير؟')?.id, 'view-invoices');
    expect(catalog.findAnswer('قديش سعر المازوت؟')?.id, 'find-prices');
  });

  test('answers station questions from the shared official network', () async {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    for (final question in ['محطات', 'وين بلاقي محطة؟', 'Show station map']) {
      expect(catalog.findAnswer(question)?.sourceUrl, officialStationsMap);
      expect(catalog.findAnswer(question)?.route, isNull);
      expect(catalog.requestsNearestStation(question), isFalse);
    }
    expect(catalog.requestsNearestStation('جيبلي أقرب كازية'), isTrue);
    expect(catalog.requestsNearestStation('nearest train station'), isFalse);
    expect(catalog.findAnswer('nearest train station'), isNull);
    expect(catalog.requestsNearestStation('أقرب محطة في التطبيق'), isTrue);
    expect(catalog.findAnswer('أقرب محطة في التطبيق')?.id, 'find-station');
    final network = await NetworkRepository(
      FixtureLoader(rootBundle),
      'assets/demo/standard/network.json',
    ).load();
    final partner = nearestOfficialStation(network.stations.values, (
      latitude: 35.807,
      longitude: 36.595,
    ));
    expect(network.stations, hasLength(21));
    expect(partner?.name.en, 'Ariha – Idlib');
    expect(
      partner?.googleMapsDirections?.queryParameters['destination'],
      '35.808446,36.594742',
    );
    expect(
      partner?.googleMapsDirections?.queryParameters.containsKey('origin'),
      isFalse,
    );
  });

  test('company answers use the relevant official website sections', () {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    final cases = {
      'كيف بتشتغل بطاقة البوابة الذهبية؟': ('company-card', 'card'),
      'كيف بطلع بطاقة وقود؟': ('company-card-contact', 'contact'),
      'وين فيني عبّي ببطاقة البوابة الذهبية؟': (
        'company-card-network',
        'stations',
      ),
      'وين محطات الوقود في حمص؟': ('company-stations-homs', 'stations'),
      'محطة ٤٧': ('guide-station-18', 'stations'),
      'توفر البنزين اليوم': ('company-live-stocks', 'stations'),
      'كيف بطلب مازوت لمعملي؟': ('company-facility-request', 'facility-supply'),
      'سعر الوقود للمنشآت': ('company-facility-pricing', 'facility-supply'),
      'رقم شركة البوابة الذهبية لو سمحت': ('company-contact', 'contact'),
    };
    for (final MapEntry(key: query, value: (id, section)) in cases.entries) {
      final answer = catalog.findAnswer(query);
      expect(answer?.id, id, reason: query);
      expect(answer?.sourceUrl, Uri.parse('https://goldengate.sy/#$section'));
      expect(answer?.route, isNull);
    }
  });

  test('ranks guide passages for wording absent from the catalog', () {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    final cases = {
      'من وين بقدر استلم كرتي الجديد؟': 'company-card-contact',
      'حوالتي تأخرت، قديش بتاخد لينضاف المبلغ؟': 'guide-transfer-time',
      'إذا بعت حوالة شام كاش إمتى بيظهر الرصيد؟': 'guide-transfer-time',
      'هل يوجد مازوت في حسياء؟': 'guide-station-05',
      'قديش قيمتها رسوم الكرت الشهرية؟': 'guide-subscription',
      'إذا ما سددت اشتراكي بتوقف بطاقتي؟': 'guide-subscription-suspension',
      'وين موقع الشيخ نجار بالضبط؟': 'guide-station-01',
      'شو البنزين اللي مدرج عند دوار القلعة؟': 'guide-station-02',
    };
    for (final MapEntry(key: question, value: id) in cases.entries) {
      final answer = catalog.findAnswer(question);
      expect(answer?.id, id, reason: question);
      expect(answer?.guideSection, isNotEmpty, reason: question);
    }
    expect(catalog.findAnswer('كيف بسترجع حوالة أرسلتها بالغلط؟'), isNull);
  });

  test('uses a previously selected topic for short follow-up questions', () {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    final topUp = catalog.findAnswer('شام كاش');
    expect(topUp?.id, 'guide-sham-cash');
    expect(
      catalog.findAnswer('طيب قديش بتاخد؟', previous: topUp)?.id,
      'guide-transfer-time',
    );
    final station = catalog.findAnswer('الشيخ نجار');
    expect(
      catalog.findAnswer('عندهم مازوت؟', previous: station)?.id,
      'guide-station-01',
    );
    expect(
      catalog.findAnswer('طيب شو دوام الدوام؟', previous: station),
      isNull,
    );
  });

  test('source links require the official HTTPS website', () {
    for (final source in [
      'http://goldengate.sy/#contact',
      'https://goldengate.sy.example.invalid/#contact',
      'https://goldengate.sy@other.example.invalid/#contact',
      'https://goldengate.sy/?next=other.example.invalid',
    ]) {
      final data = sampleCatalog();
      data['entries'][5]['source_url'] = source;
      expect(
        () => SupportCatalog.fromJson(data),
        throwsA(isA<FixtureException>()),
      );
    }
  });

  test('uncovered and ambiguous questions leave room for the FAQ', () {
    final catalog = SupportCatalog.fromJson(sampleCatalog());
    for (final question in [
      '؟!',
      'شو دوام خدمة العملاء اليوم؟',
      'وين بشوف الرصيد ووين أسعار الوقود؟',
      'crossfuel stationside',
    ]) {
      expect(catalog.findAnswer(question), isNull, reason: question);
    }
  });

  test('catalog rejects duplicate IDs and links outside the portal routes', () {
    final duplicate = sampleCatalog();
    final rows = duplicate['entries'] as List<dynamic>;
    rows.add(rows.first);
    expect(
      () => SupportCatalog.fromJson(duplicate),
      throwsA(isA<FixtureException>()),
    );

    final invalidLink = sampleCatalog();
    invalidLink['entries'][0]['app_route'] = 'https://example.invalid';
    expect(
      () => SupportCatalog.fromJson(invalidLink),
      throwsA(isA<FixtureException>()),
    );
  });
}
