import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import 'export_button.dart';
import 'finance_filter_sheet.dart';
import 'finance_labels.dart';
import 'finance_models.dart';
import 'finance_scope.dart';
import 'finance_tables.dart';
import 'finance_widgets.dart';

class BalancesPage extends StatelessWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final finance = accountFinance(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
          child: Row(
            children: [
              Expanded(child: BalanceHero(amountMinor: finance.totalBalance)),
              ExportButton(prepare: () async => balancesTable(finance)),
            ],
          ),
        ),
        Expanded(
          child: finance.cards.isEmpty
              ? EmptyFinance(labels.noCards)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: finance.cards.length,
                  itemBuilder: (context, index) {
                    final card = finance.cards[index];
                    final last = finance.operationLog(card.id).firstOrNull;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isolate(card.number),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('${labels.plate} · ${isolate(card.plate)}'),
                            Text(
                              labels.amount(finance.balance(card.id)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              last == null
                                  ? labels.noLastOperation
                                  : '${labels.lastOperation} · ${labels.timestamp(last.at)}',
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                PortalDestinations.operations(card.id),
                              ),
                              child: Text(labels.operationsLog),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key, required this.cardId});
  final String cardId;

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  FinanceFilter _filter = const FinanceFilter();

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final finance = accountFinance(context);
    final card = finance.cardById(widget.cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: Text(labels.operationsLog)),
        body: EmptyFinance(labels.missingCard),
      );
    }
    final rows = finance.operationLog(card.id, _filter);
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.operationsLog),
        actions: [
          ExportButton(
            prepare: () async => operationsTable(card, rows),
            share: true,
          ),
          ExportButton(prepare: () async => operationsTable(card, rows)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterBar(
              label: isolate(card.number),
              active:
                  _filter.operation != null ||
                  _filter.from != null ||
                  _filter.to != null,
              onPressed: () async {
                final result = await editFinanceFilter(
                  context,
                  current: _filter,
                  anchor: finance.clockAnchor,
                );
                if (result != null && mounted) setState(() => _filter = result);
              },
            ),
            Expanded(
              child: rows.isEmpty
                  ? EmptyFinance(labels.noOperations)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) =>
                          OperationTile(row: rows[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  FinanceFilter _filter = const FinanceFilter();

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final finance = accountFinance(context);
    final rows = finance.filteredSales(_filter);
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.sales),
        actions: [
          ExportButton(
            prepare: () async => salesTable(finance, rows),
            share: true,
          ),
          ExportButton(prepare: () async => salesTable(finance, rows)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterBar(
              label: _filter.cardId == null
                  ? labels.allCards
                  : isolate(finance.cardById(_filter.cardId!)?.number ?? ''),
              active:
                  _filter.product != null ||
                  _filter.cardId != null ||
                  _filter.from != null ||
                  _filter.to != null,
              onPressed: () async {
                final result = await editFinanceFilter(
                  context,
                  current: _filter,
                  anchor: finance.clockAnchor,
                  cards: finance.cards,
                );
                if (result != null && mounted) setState(() => _filter = result);
              },
            ),
            Expanded(
              child: rows.isEmpty
                  ? EmptyFinance(labels.noSales)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rows.length,
                      itemBuilder: (context, index) =>
                          _SaleCard(row: rows[index], finance: finance),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (active)
            FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: const Icon(Icons.filter_alt),
              label: Text(labels.filter),
            )
          else
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(labels.filter),
            ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.row, required this.finance});
  final Sale row;
  final AccountFinance finance;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final station = finance.stations[row.stationId]![labels.localeName]!;
    final number = finance.cardById(row.cardId)!.number;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${labels.receipt} · ${isolate(row.receipt)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('${isolate(number)} · ${labels.fuelProduct(row.product)}'),
            Text('${labels.station} · $station'),
            Text(labels.timestamp(row.at)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _Measure(labels.quantity, labels.volume(row.quantity)),
                _Measure(labels.unitPrice, labels.amount(row.unitPriceMinor)),
                _Measure(labels.saleTotal, labels.amount(row.totalMinor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}
