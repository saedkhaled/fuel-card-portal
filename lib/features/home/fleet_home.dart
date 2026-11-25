import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import '../finance/finance_models.dart';
import '../finance/finance_scope.dart';
import '../finance/finance_widgets.dart';
import '../notifications/inbox_controller.dart';

class FleetHome extends StatelessWidget {
  const FleetHome({super.key});

  @override
  Widget build(BuildContext context) {
    final data = accountFinance(context);
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recent = data.recent;
    final counts = <OperationType, int>{};
    for (final operation in recent) {
      counts.update(operation.type, (count) => count + 1, ifAbsent: () => 1);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(labels.homeHeading, style: theme.textTheme.headlineSmall),
        ),
        BalanceHero(
          amountMinor: data.totalBalance,
          footer: Text('${labels.cardCount} · ${data.cards.length}'),
        ),
        const SizedBox(height: 18),
        Text(labels.last48Hours, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, count) in [
              (labels.refill, counts[OperationType.refill] ?? 0),
              (labels.deposit, counts[OperationType.deposit] ?? 0),
              (labels.withdraw, counts[OperationType.withdraw] ?? 0),
              (labels.unread, context.watch<InboxController>().unread),
            ])
              Chip(label: Text('$label · $count')),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, icon, route) in [
              (
                labels.cards,
                Icons.credit_card_outlined,
                PortalDestinations.cards,
              ),
              (
                labels.balances,
                Icons.account_balance_wallet_outlined,
                PortalDestinations.balances,
              ),
              (
                labels.priceBulletins,
                Icons.price_change_outlined,
                PortalDestinations.prices,
              ),
              (
                labels.sales,
                Icons.receipt_long_outlined,
                PortalDestinations.sales,
              ),
            ])
              FilledButton.tonalIcon(
                onPressed: () {
                  if (route == PortalDestinations.cards ||
                      route == PortalDestinations.balances) {
                    context.go(route);
                  } else {
                    context.push(route);
                  }
                },
                icon: Icon(icon),
                label: Text(label),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                labels.recentActivity,
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => context.push(PortalDestinations.notifications),
              child: Text(labels.viewAll),
            ),
          ],
        ),
        if (recent.isEmpty) EmptyFinance(labels.noOperations),
        for (final row in recent.take(4))
          OperationTile(
            row: row,
            cardNumber: data.cardById(row.cardId)?.number,
          ),
      ],
    );
  }
}
