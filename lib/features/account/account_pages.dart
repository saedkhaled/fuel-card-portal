import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/android_file_actions.dart';
import '../../app/language_picker.dart';
import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/session_controller.dart';
import '../finance/finance_labels.dart';
import '../finance/finance_scope.dart';
import 'account_data.dart';
import 'account_scope.dart';

void accountMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

Future<void> copyAccountText(BuildContext context, String text) async {
  final labels = AppLocalizations.of(context)!;
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) accountMessage(context, labels.copied);
  } catch (_) {
    if (context.mounted) accountMessage(context, labels.operationFailed);
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final labels = AppLocalizations.of(context)!;
    final session = context.read<SessionController>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels.logoutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(labels.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(labels.logout),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    await session.logout();
    if (context.mounted && session.issue != null) {
      accountMessage(context, labels.operationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = accountProfile(context);
    if (profile == null) return const SizedBox.shrink();
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = context.watch<SessionController>();
    final cardCount = accountFinance(context).cards.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business_outlined),
                const SizedBox(height: 8),
                Text(
                  profile.company.inLanguage(labels.localeName),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${labels.city} · ${profile.city.inLanguage(labels.localeName)}',
                ),
                Text(
                  '${labels.registration} · ${isolate(profile.registration)}',
                ),
                Text('${labels.cardCount} · $cardCount'),
                Text(
                  '${labels.contact} · ${profile.contact.name.inLanguage(labels.localeName)}',
                ),
                Text(isolate(profile.contact.phone)),
                Text(isolate(profile.contact.email)),
              ],
            ),
          ),
        ),
        _SectionTitle(labels.services),
        for (final (title, icon, path) in [
          (
            labels.subscriptions,
            Icons.receipt_outlined,
            PortalDestinations.subscriptions,
          ),
          (
            labels.topUp,
            Icons.account_balance_wallet_outlined,
            PortalDestinations.topUp,
          ),
          (
            labels.importantInformation,
            Icons.info_outline,
            PortalDestinations.information,
          ),
          (
            labels.notificationSettings,
            Icons.notifications_active_outlined,
            PortalDestinations.notificationSettings,
          ),
          (labels.sales, Icons.receipt_long_outlined, PortalDestinations.sales),
          (
            labels.priceBulletins,
            Icons.price_change_outlined,
            PortalDestinations.prices,
          ),
          (
            labels.notifications,
            Icons.notifications_outlined,
            PortalDestinations.notifications,
          ),
        ])
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(path),
          ),
        _SectionTitle(labels.settings),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(labels.language),
          onTap: () => choosePortalLanguage(context),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(labels.about),
          onTap: () => context.push(PortalDestinations.about),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(labels.logout),
          enabled: !session.busy,
          onTap: () => _signOut(context),
        ),
      ],
    );
  }
}

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final profile = accountProfile(context);
    final finance = accountFinance(context);
    return Scaffold(
      appBar: AppBar(title: Text(labels.subscriptions)),
      body: SafeArea(
        child: profile == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labels.monthlyCharge),
                          Text(
                            labels.amount(profile.monthlyAmountMinor),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${labels.nextCharge} · ${labels.day(profile.nextChargeOn)}',
                          ),
                          const SizedBox(height: 8),
                          Text(labels.subscriptionHelp),
                        ],
                      ),
                    ),
                  ),
                  if (finance.cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(labels.noCards),
                    ),
                  for (final card in finance.cards)
                    Card(
                      child: ListTile(
                        title: Text(isolate(card.number)),
                        subtitle: _SubscriptionStatus(
                          subscription: profile.subscriptions[card.id]!,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () =>
                            context.push(PortalDestinations.invoices(card.id)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SubscriptionStatus extends StatelessWidget {
  const _SubscriptionStatus({required this.subscription});
  final CardSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final last = subscription.lastPayment;
    return Text(
      [
        subscription.exempt ? labels.exempt : labels.billed,
        if (!subscription.exempt)
          last == null
              ? labels.noPayments
              : '${labels.lastPayment} · ${labels.day(last.issuedOn)} · ${labels.amount(last.amountMinor)}',
      ].join('\n'),
    );
  }
}

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key, required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final profile = accountProfile(context);
    final card = accountFinance(context).cardById(cardId);
    final subscription = profile?.subscriptions[cardId];
    return Scaffold(
      appBar: AppBar(title: Text(labels.invoiceHistory)),
      body: SafeArea(
        child: card == null || subscription == null
            ? Center(child: Text(labels.missingCard))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    title: Text(isolate(card.number)),
                    subtitle: _SubscriptionStatus(subscription: subscription),
                  ),
                  if (subscription.invoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(labels.noInvoices),
                    ),
                  for (final invoice in subscription.invoices)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isolate(invoice.id),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(labels.day(invoice.issuedOn)),
                            Chip(
                              label: Text(
                                invoice.paid ? labels.paid : labels.unpaid,
                              ),
                            ),
                            Text(
                              labels.amount(invoice.amountMinor),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${labels.paymentMethod} · ${invoice.paid ? labels.fleetBalance : labels.pendingPayment}',
                            ),
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

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final profile = accountProfile(context);
    return Scaffold(
      appBar: AppBar(title: Text(labels.importantInformation)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in profile?.faq ?? const <AccountFaq>[])
              Card(
                child: ExpansionTile(
                  title: Text(item.question.inLanguage(labels.localeName)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(item.answer.inLanguage(labels.localeName)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<String?> _version = const AndroidFileActions().appVersion();

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final contact = accountProfile(context)?.contact;
    return Scaffold(
      appBar: AppBar(title: Text(labels.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(labels.appTitle),
            Text(labels.aboutDescription),
            FutureBuilder(
              future: _version,
              builder: (context, snapshot) => ListTile(
                title: Text(labels.appVersion),
                subtitle: Text(
                  snapshot.data ??
                      (snapshot.hasError ? labels.operationFailed : '—'),
                ),
              ),
            ),
            if (contact != null)
              ListTile(
                title: Text(labels.support),
                subtitle: Text(contact.name.inLanguage(labels.localeName)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(labels.supportPreview),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isolate(contact.phone)),
                        Text(isolate(contact.email)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
  );
}
