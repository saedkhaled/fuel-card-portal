import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_shell.dart';
import '../../app/portal_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'support_catalog.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <({String question, SupportEntry? entry})>[];
  late Future<SupportCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = context.read<SupportRepository>().load();
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(SupportCatalog catalog, String text) {
    final question = text.trim();
    if (question.isEmpty) return;
    setState(() {
      _turns.add((question: question, entry: catalog.findAnswer(question)));
    });
    _composer.clear();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (MediaQuery.viewInsetsOf(context).bottom > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
      } else {
        PortalShell.returnFromSupport(context);
      }
    },
    child: _buildChat(context),
  );

  Widget _buildChat(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return FutureBuilder<SupportCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final catalog = snapshot.data;
        if (catalog == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labels.supportLoadFailed, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => setState(() {
                      _catalog = context.read<SupportRepository>().load();
                    }),
                    child: Text(labels.retry),
                  ),
                  const _FaqLink(),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: _turns.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [_welcome(catalog, labels)],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(16),
                      itemCount: _turns.length,
                      itemBuilder: (context, index) {
                        final turn = _turns[_turns.length - index - 1];
                        return _SupportTurn(
                          question: turn.question,
                          entry: turn.entry,
                        );
                      },
                    ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _composer,
                        builder: (context, value, _) => TextField(
                          controller: _composer,
                          textDirection: value.text.trim().isEmpty
                              ? null
                              : _textDirection(value.text),
                          decoration: InputDecoration(
                            labelText: labels.supportInputHint,
                            counterText: '',
                          ),
                          textInputAction: TextInputAction.send,
                          maxLength: 300,
                          onSubmitted: (text) => _send(catalog, text),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _composer,
                      builder: (context, value, _) => IconButton.filled(
                        tooltip: labels.supportSend,
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        onPressed: value.text.trim().isEmpty
                            ? null
                            : () => _send(catalog, value.text),
                        icon: const Icon(Icons.send_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _welcome(SupportCatalog catalog, AppLocalizations labels) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels.supportIntro),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in {
              ...catalog.entries
                  .where((entry) => entry.sourceUrl != null)
                  .take(2),
              ...catalog.entries,
            }.take(3))
              ActionChip(
                label: Text(entry.question, textDirection: TextDirection.rtl),
                onPressed: () => _send(catalog, entry.question),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SupportTurn extends StatelessWidget {
  const _SupportTurn({required this.question, required this.entry});

  final String question;
  final SupportEntry? entry;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final answer = entry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(question, textDirection: _textDirection(question)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: portalLine),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        answer?.answer ?? labels.supportNoAnswer,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  if (answer == null)
                    const _FaqLink()
                  else ...[
                    if (answer.sourceUrl case final sourceUrl?)
                      TextButton.icon(
                        onPressed: () => _openSource(context, sourceUrl),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(labels.supportOfficialSource),
                      )
                    else ...[
                      const SizedBox(height: 6),
                      Text(
                        labels.supportSampleSource,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: portalMuted,
                        ),
                      ),
                    ],
                    if (answer.route case final route?)
                      TextButton(
                        onPressed: () {
                          if (route == PortalDestinations.stations) {
                            context.go(route);
                          } else {
                            context.push(route);
                          }
                        },
                        child: Text(switch (route) {
                          PortalDestinations.balances => labels.balances,
                          PortalDestinations.topUp => labels.topUp,
                          PortalDestinations.stations => labels.stations,
                          PortalDestinations.subscriptions =>
                            labels.subscriptions,
                          PortalDestinations.prices => labels.priceBulletins,
                          _ => labels.supportFaq,
                        }),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openSource(BuildContext context, Uri url) async {
  try {
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
  } on Exception {
    // A device can have no enabled browser.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context)!.supportSourceUnavailable),
    ),
  );
}

class _FaqLink extends StatelessWidget {
  const _FaqLink();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => context.push(PortalDestinations.information),
    child: Text(AppLocalizations.of(context)!.supportFaq),
  );
}

TextDirection _textDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;
