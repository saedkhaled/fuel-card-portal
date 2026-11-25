import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../demo/demo_fixtures.dart';
import '../features/account/account_data.dart';
import '../features/notifications/inbox_controller.dart';
import '../features/auth/session_controller.dart';
import '../features/auth/session_repository.dart';
import '../features/cards/card_notes.dart';
import '../features/finance/fleet_data.dart';
import '../features/stations/station_network.dart';
import '../l10n/generated/app_localizations.dart';
import 'demo_preferences.dart';
import 'portal_router.dart';
import 'portal_settings.dart';
import 'portal_theme.dart';

class PortalBootstrap extends StatefulWidget {
  const PortalBootstrap({
    super.key,
    required this.loader,
    required this.preferences,
    required this.now,
    this.scenario,
    this.initialLocation = '/home',
  });

  final FixtureLoader loader;
  final DemoPreferences preferences;
  final DateTime Function() now;
  final String? scenario;
  final String initialLocation;

  @override
  State<PortalBootstrap> createState() => _PortalBootstrapState();
}

class _PortalBootstrapState extends State<PortalBootstrap> {
  late Future<_Startup> _startup = _load();

  Future<_Startup> _load() async {
    final DemoFixtures fixtures;
    final FleetData fleet;
    final AccountData account;
    try {
      fixtures = await widget.loader.load(scenario: widget.scenario);
      fleet = await FleetData.load(widget.loader, fixtures);
      account = await AccountData.load(widget.loader, fixtures, fleet);
    } on FixtureException catch (error) {
      debugPrint(error.toString());
      rethrow;
    }
    final preferences = widget.preferences;
    final repository = FixtureSessionRepository(
      fixtures,
      preferences,
      widget.now,
    );
    return _Startup(
      fixtures: fixtures,
      fleet: fleet,
      account: account,
      repository: repository,
      accountId: await repository.restore(),
      language: await preferences.read(PortalSettings.languageKey),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _startup,
    builder: (context, snapshot) {
      final startup = snapshot.data;
      if (startup != null) {
        return _PortalApp(
          startup: startup,
          preferences: widget.preferences,
          loader: widget.loader,
          now: widget.now,
          initialLocation: widget.initialLocation,
        );
      }

      return MaterialApp(
        theme: buildPortalTheme(locale: const Locale('ar')),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.startupError),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => setState(() {
                                _startup = _load();
                              }),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          },
        ),
      );
    },
  );
}

class _Startup {
  const _Startup({
    required this.fixtures,
    required this.fleet,
    required this.account,
    required this.repository,
    required this.accountId,
    required this.language,
  });

  final DemoFixtures fixtures;
  final FleetData fleet;
  final AccountData account;
  final SessionRepository repository;
  final String? accountId;
  final String? language;
}

class _PortalApp extends StatefulWidget {
  const _PortalApp({
    required this.startup,
    required this.loader,
    required this.preferences,
    required this.now,
    required this.initialLocation,
  });

  final _Startup startup;
  final FixtureLoader loader;
  final DemoPreferences preferences;
  final DateTime Function() now;
  final String initialLocation;

  @override
  State<_PortalApp> createState() => _PortalAppState();
}

class _PortalAppState extends State<_PortalApp> {
  late final SessionController _session;
  late final PortalSettings _settings;
  late final CardNotes _notes;
  late final InboxController _inbox;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final startup = widget.startup;
    _session = SessionController(startup.repository, startup.accountId);
    _notes = CardNotes(widget.preferences, startup.fixtures.scenario);
    _inbox = InboxController(
      startup.account,
      widget.preferences,
      startup.fixtures.scenario,
      _session,
    );
    _settings = PortalSettings(widget.preferences, language: startup.language);
    _router = createPortalRouter(
      _session,
      widget.now,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _inbox.dispose();
    _session.dispose();
    _settings.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: widget.startup.fixtures),
      Provider.value(value: widget.startup.fleet),
      Provider.value(value: widget.startup.account),
      ChangeNotifierProvider.value(value: _inbox),
      Provider(
        create: (_) => NetworkRepository(
          widget.loader,
          widget.startup.fixtures.files['network'],
        ),
      ),
      ChangeNotifierProvider.value(value: _notes),
      ChangeNotifierProvider.value(value: _session),
      ChangeNotifierProvider.value(value: _settings),
    ],
    child: Consumer<PortalSettings>(
      builder: (context, settings, _) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildPortalTheme(locale: settings.locale),
        locale: settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      ),
    ),
  );
}
