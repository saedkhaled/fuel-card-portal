import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/portal_destinations.dart';
import '../../l10n/generated/app_localizations.dart';
import '../account/account_data.dart';
import '../account/account_pages.dart';
import '../finance/finance_labels.dart';
import 'inbox_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _open(
    BuildContext context,
    InboxController inbox,
    InboxItem item,
  ) async {
    final labels = AppLocalizations.of(context)!;
    try {
      if (!inbox.isRead(item)) await inbox.markRead(item.id);
      if (!context.mounted) return;
      if (item.stationId case final id?) {
        context.push(PortalDestinations.station(id));
      } else if (item.bulletinId case final id?) {
        context.push(PortalDestinations.bulletin(id));
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item.title.inLanguage(labels.localeName)),
            content: Text(item.body.inLanguage(labels.localeName)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) accountMessage(context, labels.operationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final inbox = context.watch<InboxController>();
    final items = inbox.items;
    return Scaffold(
      appBar: AppBar(title: Text(labels.notifications)),
      body: SafeArea(
        child: !inbox.ready
            ? _InboxLoading(inbox: inbox)
            : items.isEmpty
            ? Center(child: Text(labels.noNotifications))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final read = inbox.isRead(item);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      read
                          ? Icons.notifications_none
                          : Icons.mark_email_unread_outlined,
                    ),
                    title: Text(
                      item.title.inLanguage(labels.localeName),
                      style: read
                          ? null
                          : const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item.body.inLanguage(labels.localeName)}\n${labels.timestamp(item.at)}',
                    ),
                    trailing: read
                        ? null
                        : IconButton(
                            tooltip: labels.markRead,
                            onPressed: inbox.saving
                                ? null
                                : () async {
                                    try {
                                      await inbox.markRead(item.id);
                                    } catch (_) {
                                      if (context.mounted) {
                                        accountMessage(
                                          context,
                                          labels.operationFailed,
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.done),
                          ),
                    enabled: !inbox.saving,
                    onTap: () => _open(context, inbox, item),
                  );
                },
              ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final inbox = context.watch<InboxController>();
    return Scaffold(
      appBar: AppBar(title: Text(labels.notificationSettings)),
      body: SafeArea(
        child: !inbox.ready
            ? _InboxLoading(inbox: inbox)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: Text(labels.stationAlerts),
                    subtitle: Text(labels.stationAlertsHelp),
                    value: inbox.alerts,
                    onChanged: inbox.saving
                        ? null
                        : (enabled) async {
                            try {
                              await inbox.setAlerts(enabled);
                            } catch (_) {
                              if (context.mounted) {
                                accountMessage(context, labels.operationFailed);
                              }
                            }
                          },
                  ),
                ],
              ),
      ),
    );
  }
}

class _InboxLoading extends StatelessWidget {
  const _InboxLoading({required this.inbox});
  final InboxController inbox;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Center(
      child: inbox.failed
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labels.inboxLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: inbox.retry,
                    child: Text(labels.retry),
                  ),
                ],
              ),
            )
          : const CircularProgressIndicator(),
    );
  }
}
