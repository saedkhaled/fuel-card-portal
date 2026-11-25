import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import 'station_network.dart';

class NetworkContent extends StatefulWidget {
  const NetworkContent({super.key, required this.builder});

  final Widget Function(BuildContext context, StationNetwork network) builder;

  @override
  State<NetworkContent> createState() => _NetworkContentState();
}

class _NetworkContentState extends State<NetworkContent> {
  late Future<StationNetwork> _future = context
      .read<NetworkRepository>()
      .load();

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final network = snapshot.data;
        if (network != null) return widget.builder(context, network);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labels.networkLoadFailed, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() {
                    _future = context.read<NetworkRepository>().retry();
                  }),
                  child: Text(labels.retry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
