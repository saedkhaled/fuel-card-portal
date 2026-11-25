import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import '../finance/finance_labels.dart';
import '../stations/network_content.dart';
import '../stations/station_network.dart';

class PriceBulletinsPage extends StatelessWidget {
  const PriceBulletinsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(labels.priceBulletins)),
      body: SafeArea(
        child: NetworkContent(
          builder: (context, network) {
            final current = network.current;
            if (current == null) return Center(child: Text(labels.noBulletins));
            final history = network.history;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels.currentBulletin,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${labels.effectiveDate} · ${labels.day(current.effectiveOn)}',
                        ),
                        const SizedBox(height: 12),
                        _Prices(network: network, bulletin: current),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => context.push(
                            PortalDestinations.bulletin(current.id),
                          ),
                          child: Text(labels.viewBulletin),
                        ),
                      ],
                    ),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      labels.previousBulletins,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  for (final item in history)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(labels.day(item.effectiveOn)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () =>
                            context.push(PortalDestinations.bulletin(item.id)),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class PriceBulletinDetailsPage extends StatelessWidget {
  const PriceBulletinDetailsPage({super.key, required this.bulletinId});

  final String bulletinId;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(labels.bulletinDetails)),
      body: SafeArea(
        child: NetworkContent(
          builder: (context, network) {
            final bulletin = network.bulletins[bulletinId];
            if (bulletin == null) {
              return Center(child: Text(labels.missingBulletin));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  bulletin.id == network.currentBulletinId
                      ? labels.currentBulletin
                      : labels.previousBulletin,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  '${labels.effectiveDate} · ${labels.day(bulletin.effectiveOn)}',
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _Prices(network: network, bulletin: bulletin),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Prices extends StatelessWidget {
  const _Prices({required this.network, required this.bulletin});

  final StationNetwork network;
  final PriceBulletin bulletin;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels.fuelPrices, style: Theme.of(context).textTheme.titleMedium),
        for (final item in bulletin.prices.entries)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              network.products[item.key]!.inLanguage(labels.localeName),
            ),
            trailing: Text(labels.amount(item.value)),
          ),
      ],
    );
  }
}
