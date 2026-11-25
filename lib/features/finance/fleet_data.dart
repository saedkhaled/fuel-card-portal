import 'package:characters/characters.dart';

import '../../demo/demo_fixtures.dart';
import '../cards/fleet_card.dart';
import 'finance_models.dart';

class FleetData {
  const FleetData(this._data);

  final AccountFinance _data;

  AccountFinance forAccount(String? accountId) {
    final cards = _data.cards
        .where((card) => card.accountId == accountId)
        .toList(growable: false);
    final ids = cards.map((card) => card.id).toSet();
    return AccountFinance(
      cards: cards,
      balances: {for (final id in ids) id: _data.balance(id)},
      operations: _data.operations
          .where((row) => ids.contains(row.cardId))
          .toList(growable: false),
      sales: _data.sales
          .where((row) => ids.contains(row.cardId))
          .toList(growable: false),
      stations: _data.stations,
      clockAnchor: _data.clockAnchor,
    );
  }

  static Future<FleetData> load(
    FixtureLoader loader,
    DemoFixtures fixtures,
  ) async {
    final cardsPath = fixtures.files['cards'];
    final financePath = fixtures.files['finance'];
    if (cardsPath == null || financePath == null) {
      throw const FixtureException(
        FixtureLoader.manifestPath,
        'missing cards or finance mapping',
      );
    }
    final cardFixture = _Row(cardsPath, await loader.readObject(cardsPath));
    final finance = _Row(financePath, await loader.readObject(financePath));
    final accounts = fixtures.accounts.map((account) => account.id).toSet();
    final cards = <String, FleetCard>{};
    for (final row in cardFixture.rows('cards')) {
      final id = row.string('id');
      final accountId = row.string('accountId');
      final note = row.optionalString('note');
      final plan = row.string('plan');
      if (cards.containsKey(id) ||
          !accounts.contains(accountId) ||
          plan != 'monthly' ||
          (note != null && note.characters.length > 500)) {
        row.fail('invalid card ID, account, plan or note');
      }
      cards[id] = FleetCard(
        id: id,
        accountId: accountId,
        number: row.string('number'),
        plate: row.string('plate'),
        status: row.enumValue('status', CardStatus.values),
        product: row.enumValue('productId', FuelProduct.values),
        plan: plan,
        quotaLiters: row.nonNegativeInt('quotaLiters'),
        createdAt: row.instants('createdAt'),
        activatedAt: row.optionalInstant('activatedAt'),
        deliveredAt: row.optionalInstant('deliveredAt'),
        rfid: row.optionalString('rfid'),
        seedNote: note,
      );
    }

    if (finance.string('currency') != 'SYP' ||
        finance.nonNegativeInt('minorDigits') != 2) {
      finance.fail('expected SYP with two decimals');
    }
    final balances = <String, int>{};
    for (final row in finance.rows('balances')) {
      final id = row.string('cardId');
      if (!cards.containsKey(id) || balances.containsKey(id)) {
        row.fail('invalid or duplicate balance card');
      }
      balances[id] = row.value<int>('amountMinor');
    }
    if (balances.length != cards.length) finance.fail('missing card balance');

    final stations = <String, Map<String, String>>{};
    for (final row in finance.rows('stations')) {
      final id = row.string('id');
      final name = _Row(
        '${row.path}.name',
        row.value<Map<String, dynamic>>('name'),
      );
      if (stations.containsKey(id)) row.fail('duplicate station ID');
      stations[id] = Map.unmodifiable({
        'en': name.string('en'),
        'ar': name.string('ar'),
      });
    }

    final operationIds = <String>{};
    final operations = [
      for (final row in finance.rows('operations'))
        CardOperation(
          row.uniqueId(operationIds),
          row.cardId(cards),
          row.enumValue('type', OperationType.values),
          row.instants('at'),
          row.value<int>('amountMinor'),
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    final sales = <Sale>[];
    final saleIds = <String>{};
    for (final row in finance.rows('sales')) {
      final stationId = row.string('stationId');
      final quantity = row.value<num>('quantityLiters');
      final price = row.nonNegativeInt('unitPriceMinor');
      final total = row.nonNegativeInt('totalMinor');
      if (!stations.containsKey(stationId) ||
          !quantity.isFinite ||
          quantity <= 0 ||
          total != (quantity * price).round()) {
        row.fail('invalid sale station, quantity or total');
      }
      sales.add(
        Sale(
          id: row.uniqueId(saleIds),
          receipt: row.string('receipt'),
          cardId: row.cardId(cards),
          product: row.enumValue('productId', FuelProduct.values),
          stationId: stationId,
          at: row.instants('at'),
          quantity: quantity,
          unitPriceMinor: price,
          totalMinor: total,
        ),
      );
    }
    sales.sort((a, b) => b.at.compareTo(a.at));

    return FleetData(
      AccountFinance(
        cards: List.unmodifiable(cards.values),
        balances: Map.unmodifiable(balances),
        operations: List.unmodifiable(operations),
        sales: List.unmodifiable(sales),
        stations: Map.unmodifiable(stations),
        clockAnchor: finance.instants('clockAnchor'),
      ),
    );
  }
}

class _Row {
  const _Row(this.path, this._values);

  final String path;
  final Map<String, dynamic> _values;
  static final _utcTimestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$',
  );

  Never fail(String reason) => throw FixtureException(path, reason);

  T value<T>(String name) {
    final value = _values[name];
    if (value is T) return value;
    fail('invalid $name');
  }

  String string(String name) {
    final text = value<String>(name);
    if (text.trim().isEmpty) fail('empty $name');
    return text;
  }

  String? optionalString(String name) =>
      _values[name] == null ? null : string(name);

  int nonNegativeInt(String name) {
    final number = value<int>(name);
    if (number < 0) fail('negative $name');
    return number;
  }

  DateTime instants(String name) {
    final text = string(name);
    final parsed = DateTime.tryParse(text);
    if (parsed == null ||
        !_utcTimestamp.hasMatch(text) ||
        !parsed.toIso8601String().startsWith(text.substring(0, 19))) {
      fail('invalid UTC timestamp for $name');
    }
    return parsed;
  }

  DateTime? optionalInstant(String name) =>
      _values[name] == null ? null : instants(name);

  T enumValue<T extends Enum>(String name, List<T> values) {
    final key = string(name);
    return values.where((value) => value.name == key).firstOrNull ??
        fail('unknown $name');
  }

  Iterable<_Row> rows(String name) sync* {
    for (final (index, obj) in value<List<dynamic>>(name).indexed) {
      if (obj is! Map<String, dynamic>) fail('invalid $name[$index]');
      yield _Row('$path:$name[$index]', obj);
    }
  }

  String uniqueId(Set<String> ids) {
    final id = string('id');
    if (!ids.add(id)) fail('duplicate ID');
    return id;
  }

  String cardId(Map<String, FleetCard> cards) {
    final id = string('cardId');
    if (!cards.containsKey(id)) fail('unknown card');
    return id;
  }
}
