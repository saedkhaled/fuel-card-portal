import 'dart:convert';
import 'dart:io';

import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/support/support_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> sampleCatalog() =>
    jsonDecode(File(SupportRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
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
      catalog.findAnswer('I need the NEAREST STATION.')?.id,
      'find-station',
    );
    expect(catalog.findAnswer('كيف عبّي رصيدي؟')?.id, 'top-up');
    expect(catalog.findAnswer('وين الفواتير؟')?.id, 'view-invoices');
    expect(catalog.findAnswer('قديش سعر المازوت؟')?.id, 'find-prices');
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
      'محطة ٤٧': ('company-stations-deir-ez-zor', 'stations'),
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
