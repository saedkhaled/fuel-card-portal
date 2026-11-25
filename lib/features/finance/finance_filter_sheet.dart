import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cards/fleet_card.dart';
import 'finance_labels.dart';
import 'finance_models.dart';

Future<FinanceFilter?> editFinanceFilter(
  BuildContext context, {
  required FinanceFilter current,
  required DateTime anchor,
  List<FleetCard>? cards,
}) => showModalBottomSheet<FinanceFilter>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _FilterSheet(current: current, anchor: anchor, cards: cards),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.anchor, this.cards});

  final FinanceFilter current;
  final DateTime anchor;
  final List<FleetCard>? cards;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _card = widget.current.cardId;
  late FuelProduct? _product = widget.current.product;
  late OperationType? _operation = widget.current.operation;
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;

  FinanceFilter get _value => FinanceFilter(
    cardId: _card,
    product: _product,
    operation: _operation,
    from: _from,
    to: _to,
  );

  Future<void> _editDate({required bool start}) async {
    final anchor = widget.anchor;
    final selected = await showDatePicker(
      context: context,
      initialDate:
          (start ? _from : _to) ??
          DateTime(anchor.year, anchor.month, anchor.day),
      currentDate: DateTime(anchor.year, anchor.month, anchor.day),
      firstDate: DateTime(anchor.year - 50),
      lastDate: DateTime(anchor.year + 50, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _from = selected;
      } else {
        _to = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels.filter, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (widget.cards case final cards?) ...[
              InputDecorator(
                decoration: InputDecoration(labelText: labels.cardNumber),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _card ?? '',
                    items: [
                      DropdownMenuItem(value: '', child: Text(labels.allCards)),
                      for (final card in cards)
                        DropdownMenuItem(
                          value: card.id,
                          child: Text(isolate(card.number)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _card = value == '' ? null : value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(labels.product),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in [null, ...FuelProduct.values])
                    ChoiceChip(
                      label: Text(
                        value == null ? labels.all : labels.fuelProduct(value),
                      ),
                      selected: value == _product,
                      onSelected: (_) => setState(() => _product = value),
                    ),
                ],
              ),
            ] else ...[
              Text(labels.operationType),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in [null, ...OperationType.values])
                    ChoiceChip(
                      label: Text(
                        value == null
                            ? labels.all
                            : labels.operationLabel(value),
                      ),
                      selected: value == _operation,
                      onSelected: (_) => setState(() => _operation = value),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            for (final (label, date, start) in [
              (labels.fromDate, _from, true),
              (labels.toDate, _to, false),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(label),
                subtitle: date == null
                    ? null
                    : Text(
                        labels.day(
                          DateTime.utc(date.year, date.month, date.day),
                        ),
                      ),
                onTap: () => _editDate(start: start),
              ),
            if (!_value.isValid)
              Text(
                labels.invalidDates,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _card = null;
                    _product = null;
                    _operation = null;
                    _from = null;
                    _to = null;
                  }),
                  child: Text(labels.clearFilters),
                ),
                FilledButton(
                  onPressed: _value.isValid
                      ? () => Navigator.pop(context, _value)
                      : null,
                  child: Text(labels.applyFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
