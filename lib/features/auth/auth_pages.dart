import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/language_picker.dart';
import '../../app/portal_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _request(SessionController session) {
    session.request(_phone.text);
    if (session.issue == null && session.challenge != null) {
      FocusScope.of(context).unfocus();
      context.push('/sign-in/code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const PortalMark(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                PortalMark.hasBrandArtwork ? l10n.portalBrand : l10n.appTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.language,
            onPressed: () => choosePortalLanguage(context),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: _AuthBody(
        icon: Icons.local_gas_station_outlined,
        title: l10n.signInHeading,
        subtitle: l10n.signInHelp,
        children: [
          TextField(
            key: const Key('phone-field'),
            controller: _phone,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              _normalizeDigits,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => session.clearIssue(),
            onSubmitted: (_) => _request(session),
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              errorText: _message(l10n, session.issue),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _request(session),
            child: Text(l10n.sendCode),
          ),
          const SizedBox(height: 12),
          Text(l10n.demoPhone(_isolated(session.repository.sample.phone))),
          const SizedBox(height: 8),
          Text(l10n.signInRecovery),
        ],
      ),
    );
  }
}

class CodePage extends StatefulWidget {
  const CodePage({super.key, required this.now});

  final DateTime Function() now;

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final _code = TextEditingController();
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final active = session.challenge;
    final l10n = AppLocalizations.of(context)!;
    final now = widget.now();
    final expires = active?.expiresAt.difference(now) ?? Duration.zero;
    final resend = active?.resendAt.difference(now) ?? Duration.zero;
    final expired = expires <= Duration.zero;
    final phone = active?.phone;
    final masked = phone == null
        ? ''
        : '${phone.substring(0, 3)}•••••${phone.substring(8)}';
    return PopScope<Object?>(
      canPop: !session.busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && session.accountId == null) session.cancelChallenge();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signIn)),
        body: _AuthBody(
          icon: Icons.verified_user_outlined,
          title: l10n.verifyHeading,
          subtitle: l10n.verifyHelp(_isolated(masked)),
          children: [
            TextField(
              key: const Key('code-field'),
              controller: _code,
              enabled: !session.busy && !expired,
              autofocus: true,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                _normalizeDigits,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (value) {
                session.clearIssue();
                if (value.length == 6) {
                  unawaited(session.verify(value));
                } else {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                labelText: l10n.codeLabel,
                errorText: _message(l10n, session.issue),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              expired && !session.busy
                  ? l10n.expiredCode
                  : l10n.codeExpires(_isolated(_countdown(expires))),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: session.busy || expired || _code.text.length != 6
                  ? null
                  : () => session.verify(_code.text),
              child: Text(l10n.confirmCode),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: session.busy || resend > Duration.zero
                  ? null
                  : () {
                      _code.clear();
                      session.resend();
                    },
              child: Text(
                resend > Duration.zero
                    ? l10n.resendIn(_isolated(_countdown(resend)))
                    : l10n.resendCode,
              ),
            ),
            if (active != null)
              Text(l10n.demoCode(_isolated(active.account.code))),
          ],
        ),
      ),
    );
  }
}

class _AuthBody extends StatelessWidget {
  const _AuthBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalHeroSurface(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: icon == Icons.local_gas_station_outlined
                        ? const PortalMark(size: 48)
                        : Icon(icon, size: 42),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _normalizeDigits = TextInputFormatter.withFunction((old, value) {
  final normalized = String.fromCharCodes(
    value.text.runes.map((rune) {
      if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
      if (rune >= 0x06f0 && rune <= 0x06f9) return rune - 0x06f0 + 0x30;
      return rune;
    }),
  );
  return FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
    old,
    value.copyWith(text: normalized),
  );
});

String _isolated(String value) => '\u2066$value\u2069';

String _countdown(Duration duration) {
  final seconds = (duration.inMilliseconds / 1000).ceil().clamp(0, 1 << 31);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String? _message(AppLocalizations l10n, AuthIssue? issue) => switch (issue) {
  AuthIssue.invalidPhone => l10n.invalidPhone,
  AuthIssue.unknownPhone => l10n.unknownPhone,
  AuthIssue.requestFailed => l10n.requestFailed,
  AuthIssue.invalidCode => l10n.invalidCode,
  AuthIssue.expired => l10n.expiredCode,
  AuthIssue.saveFailed => l10n.operationFailed,
  null => null,
};
