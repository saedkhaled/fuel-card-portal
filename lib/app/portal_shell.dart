import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/session_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'language_picker.dart';
import 'portal_settings.dart';
import 'portal_destinations.dart';

enum PortalTab {
  home('/home', Icons.dashboard_outlined),
  cards(PortalDestinations.cards, Icons.credit_card_outlined),
  balances(PortalDestinations.balances, Icons.account_balance_wallet_outlined),
  stations('/stations', Icons.local_gas_station_outlined),
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
        title: Text(PortalTab.values[navigation.currentIndex].title(l10n)),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.push(PortalDestinations.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(top: false, child: navigation),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) => navigation.goBranch(
          index,
          initialLocation: index == navigation.currentIndex,
        ),
        destinations: [
          for (final tab in PortalTab.values)
            NavigationDestination(icon: Icon(tab.icon), label: tab.title(l10n)),
        ],
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showAlertPrompt();
    });
  }

  Future<void> _showAlertPrompt() async {
    final settings = context.read<PortalSettings>();
    final id = context.read<SessionController>().accountId;
    if (id == null) return;
    try {
      final needsPrompt = await settings.needsAlertPrompt(id);
      if (!mounted || !needsPrompt) return;
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
      if (enabled != null) {
        await settings.recordAlertChoice(id, enabled: enabled);
      }
    } catch (_) {
      if (mounted) showOperationError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          labels.homeHeading,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(labels.sessionActive),
      ],
    );
  }
}

class FoundationMore extends StatelessWidget {
  const FoundationMore({super.key});

  Future<void> _signOut(BuildContext context) async {
    final session = context.read<SessionController>();
    final l10n = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    await session.logout();
    if (context.mounted && session.issue != null) showOperationError(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.watch<SessionController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          onTap: () => choosePortalLanguage(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.logout),
          enabled: !session.busy,
          onTap: () => _signOut(context),
        ),
      ],
    );
  }
}

class PendingTab extends StatelessWidget {
  const PendingTab({super.key, required this.tab});

  final PortalTab tab;

  @override
  Widget build(BuildContext context) => Center(
    child: ListTile(
      leading: Icon(tab.icon),
      title: Text(AppLocalizations.of(context)!.sectionPending),
    ),
  );
}

void showOperationError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.operationFailed)),
  );
}
