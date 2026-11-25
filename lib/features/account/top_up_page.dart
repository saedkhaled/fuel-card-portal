import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/android_file_actions.dart';
import '../../l10n/generated/app_localizations.dart';
import '../finance/finance_labels.dart';
import '../finance/finance_scope.dart';
import 'account_pages.dart';
import 'account_scope.dart';

Future<Uint8List> encodeDemoQr(String payload) async {
  const side = 512;
  const margin = 64.0;
  final painter = QrPainter(
    data: payload,
    version: QrVersions.auto,
    gapless: true,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(Colors.white, BlendMode.src)
    ..translate(margin, margin);
  painter.paint(canvas, const Size.square(side - margin * 2));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(side, side);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode QR PNG');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  String? _selectedId;
  bool _busy = false;

  Future<void> _export(String payload, {required bool share}) async {
    final labels = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final bytes = await encodeDemoQr(payload);
      if (!mounted) return;
      final saved = await const AndroidFileActions().send(
        name: 'fleet-cards-demo-qr.png',
        mime: 'image/png',
        bytes: bytes,
        share: share,
      );
      if (saved && !share && mounted) accountMessage(context, labels.fileSaved);
    } catch (_) {
      if (mounted) accountMessage(context, labels.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topUp = accountProfile(context)?.topUp;
    final finance = accountFinance(context);
    final card = _selectedId == null
        ? finance.cards.firstOrNull
        : finance.cardById(_selectedId!);
    return Scaffold(
      appBar: AppBar(title: Text(labels.topUp)),
      body: SafeArea(
        child: topUp == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            labels.demoTopUp,
                            style: theme.textTheme.titleLarge,
                          ),
                          QrImageView(
                            data: topUp.qrPayload,
                            size: 216,
                            padding: const EdgeInsets.all(28),
                            backgroundColor: Colors.white,
                            semanticsLabel: labels.demoTopUp,
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _export(
                                        topUp.qrPayload,
                                        share: false,
                                      ),
                                icon: const Icon(Icons.file_download_outlined),
                                label: Text(labels.downloadImage),
                              ),
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _export(topUp.qrPayload, share: true),
                                icon: const Icon(Icons.share_outlined),
                                label: Text(labels.shareImage),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(labels.transferDestination),
                    subtitle: Text(isolate(topUp.destination)),
                    trailing: IconButton(
                      tooltip: labels.copyDestination,
                      onPressed: () =>
                          copyAccountText(context, topUp.destination),
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ),
                  Text(topUp.instructions.inLanguage(labels.localeName)),
                  const Divider(height: 32),
                  Text(labels.transferNote, style: theme.textTheme.titleLarge),
                  if (finance.cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(labels.noCards),
                    ),
                  if (card != null) ...[
                    InputDecorator(
                      decoration: InputDecoration(labelText: labels.chooseCard),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: card.id,
                          items: [
                            for (final item in finance.cards)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(isolate(item.number)),
                              ),
                          ],
                          onChanged: (id) => setState(() => _selectedId = id),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isolate(topUp.note(card.number, card.plate))),
                      trailing: IconButton(
                        tooltip: labels.copyNote,
                        onPressed: () => copyAccountText(
                          context,
                          topUp.note(card.number, card.plate),
                        ),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
