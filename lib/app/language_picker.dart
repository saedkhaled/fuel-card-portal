import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import 'portal_settings.dart';
import 'portal_surfaces.dart';

Future<void> choosePortalLanguage(BuildContext context) async {
  final settings = context.read<PortalSettings>();
  final l10n = AppLocalizations.of(context)!;
  final selected = await showModalBottomSheet<Locale>(
    context: context,
    sheetAnimationStyle: portalSheetAnimation(context),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chooseLanguage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final (code, label) in [('ar', 'العربية'), ('en', 'English')])
              ListTile(
                title: Text(label),
                selected: settings.locale.languageCode == code,
                trailing: settings.locale.languageCode == code
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, Locale(code)),
              ),
          ],
        ),
      ),
    ),
  );
  if (selected == null) return;
  try {
    await settings.setLocale(selected);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.operationFailed)));
    }
  }
}
