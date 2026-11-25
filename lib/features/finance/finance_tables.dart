import '../cards/card_notes.dart';
import '../cards/fleet_card.dart';
import 'finance_export.dart';
import 'finance_models.dart';

Future<FinanceExport> cardsTable(
  List<FleetCard> cards,
  AccountFinance finance,
  CardNotes notes,
) async => FinanceExport(
  'cards',
  const [
    'card_id',
    'card_number',
    'plate',
    'status',
    'product',
    'plan',
    'quota_liters',
    'balance_syp',
    'note',
  ],
  [
    for (final card in cards)
      [
        card.id,
        card.number,
        card.plate,
        card.status.name,
        card.product.name,
        card.plan,
        card.quotaLiters,
        finance.balance(card.id) / 100,
        await notes.read(card),
      ],
  ],
);

FinanceExport balancesTable(AccountFinance finance) => FinanceExport(
  'balances',
  const [
    'card_id',
    'card_number',
    'plate',
    'balance_syp',
    'last_operation_utc',
  ],
  finance.cards.map(
    (card) => [
      card.id,
      card.number,
      card.plate,
      finance.balance(card.id) / 100,
      finance.operationLog(card.id).firstOrNull?.at.toIso8601String(),
    ],
  ),
);

FinanceExport operationsTable(FleetCard card, List<CardOperation> rows) =>
    FinanceExport(
      'operations-${card.number}',
      const [
        'operation_id',
        'card_number',
        'type',
        'timestamp_utc',
        'amount_syp',
      ],
      rows.map(
        (row) => [
          row.id,
          card.number,
          row.type.name,
          row.at.toIso8601String(),
          row.amountMinor / 100,
        ],
      ),
    );

FinanceExport salesTable(AccountFinance finance, List<Sale> rows) =>
    FinanceExport(
      'sales',
      const [
        'receipt',
        'card_number',
        'product',
        'station_id',
        'timestamp_utc',
        'quantity_liters',
        'unit_price_syp',
        'total_syp',
      ],
      rows.map(
        (row) => [
          row.receipt,
          finance.cardById(row.cardId)?.number,
          row.product.name,
          row.stationId,
          row.at.toIso8601String(),
          row.quantity,
          row.unitPriceMinor / 100,
          row.totalMinor / 100,
        ],
      ),
    );
