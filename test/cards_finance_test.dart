import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:fleet_cards_demo/features/cards/card_notes.dart';
import 'package:fleet_cards_demo/features/cards/fleet_card.dart';
import 'package:fleet_cards_demo/features/finance/finance_export.dart';
import 'package:fleet_cards_demo/features/finance/finance_models.dart';
import 'package:fleet_cards_demo/features/finance/finance_tables.dart';
import 'package:fleet_cards_demo/features/finance/fleet_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FixtureLoader(rootBundle);

  Future<AccountFinance> finance([String? scenario]) async {
    final fixtures = await loader.load(scenario: scenario);
    return (await FleetData.load(
      loader,
      fixtures,
    )).forAccount(fixtures.accounts.first.id);
  }

  test('consistent card scope, balances and dated feed', () async {
    final data = await finance();
    expect(data.totalBalance, 38045000);
    expect(
      data.cards
          .where((card) => card.matches(' dam ', CardStatus.active))
          .map((c) => c.id),
      ['fc-101', 'fc-104'],
    );
    expect(
      data.cards.where((card) => card.matches('HMS', CardStatus.active)),
      isEmpty,
    );
    expect(data.recent, hasLength(4));
    expect(data.operationLog('fc-101').map((row) => row.id), [
      'op-001',
      'op-002',
      'op-004',
      'op-006',
    ]);
    final nov25 = DateTime(2026, 11, 25);
    expect(
      data
          .operationLog(
            'fc-101',
            FinanceFilter(
              operation: OperationType.refill,
              from: nov25,
              to: nov25,
            ),
          )
          .single
          .id,
      'op-001',
    );
    final invalid = FinanceFilter(from: nov25, to: DateTime(2026, 11, 24));
    expect(invalid.isValid, isFalse);
    expect(data.operationLog('fc-101', invalid), isEmpty);
    expect(
      data
          .filteredSales(
            FinanceFilter(
              cardId: 'fc-101',
              product: FuelProduct.diesel,
              from: nov25,
              to: nov25,
            ),
          )
          .single
          .receipt,
      'RC-3104',
    );
    expect(
      data.filteredSales(
        const FinanceFilter(cardId: 'fc-101', product: FuelProduct.premium),
      ),
      isEmpty,
    );
    expect((await finance('quiet')).recent, isEmpty);
    expect((await finance('empty')).totalBalance, 0);
    expect((await finance('empty')).cards, isEmpty);
  });

  test('rejects orphan balances and separates accounts', () async {
    final fixtures = await loader.load();
    final data = await FleetData.load(loader, fixtures);
    expect(data.forAccount('another-account').cards, isEmpty);
    expect(data.forAccount('another-account').sales, isEmpty);
    final fixtureAssets = FixtureAssets()
      ..files[fixtures.files['finance']!] = jsonEncode({
        'currency': 'SYP',
        'minorDigits': 2,
        'clockAnchor': '2026-11-25T12:00:00Z',
        'balances': [
          {'cardId': 'unknown', 'amountMinor': 1},
        ],
        'operations': [],
        'sales': [],
        'stations': [],
      });
    final badLoader = FixtureLoader(fixtureAssets);
    final bad = await badLoader.load();
    await expectLater(
      FleetData.load(badLoader, bad),
      throwsA(isA<FixtureException>()),
    );
  });

  test(
    'note edits, tombstones and 500 graphemes survive reconstruction',
    () async {
      final data = await finance();
      final first = data.cards.first;
      final preferences = MemoryPreferences();
      final store = CardNotes(preferences, 'standard');
      expect(await store.read(first), 'North route');
      final long = List.filled(500, '👨‍👩‍👧‍👦').join();
      await store.save(first, long);
      await expectLater(store.save(first, '${long}a'), throwsArgumentError);
      final restarted = CardNotes(preferences, 'standard');
      expect(await restarted.read(first), long);
      expect(await restarted.read(data.cards[1]), isNull);
      final quiet = CardNotes(preferences, 'quiet');
      expect(await quiet.read(first), 'North route');
      await restarted.save(first, null);
      final afterDelete = CardNotes(preferences, 'standard');
      expect(await afterDelete.read(first), isNull);
      for (final repository in [store, restarted, quiet, afterDelete]) {
        repository.dispose();
      }
    },
  );

  test(
    'exports the filtered snapshot and protects text in both formats',
    () async {
      final data = await finance();
      final card = data.cards.first;
      final filtered = data.operationLog(
        card.id,
        const FinanceFilter(operation: OperationType.refill),
      );
      final operations = operationsTable(card, filtered);
      final csv = utf8.decode(operations.encode(FinanceExportFormat.csv));
      expect(
        csv,
        contains(
          '"op-001","FC-0101","refill","2026-11-25T09:12:00.000Z",-16500.0',
        ),
      );
      expect(csv, isNot(contains('op-002')));
      final workbook = Excel.decodeBytes(
        operations.encode(FinanceExportFormat.xlsx),
      );
      final sheet = workbook.tables.values.single;
      expect(sheet.rows, hasLength(2));
      final exported = sheet.rows.last[4]!.value;
      expect(switch (exported) {
        IntCellValue(:final value) => value,
        DoubleCellValue(:final value) => value,
        _ => null,
      }, -16500);
      final notes = CardNotes(MemoryPreferences(), 'standard');
      await notes.save(card, '=SUM(1,2)\n"fleet"');
      final cards = await cardsTable([card], data, notes);
      expect(
        utf8.decode(cards.encode(FinanceExportFormat.csv)),
        contains('''"'=SUM(1,2)
""fleet"""'''),
      );
      final noteWorkbook = Excel.decodeBytes(
        cards.encode(FinanceExportFormat.xlsx),
      );
      final note = noteWorkbook.tables.values.single.rows.last.last!.value;
      expect(note, isA<TextCellValue>());
      expect(note.toString(), '=SUM(1,2)\n"fleet"');
      notes.dispose();
    },
  );
}
