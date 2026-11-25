import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../features/account/account_pages.dart';
import '../features/account/top_up_page.dart';
import '../features/auth/auth_pages.dart';
import '../features/auth/session_controller.dart';
import '../features/cards/cards_pages.dart';
import '../features/finance/finance_pages.dart';
import '../features/prices/price_pages.dart';
import '../features/notifications/notification_pages.dart';
import '../features/stations/station_pages.dart';
import '../features/support/support_page.dart';
import 'portal_destinations.dart';
import 'portal_shell.dart';

GoRouter createPortalRouter(
  SessionController session,
  DateTime Function() now, {
  String initialLocation = '/home',
}) {
  const signIn = '/sign-in';
  const code = '/sign-in/code';
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (_, state) {
      final path = state.uri.path;
      final inAuth = path == signIn || path == code;
      if (session.accountId != null) return inAuth ? PortalTab.home.path : null;
      if (!inAuth ||
          (path == code && session.challenge == null && !session.busy)) {
        return signIn;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: signIn,
        builder: (_, _) => const SignInPage(),
        routes: [
          GoRoute(
            path: 'code',
            builder: (_, _) => CodePage(now: now),
          ),
        ],
      ),
      GoRoute(
        path: '/card/:cardId',
        pageBuilder: (context, state) {
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final duration = reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 260);
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: duration,
            reverseTransitionDuration: duration,
            child: CardDetailsPage(id: state.pathParameters['cardId']!),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/card/:cardId/operations',
        builder: (_, state) =>
            OperationsPage(cardId: state.pathParameters['cardId']!),
      ),
      GoRoute(
        path: PortalDestinations.sales,
        builder: (_, _) => const SalesPage(),
      ),
      GoRoute(
        path: PortalDestinations.prices,
        builder: (_, _) => const PriceBulletinsPage(),
      ),
      GoRoute(
        path: '${PortalDestinations.prices}/:bulletinId',
        builder: (_, state) => PriceBulletinDetailsPage(
          bulletinId: state.pathParameters['bulletinId']!,
        ),
      ),
      GoRoute(
        path: '${PortalDestinations.stations}/:stationId',
        builder: (_, state) =>
            StationDetailsPage(stationId: state.pathParameters['stationId']!),
      ),
      GoRoute(
        path: '${PortalDestinations.stations}/:stationId/directions',
        builder: (_, state) => StationDirectionsPage(
          stationId: state.pathParameters['stationId']!,
        ),
      ),
      GoRoute(
        path: PortalDestinations.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: PortalDestinations.notificationSettings,
        builder: (_, _) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: PortalDestinations.subscriptions,
        builder: (_, _) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: '${PortalDestinations.subscriptions}/:cardId',
        builder: (_, state) =>
            InvoicesPage(cardId: state.pathParameters['cardId']!),
      ),
      GoRoute(
        path: PortalDestinations.topUp,
        builder: (_, _) => const TopUpPage(),
      ),
      GoRoute(
        path: PortalDestinations.information,
        builder: (_, _) => const InformationPage(),
      ),
      GoRoute(
        path: PortalDestinations.about,
        builder: (_, _) => const AboutPage(),
      ),
      GoRoute(
        path: PortalDestinations.balances,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context)!.balances)),
          body: const SafeArea(child: BalancesPage()),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigation) => PortalShell(navigation: navigation),
        branches: [
          for (final tab in PortalTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (_, _) => switch (tab) {
                    PortalTab.home => const FoundationHome(),
                    PortalTab.more => const AccountPage(),
                    PortalTab.cards => const CardsPage(),
                    PortalTab.support => const SupportPage(),
                    PortalTab.stations => const StationsPage(),
                  },
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
