import 'package:flutter/material.dart';

import '../../app/portal_surfaces.dart';
import '../../app/portal_theme.dart';
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
    return PortalHeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.totalBalance,
            style: theme.textTheme.labelLarge!.copyWith(color: portalGold),
          ),
          const SizedBox(height: 12),
          Text(
            labels.amount(amountMinor),
            style: theme.textTheme.headlineMedium!.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
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
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              row.amountMinor >= 0 ? Icons.call_received : Icons.call_made,
              color: portalNavy,
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labels.operationLabel(row.type), style: text.titleSmall),
                  Text(
                    cardNumber == null
                        ? labels.timestamp(row.at)
                        : '${isolate(cardNumber!)} · ${labels.timestamp(row.at)}',
                    style: text.bodySmall!.copyWith(color: portalMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Semantics(
                label: labels.amount(row.amountMinor, signed: true),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels.amountValue(row.amountMinor, signed: true),
                        textDirection: TextDirection.ltr,
                        style: text.titleSmall!.copyWith(
                          color: row.amountMinor > 0
                              ? const Color(0xff176344)
                              : portalInk,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text('SYP', style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
