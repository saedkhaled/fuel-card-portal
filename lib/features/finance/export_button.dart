import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'finance_export.dart';

class ExportButton extends StatefulWidget {
  const ExportButton({super.key, required this.prepare, this.share = false});

  final Future<FinanceExport> Function() prepare;
  final bool share;

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    final labels = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final format = await showModalBottomSheet<FinanceExportFormat>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels.chooseFileFormat,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final format in FinanceExportFormat.values)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(format.name.toUpperCase()),
                  onTap: () => Navigator.pop(context, format),
                ),
            ],
          ),
        ),
      );
      if (format == null || !mounted) return;
      final table = await widget.prepare();
      if (!mounted) return;
      final saved = await const AndroidFinanceExport().send(
        table,
        format,
        share: widget.share,
      );
      if (saved && mounted && !widget.share) _message(labels.fileSaved);
    } catch (_) {
      if (mounted) _message(labels.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: widget.share ? labels.shareFile : labels.exportFile,
      onPressed: _busy ? null : _export,
      icon: Icon(
        widget.share ? Icons.share_outlined : Icons.file_download_outlined,
      ),
    );
  }
}
