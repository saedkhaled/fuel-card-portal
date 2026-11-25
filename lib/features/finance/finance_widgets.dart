import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'finance_labels.dart';
import 'finance_models.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.amountMinor, this.footer});

  final int amountMinor;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.totalBalance, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              labels.amount(amountMinor),
              style: theme.textTheme.headlineMedium,
            ),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}

class OperationTile extends StatelessWidget {
  const OperationTile({super.key, required this.row, this.cardNumber});
  final CardOperation row;
  final String? cardNumber;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      leading: Icon(row.amountMinor >= 0 ? Icons.south_west : Icons.north_east),
      title: Text(labels.operationLabel(row.type)),
      subtitle: Text(
        cardNumber == null
            ? labels.timestamp(row.at)
            : '${isolate(cardNumber!)} · ${labels.timestamp(row.at)}',
      ),
      trailing: Text(labels.amount(row.amountMinor, signed: true)),
    );
  }
}

class EmptyFinance extends StatelessWidget {
  const EmptyFinance(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
