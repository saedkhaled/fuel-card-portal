import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_shell.dart';
import '../../app/portal_theme.dart';
import '../../demo/demo_fixtures.dart';
import '../stations/station_network.dart';
import '../../l10n/generated/app_localizations.dart';
import 'support_catalog.dart';
import 'support_gemini.dart';
import 'support_stations.dart';

enum _LocationIssue { permissionDenied, servicesDisabled, unavailable }

typedef _NearestResult = ({FuelStation? station, _LocationIssue? issue});
typedef SupportReply = ({String text, List<SupportEntry> sources, bool online});
typedef _ChatTurn = ({
  String question,
  SupportReply? reply,
  _NearestResult? nearest,
});

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_ChatTurn>[];
  late Future<SupportCatalog> _catalog;
  bool _searching = false;
  bool _locating = false;

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

  Future<void> _send(
    SupportCatalog? catalog,
    String text, {
    bool nearestShortcut = false,
  }) async {
    final question = text.trim();
    if (question.isEmpty || _searching) return;
    final locating =
        nearestShortcut || (catalog?.requestsNearestStation(question) ?? false);
    final previous = _turns.lastOrNull;
    final labels = AppLocalizations.of(context)!;
    final gemini = context.read<SupportGemini?>();
    setState(() {
      _searching = true;
      _locating = locating;
      _turns.add((question: question, reply: null, nearest: null));
    });
    _composer.clear();
    if (_scroll.hasClients) _scroll.jumpTo(0);

    final _NearestResult? nearest;
    final SupportReply? reply;
    if (locating) {
      FocusManager.instance.primaryFocus?.unfocus();
      nearest = await _findNearest(context.read<NetworkRepository>());
      reply = null;
    } else {
      nearest = null;
      // Let the indicator paint even when a bundled answer is immediate.
      final indicator = Future<void>.delayed(const Duration(milliseconds: 450));
      final match = catalog?.findAnswer(
        question,
        previous: previous?.reply?.sources.firstOrNull,
      );
      final action = catalog?.localAction(question, match);
      if (SupportGemini.isPrivateQuestion(question)) {
        reply = (
          text: labels.supportPrivateAccount,
          sources: [if (action != null) action],
          online: false,
        );
      } else if (action != null) {
        reply = (text: action.passage, sources: [action], online: false);
      } else {
        final generated = await gemini?.answer(
          catalog,
          question,
          firstTurn: previous == null,
          previous: previous?.reply?.online == true
              ? (question: previous!.question, reply: previous.reply!.text)
              : null,
        );
        if (generated != null) {
          reply = (
            text: generated,
            sources: [if (match != null) match],
            online: true,
          );
        } else if (match != null) {
          reply = (
            text: match.id == SupportCatalog.assistantIdentityId
                ? labels.assistantIntroduction
                : match.passage,
            sources: [match],
            online: false,
          );
        } else {
          reply = null;
        }
      }
      await indicator;
    }
    if (!mounted) return;
    setState(() {
      _turns[_turns.length - 1] = (
        question: question,
        reply: reply,
        nearest: nearest,
      );
      _searching = false;
      _locating = false;
    });
  }

  Future<_NearestResult> _findNearest(NetworkRepository repository) async {
    try {
      final network = await repository.load();
      if (!mounted || network.stations.isEmpty) {
        return (station: null, issue: _LocationIssue.unavailable);
      }
      final position = await currentStationLocation();
      final station = position == null
          ? null
          : nearestOfficialStation(network.stations.values, position);
      return (
        station: station,
        issue: station == null ? _LocationIssue.unavailable : null,
      );
    } on PlatformException catch (error) {
      return (
        station: null,
        issue: switch (error.code) {
          'permission_denied' => _LocationIssue.permissionDenied,
          'services_disabled' => _LocationIssue.servicesDisabled,
          _ => _LocationIssue.unavailable,
        },
      );
    } on MissingPluginException {
      return (station: null, issue: _LocationIssue.unavailable);
    } on FixtureException {
      return (station: null, issue: _LocationIssue.unavailable);
    }
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
    final hasGemini = context.watch<SupportGemini?>() != null;
    return FutureBuilder<SupportCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (!hasGemini && snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final catalog = snapshot.data;
        if (!hasGemini && catalog == null) {
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
                          reply: turn.reply,
                          nearest: turn.nearest,
                          retryLocation:
                              !_searching && turn.nearest?.issue != null
                              ? () => _send(
                                  catalog,
                                  turn.question,
                                  nearestShortcut: true,
                                )
                              : null,
                          searching: _searching && index == 0,
                          locating: _locating && index == 0,
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

  Widget _welcome(SupportCatalog? catalog, AppLocalizations labels) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels.supportIntro),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.near_me_outlined, size: 18),
              label: Text(labels.supportNearestStation),
              onPressed: () => _send(
                catalog,
                labels.supportNearestStation,
                nearestShortcut: true,
              ),
            ),
            for (final entry in {
              ...?catalog?.entries
                  .where(
                    (entry) => entry.sourceUrl != null && entry.example != null,
                  )
                  .take(2),
              ...?catalog?.entries,
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
    required this.reply,
    required this.nearest,
    required this.retryLocation,
    required this.searching,
    required this.locating,
  });

  final String question;
  final SupportReply? reply;
  final _NearestResult? nearest;
  final VoidCallback? retryLocation;
  final bool searching;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final body = reply?.text ?? labels.supportNoAnswer;
    final direction = _textDirection(body);
    final sources = reply?.sources ?? const <SupportEntry>[];
    final sections = {
      if (reply?.online != true)
        for (final source in sources)
          if (source.guideSection case final section?) section,
    };
    final urls = {
      for (final source in sources)
        if (source.sourceUrl case final url?)
          url.fragment == 'stations' ? officialStationsMap : url,
      for (final url in SupportCatalog.officialLinksIn(body))
        url.fragment == 'stations' ? officialStationsMap : url,
    };
    final routes = {
      for (final source in sources)
        if (source.route case final route?
            when route != PortalDestinations.support)
          route,
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
                ? _SearchingReply(locating: locating)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: nearest != null
                        ? _NearestStationReply(
                            result: nearest!,
                            onRetry: retryLocation,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                liveRegion: true,
                                child: Align(
                                  alignment: direction == TextDirection.rtl
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(body, textDirection: direction),
                                ),
                              ),
                              if (reply == null)
                                const _FaqLink()
                              else ...[
                                for (final section in sections)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${labels.supportGuideSource} · $section',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ),
                                for (final url in urls)
                                  _SupportSourceLink(
                                    url: url,
                                    label: url.fragment == 'stations'
                                        ? labels.supportStationMap
                                        : labels.supportOfficialSource,
                                  ),
                                if (sources.isNotEmpty &&
                                    urls.isEmpty &&
                                    sections.isEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    labels.supportSampleSource,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: portalMuted),
                                  ),
                                ],
                                for (final route in routes)
                                  TextButton(
                                    onPressed: () {
                                      if (route ==
                                              PortalDestinations.stations ||
                                          route == PortalDestinations.cards) {
                                        context.go(route);
                                      } else {
                                        context.push(route);
                                      }
                                    },
                                    child: Text(switch (route) {
                                      PortalDestinations.balances =>
                                        labels.balances,
                                      PortalDestinations.cards => labels.cards,
                                      PortalDestinations.topUp => labels.topUp,
                                      PortalDestinations.stations =>
                                        labels.stations,
                                      PortalDestinations.subscriptions =>
                                        labels.subscriptions,
                                      PortalDestinations.prices =>
                                        labels.priceBulletins,
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

class _SearchingReply extends StatelessWidget {
  const _SearchingReply({required this.locating});

  final bool locating;

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
          Flexible(
            child: Text(
              locating
                  ? AppLocalizations.of(context)!.supportLocating
                  : AppLocalizations.of(context)!.supportSearching,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NearestStationReply extends StatelessWidget {
  const _NearestStationReply({required this.result, required this.onRetry});

  final _NearestResult result;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final station = result.station;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            station != null
                ? labels.supportNearestResult(
                    station.name.inLanguage(labels.localeName),
                  )
                : switch (result.issue) {
                    _LocationIssue.permissionDenied =>
                      labels.supportLocationDenied,
                    _LocationIssue.servicesDisabled =>
                      labels.supportLocationServicesOff,
                    _ => labels.supportLocationUnavailable,
                  },
          ),
        ),
        if (station?.googleMapsDirections case final url?)
          TextButton.icon(
            onPressed: () => _openExternal(context, url, maps: true),
            icon: const Icon(Icons.directions_outlined, size: 18),
            label: Text(labels.supportGoogleDirections),
          )
        else ...[
          if (result.issue == _LocationIssue.permissionDenied ||
              result.issue == _LocationIssue.servicesDisabled)
            TextButton.icon(
              onPressed: () async {
                final opened = await openStationLocationSettings(
                  permission: result.issue == _LocationIssue.permissionDenied,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(labels.supportLocationUnavailable)),
                  );
                }
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(labels.supportLocationSettings),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(labels.supportLocationRetry),
            ),
          TextButton.icon(
            onPressed: () =>
                _openExternal(context, stationSearchInGoogleMaps, maps: true),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(labels.supportSearchGoogleMaps),
          ),
        ],
        _SupportSourceLink(
          url: officialStationsMap,
          label: labels.supportStationMap,
        ),
      ],
    );
  }
}

class _SupportSourceLink extends StatelessWidget {
  const _SupportSourceLink({required this.url, required this.label});

  final Uri url;
  final String label;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => _openExternal(context, url),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(
          url.toString(),
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

Future<void> _openExternal(
  BuildContext context,
  Uri url, {
  bool maps = false,
}) async {
  try {
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
  } on Exception {
    // A device can have no enabled browser.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        maps
            ? AppLocalizations.of(context)!.mapsUnavailable
            : AppLocalizations.of(context)!.supportSourceUnavailable,
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
