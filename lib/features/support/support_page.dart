import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:provider/provider.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_shell.dart';
import '../../app/portal_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'support_catalog.dart';
import 'support_gemini.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _turns =
      <
        ({
          String question,
          SupportEntry? entry,
          SupportGeneratedReply? generated,
        })
      >[];
  late Future<SupportCatalog> _catalog;
  bool _searching = false;

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

  Future<void> _send(SupportCatalog catalog, String text) async {
    final question = text.trim();
    if (question.isEmpty || _searching) return;
    final previous = _turns.lastOrNull?.entry;
    final gemini = context.read<SupportGemini?>();
    setState(() {
      _searching = true;
      _turns.add((question: question, entry: null, generated: null));
    });
    _composer.clear();
    if (_scroll.hasClients) _scroll.jumpTo(0);

    // Keep the search state visible even when the bundled index is fast.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final generated = await gemini?.answer(
      catalog,
      question,
      previous: previous,
    );
    if (!mounted) return;
    final entry = generated == null
        ? catalog.findAnswer(question, previous: previous)
        : generated.source;
    setState(() {
      _turns[_turns.length - 1] = (
        question: question,
        entry: entry,
        generated: generated,
      );
      _searching = false;
    });
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
                          generated: turn.generated,
                          searching: _searching && index == 0,
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
                        onPressed: _searching || value.text.trim().isEmpty
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
                  .where(
                    (entry) => entry.sourceUrl != null && entry.example != null,
                  )
                  .take(2),
              ...catalog.entries,
            }.where((entry) => entry.example != null).take(3))
              ActionChip(
                label: Text(entry.example!, textDirection: TextDirection.rtl),
                onPressed: () => _send(catalog, entry.example!),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SupportTurn extends StatelessWidget {
  const _SupportTurn({
    required this.question,
    required this.entry,
    required this.generated,
    required this.searching,
  });

  final String question;
  final SupportEntry? entry;
  final SupportGeneratedReply? generated;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final answer = entry;
    final reply = generated;
    final response = answer?.id == SupportCatalog.assistantIdentityId
        ? labels.assistantIntroduction
        : switch (reply) {
            null => answer?.passage ?? labels.supportNoAnswer,
            (outOfScope: true, text: _, source: _) =>
              labels.supportGeminiOutOfScope,
            _ => reply.text ?? labels.supportGeminiNoAnswer,
          };
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
            child: searching
                ? const _SearchingReply()
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              response,
                              textDirection: _textDirection(response),
                            ),
                          ),
                        ),
                        if (answer == null && reply?.text == null)
                          const _FaqLink()
                        else if (answer?.route case final route?
                            when route != PortalDestinations.support)
                          TextButton(
                            onPressed: () {
                              if (route == PortalDestinations.stations ||
                                  route == PortalDestinations.cards) {
                                context.go(route);
                              } else {
                                context.push(route);
                              }
                            },
                            child: Text(switch (route) {
                              PortalDestinations.balances => labels.balances,
                              PortalDestinations.cards => labels.cards,
                              PortalDestinations.topUp => labels.topUp,
                              PortalDestinations.stations => labels.stations,
                              PortalDestinations.subscriptions =>
                                labels.subscriptions,
                              PortalDestinations.prices =>
                                labels.priceBulletins,
                              _ => labels.supportFaq,
                            }),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchingReply extends StatelessWidget {
  const _SearchingReply();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (MediaQuery.disableAnimationsOf(context))
            const Icon(Icons.manage_search, size: 18)
          else
            const SizedBox.square(
              dimension: 16,
              child: ExcludeSemantics(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(width: 10),
          Flexible(child: Text(AppLocalizations.of(context)!.supportSearching)),
        ],
      ),
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
