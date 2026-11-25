import '../cards/fleet_card.dart';

enum OperationType {
  refill,
  withdraw,
  subscription,
  forfeiture,
  deposit,
  initial,
}

class CardOperation {
  const CardOperation(
    this.id,
    this.cardId,
    this.type,
    this.at,
    this.amountMinor,
  );

  final String id;
  final String cardId;
  final OperationType type;
  final DateTime at;
  final int amountMinor;
}

class Sale {
  const Sale({
    required this.id,
    required this.receipt,
    required this.cardId,
    required this.product,
    required this.stationId,
    required this.at,
    required this.quantity,
    required this.unitPriceMinor,
    required this.totalMinor,
  });

  final String id;
  final String receipt;
  final String cardId;
  final FuelProduct product;
  final String stationId;
  final DateTime at;
  final num quantity;
  final int unitPriceMinor;
  final int totalMinor;
}

/// The demo renders and filters dates in UTC. Both endpoints are inclusive.
class FinanceFilter {
  const FinanceFilter({
    this.cardId,
    this.operation,
    this.product,
    this.from,
    this.to,
  });

  final String? cardId;
  final OperationType? operation;
  final FuelProduct? product;
  final DateTime? from;
  final DateTime? to;

  static DateTime _day(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  bool get isValid =>
      from == null || to == null || !_day(from!).isAfter(_day(to!));

  bool includes(DateTime utc) =>
      isValid &&
      (from == null || !utc.isBefore(_day(from!))) &&
      (to == null || utc.isBefore(_day(to!).add(const Duration(days: 1))));
}

class AccountFinance {
  const AccountFinance({
    required this.cards,
    required this.balances,
    required this.operations,
    required this.sales,
    required this.stations,
    required this.clockAnchor,
  });

  final List<FleetCard> cards;
  final Map<String, int> balances;
  final List<CardOperation> operations;
  final List<Sale> sales;
  final Map<String, Map<String, String>> stations;
  final DateTime clockAnchor;

  FleetCard? cardById(String id) =>
      cards.where((card) => card.id == id).firstOrNull;
  int balance(String id) => balances[id] ?? 0;
  int get totalBalance => cards.fold(0, (sum, card) => sum + balance(card.id));

  List<CardOperation> operationLog(
    String cardId, [
    FinanceFilter filter = const FinanceFilter(),
  ]) => operations
      .where(
        (row) =>
            row.cardId == cardId &&
            (filter.operation == null || row.type == filter.operation) &&
            filter.includes(row.at),
      )
      .toList(growable: false);

  List<Sale> filteredSales(FinanceFilter filter) => sales
      .where(
        (row) =>
            (filter.cardId == null || row.cardId == filter.cardId) &&
            (filter.product == null || row.product == filter.product) &&
            filter.includes(row.at),
      )
      .toList(growable: false);

  List<CardOperation> get recent {
    final cutoff = clockAnchor.subtract(const Duration(hours: 48));
    return operations
        .where(
          (row) => !row.at.isBefore(cutoff) && !row.at.isAfter(clockAnchor),
        )
        .toList(growable: false);
  }
}
