import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import '../finance/export_button.dart';
import '../finance/finance_labels.dart';
import '../finance/finance_scope.dart';
import '../finance/finance_tables.dart';
import '../finance/finance_widgets.dart';
import 'card_note_tile.dart';
import 'card_notes.dart';
import 'fleet_card.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String _query = '';
  CardStatus? _status;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final data = accountFinance(context);
    final notes = context.read<CardNotes>();
    final shown = data.cards
        .where((card) => card.matches(_query, _status))
        .toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('card-search'),
                  decoration: InputDecoration(
                    labelText: labels.searchCards,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              ExportButton(prepare: () => cardsTable(shown, data, notes)),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final status in [null, ...CardStatus.values])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        status == null ? labels.all : labels.cardStatus(status),
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? EmptyFinance(labels.noCards)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final card = shown[index];
                    return Card(
                      key: ValueKey(card.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardSummary(
                              card: card,
                              amount: data.balance(card.id),
                            ),
                            CardNoteTile(card: card),
                            Wrap(
                              spacing: 6,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () => context.push(
                                    PortalDestinations.card(card.id),
                                  ),
                                  child: Text(labels.cardDetails),
                                ),
                                TextButton(
                                  onPressed: () => context.push(
                                    PortalDestinations.operations(card.id),
                                  ),
                                  child: Text(labels.operationsLog),
                                ),
                              ],
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

class CardDetailsPage extends StatefulWidget {
  const CardDetailsPage({super.key, required this.id});

  final String id;

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  bool _operations = false;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final data = accountFinance(context);
    final card = data.cardById(widget.id);
    final operations = card == null ? const [] : data.operationLog(card.id);
    return Scaffold(
      appBar: AppBar(title: Text(labels.cardDetails)),
      body: SafeArea(
        child: card == null
            ? EmptyFinance(labels.missingCard)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _CardSummary(
                        card: card,
                        amount: data.balance(card.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(
                          labels.cardDetails,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          labels.financialOperations,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    selected: {_operations},
                    onSelectionChanged: (selected) =>
                        setState(() => _operations = selected.single),
                  ),
                  const SizedBox(height: 12),
                  if (_operations) ...[
                    if (operations.isEmpty) EmptyFinance(labels.noOperations),
                    for (final row in operations.take(4))
                      OperationTile(row: row),
                    OutlinedButton(
                      onPressed: () =>
                          context.push(PortalDestinations.operations(card.id)),
                      child: Text(labels.operationsLog),
                    ),
                  ] else ...[
                    CardNoteTile(card: card),
                    _Field(labels.fuel, labels.fuelProduct(card.product)),
                    _Field(labels.monthlyPlan, labels.volume(card.quotaLiters)),
                    _Field(labels.createdAt, labels.day(card.createdAt)),
                    if (card.activatedAt case final date?)
                      _Field(labels.activatedAt, labels.day(date)),
                    if (card.rfid case final rfid?)
                      _Field(labels.rfid, isolate(rfid)),
                    if (card.deliveredAt case final date?)
                      _Field(labels.deliveredAt, labels.day(date)),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary({required this.card, required this.amount});

  final FleetCard card;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final active = card.status == CardStatus.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(isolate(card.number), style: theme.textTheme.titleLarge),
            Chip(
              avatar: Icon(
                active
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                size: 18,
              ),
              label: Text(labels.cardStatus(card.status)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Text('${labels.plate} · ${isolate(card.plate)}'),
        const SizedBox(height: 8),
        Text(
          '${labels.fuelProduct(card.product)} · ${labels.volume(card.quotaLiters)}',
        ),
        Text(labels.amount(amount), style: theme.textTheme.titleMedium),
        if (card.activatedAt == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(labels.notActivated, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), trailing: Text(value));
}
