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
  support(PortalDestinations.support, Icons.support_agent_outlined),
  stations(PortalDestinations.stations, Icons.local_gas_station_outlined),
  more('/more', Icons.menu);

  const PortalTab(this.path, this.icon);

  final String path;
  final IconData icon;

  String title(AppLocalizations l10n) => switch (this) {
    PortalTab.home => l10n.home,
    PortalTab.cards => l10n.cards,
    PortalTab.support => l10n.assistantTab,
    PortalTab.stations => l10n.stations,
    PortalTab.more => l10n.more,
  };
}

class PortalShell extends StatefulWidget {
  const PortalShell({super.key, required this.navigation});

  final StatefulNavigationShell navigation;

  static void returnFromSupport(BuildContext context) {
    final shell = context.findAncestorStateOfType<_PortalShellState>();
    if (shell != null && shell._inSupport) {
      shell._selectTab(shell._returnTab);
    }
  }

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  int _returnTab = PortalTab.home.index;

  StatefulNavigationShell get navigation => widget.navigation;

  bool get _inSupport => navigation.currentIndex == PortalTab.support.index;

  void _selectTab(int index) {
    if (index == navigation.currentIndex) {
      if (!_inSupport) navigation.goBranch(index, initialLocation: true);
      return;
    }
    if (index == PortalTab.support.index) {
      _returnTab = navigation.currentIndex;
    }
    if (_inSupport) FocusManager.instance.primaryFocus?.unfocus();
    navigation.goBranch(index);
  }

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
                    : _inSupport
                    ? l10n.assistantTitle
                    : PortalTab.values[navigation.currentIndex].title(l10n),
                maxLines: _inSupport ? 2 : 1,
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
          onDestinationSelected: _selectTab,
          destinations: [
            for (final tab in PortalTab.values)
              NavigationDestination(
                icon: tab == PortalTab.support
                    ? const _SupportTabIcon(selected: false)
                    : Icon(tab.icon, color: portalMuted),
                selectedIcon: tab == PortalTab.support
                    ? const _SupportTabIcon(selected: true)
                    : Stack(
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
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
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

class _SupportTabIcon extends StatelessWidget {
  const _SupportTabIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -3),
    child: Material(
      color: selected ? portalGold : portalNavy,
      elevation: 3,
      shape: const CircleBorder(),
      child: SizedBox.square(
        dimension: 42,
        child: Icon(
          PortalTab.support.icon,
          color: selected ? portalInk : Colors.white,
        ),
      ),
    ),
  );
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
