import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/portal_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import 'card_notes.dart';
import 'fleet_card.dart';

class CardNoteTile extends StatelessWidget {
  const CardNoteTile({super.key, required this.card});

  final FleetCard card;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CardNotes>();
    final labels = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: store.read(card),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => store.retry(card),
            child: Text(labels.retry),
          );
        }
        final note = snapshot.data;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(note == null ? labels.addNote : labels.note),
          subtitle: note == null
              ? null
              : Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            sheetAnimationStyle: portalSheetAnimation(context),
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _EditNote(card: card, store: store, original: note),
          ),
        );
      },
    );
  }
}

class _EditNote extends StatefulWidget {
  const _EditNote({
    required this.card,
    required this.store,
    required this.original,
  });

  final FleetCard card;
  final CardNotes store;
  final String? original;

  @override
  State<_EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<_EditNote> {
  late final _text = TextEditingController(text: widget.original);
  bool _busy = false;
  bool _error = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit(String? value) async {
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      await widget.store.save(widget.card, value);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.original == null ? labels.addNote : labels.editNote,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('card-note-editor'),
                controller: _text,
                enabled: !_busy,
                maxLength: CardNotes.limit,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: labels.note,
                  errorText: _error ? labels.operationFailed : null,
                ),
              ),
              FilledButton(
                onPressed:
                    _busy ||
                        _text.text.trim().isEmpty ||
                        _text.text.characters.length > CardNotes.limit
                    ? null
                    : () => _submit(_text.text),
                child: Text(labels.saveNote),
              ),
              if (widget.original != null)
                TextButton(
                  onPressed: _busy ? null : () => _submit(null),
                  child: Text(labels.deleteNote),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
