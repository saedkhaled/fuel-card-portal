import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/account/account_pages.dart';
import '../features/notifications/inbox_controller.dart';
import '../features/home/fleet_home.dart';
import '../l10n/generated/app_localizations.dart';
import 'portal_destinations.dart';
import 'portal_surfaces.dart';
import 'portal_theme.dart';

enum PortalTab {
  home('/home', Icons.dashboard_outlined),
  cards(PortalDestinations.cards, Icons.credit_card_outlined),
  balances(PortalDestinations.balances, Icons.account_balance_wallet_outlined),
  stations(PortalDestinations.stations, Icons.local_gas_station_outlined),
  more('/more', Icons.menu);

  const PortalTab(this.path, this.icon);

  final String path;
  final IconData icon;

  String title(AppLocalizations l10n) => switch (this) {
    PortalTab.home => l10n.home,
    PortalTab.cards => l10n.cards,
    PortalTab.balances => l10n.balances,
    PortalTab.stations => l10n.stations,
    PortalTab.more => l10n.more,
  };
}

class PortalShell extends StatelessWidget {
  const PortalShell({super.key, required this.navigation});

  final StatefulNavigationShell navigation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const PortalMark(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                navigation.currentIndex == PortalTab.home.index
                    ? (PortalMark.hasBrandArtwork
                          ? l10n.portalBrand
                          : l10n.appTitle)
                    : PortalTab.values[navigation.currentIndex].title(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.push(PortalDestinations.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(top: false, child: navigation),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: portalLine)),
        ),
        child: NavigationBar(
          height:
              68 +
              (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(
                    0.0,
                    28.0,
                  ) *
                  2,
          selectedIndex: navigation.currentIndex,
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 140),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => navigation.goBranch(
            index,
            initialLocation: index == navigation.currentIndex,
          ),
          destinations: [
            for (final tab in PortalTab.values)
              NavigationDestination(
                icon: Icon(tab.icon, color: portalMuted),
                selectedIcon: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(tab.icon, color: portalNavy),
                    const Positioned(
                      top: -9,
                      child: SizedBox(
                        width: 25,
                        height: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: portalGold,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                label: tab.title(l10n),
              ),
          ],
        ),
      ),
    );
  }
}

class FoundationHome extends StatefulWidget {
  const FoundationHome({super.key});

  @override
  State<FoundationHome> createState() => _FoundationHomeState();
}

class _FoundationHomeState extends State<FoundationHome> {
  bool _promptScheduled = false;

  Future<void> _showAlertPrompt(InboxController inbox) async {
    if (!mounted || !inbox.needsPrompt) return;
    try {
      final l10n = AppLocalizations.of(context)!;
      final enabled = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.notifications_outlined),
          title: Text(l10n.alertHeading),
          content: Text(l10n.alertHelp),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.enableAlerts),
            ),
          ],
        ),
      );
      if (mounted) await inbox.setAlerts(enabled ?? false);
    } catch (_) {
      if (mounted) {
        accountMessage(context, AppLocalizations.of(context)!.operationFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InboxController>();
    if (inbox.needsPrompt && !_promptScheduled) {
      _promptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showAlertPrompt(inbox),
      );
    }
    return const FleetHome();
  }
}
