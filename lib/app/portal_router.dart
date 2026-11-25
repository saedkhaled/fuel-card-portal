import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_pages.dart';
import '../features/auth/session_controller.dart';
import '../l10n/generated/app_localizations.dart';
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
        path: PortalDestinations.notifications,
        builder: (context, _) {
          final labels = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(title: Text(labels.notifications)),
            body: Center(child: Text(labels.noNotifications)),
          );
        },
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
                    PortalTab.more => const FoundationMore(),
                    PortalTab.cards ||
                    PortalTab.balances ||
                    PortalTab.stations => PendingTab(tab: tab),
                  },
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
