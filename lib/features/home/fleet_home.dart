import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../account/account_scope.dart';
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
    final profile = accountProfile(context);
    final recent = data.recent;
    final counts = <OperationType, int>{};
    for (final operation in recent) {
      counts.update(operation.type, (count) => count + 1, ifAbsent: () => 1);
    }
    final unread = context.watch<InboxController>().unread;
    final shortcuts = [
      (labels.cards, Icons.credit_card_outlined, PortalDestinations.cards),
      (
        labels.balances,
        Icons.account_balance_wallet_outlined,
        PortalDestinations.balances,
      ),
      (labels.stations, Icons.place_outlined, PortalDestinations.stations),
    ];
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(labels.homeHeading, style: theme.textTheme.labelLarge),
        if (profile != null) ...[
          const SizedBox(height: 3),
          Text(
            profile.company.inLanguage(labels.localeName),
            style: theme.textTheme.headlineSmall,
          ),
        ],
        const SizedBox(height: 12),
        BalanceHero(
          amountMinor: data.totalBalance,
          footer: Text('${labels.cardCount} · ${data.cards.length}'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.textScalerOf(context).scale(14) > 21
                ? 2
                : 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, icon, route) in shortcuts)
                  SizedBox(
                    width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: portalNavy,
                        minimumSize: const Size(48, 70),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        if (route == PortalDestinations.balances) {
                          context.push(route);
                        } else {
                          context.go(route);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 22),
                          const SizedBox(height: 5),
                          Text(label, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
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
        const SizedBox(height: 10),
        Text(labels.last48Hours, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (label, count) in [
              (labels.refill, counts[OperationType.refill] ?? 0),
              (labels.deposit, counts[OperationType.deposit] ?? 0),
              (labels.withdraw, counts[OperationType.withdraw] ?? 0),
              (labels.unread, unread),
            ])
              Text(
                '$label · $count',
                style: theme.textTheme.bodySmall!.copyWith(color: portalMuted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(PortalDestinations.sales),
                child: Text(labels.sales, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(PortalDestinations.prices),
                child: Text(labels.priceBulletins, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
    if (MediaQuery.disableAnimationsOf(context)) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .8, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
      child: content,
    );
  }
}
