import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_surfaces.dart';
import '../../app/portal_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cards/fleet_card.dart';
import 'network_content.dart';
import 'station_network.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  final _searchFocus = FocusNode();
  StationFilter _filter = const StationFilter();
  String _search = '';

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _editFilter(StationNetwork network) async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<StationFilter>(
      context: context,
      sheetAnimationStyle: portalSheetAnimation(context),
      showDragHandle: true,
      requestFocus: false,
      isScrollControlled: true,
      builder: (_) => _StationFilterSheet(network: network, current: _filter),
    );
    if (mounted && selected != null) setState(() => _filter = selected);
  }

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return NetworkContent(
      builder: (context, network) {
        final stations = _filter.results(
          network,
          language: labels.localeName,
          search: _search,
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('station-search'),
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        labelText: labels.searchStations,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (text) => setState(() => _search = text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: labels.filter,
                    isSelected: _filter.isActive,
                    onPressed: () => _editFilter(network),
                    selectedIcon: const Icon(Icons.filter_alt),
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
                ],
              ),
            ),
            if (network.stations.values.any(
              (station) => station.operator != null,
            ))
              const _StationWebsiteLink(),
            if (_filter.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_filter.operator case final operator?)
                      InputChip(
                        label: Text(_stationOperatorName(labels, operator)),
                        onDeleted: () => setState(
                          () => _filter = StationFilter(
                            cityId: _filter.cityId,
                            product: _filter.product,
                          ),
                        ),
                      ),
                    if (_filter.cityId case final id?)
                      InputChip(
                        label: Text(
                          network.cities[id]!.inLanguage(labels.localeName),
                        ),
                        onDeleted: () => setState(
                          () => _filter = StationFilter(
                            product: _filter.product,
                            operator: _filter.operator,
                          ),
                        ),
                      ),
                    if (_filter.product case final product?)
                      InputChip(
                        label: Text(
                          network.products[product]!.inLanguage(
                            labels.localeName,
                          ),
                        ),
                        onDeleted: () => setState(
                          () => _filter = StationFilter(
                            cityId: _filter.cityId,
                            operator: _filter.operator,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: stations.isEmpty
                  ? Center(
                      child: Text(
                        labels.noStations,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: stations.length,
                      itemBuilder: (_, index) => _StationCard(
                        network: network,
                        station: stations[index],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.network, required this.station});

  final StationNetwork network;
  final FuelStation station;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final operator = station.operator;
    final goldenGate = operator == StationOperator.goldenGate;
    final taiba = operator == StationOperator.taiba;
    final accent = switch (operator) {
      StationOperator.goldenGate => portalGold,
      StationOperator.taiba => const Color(0xff1a5841),
      null => null,
    };
    final secondaryText = goldenGate ? const Color(0xffe4edf8) : portalMuted;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: operator == null ? null : Clip.antiAlias,
      shape: operator == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              side: BorderSide(
                color: taiba ? const Color(0xffb9ddca) : portalLine,
              ),
            ),
      child: Ink(
        decoration: taiba
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [Color(0xffe5f6ed), Color(0xfff7fcf9)],
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Ink(
              decoration: goldenGate
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [portalNavy, portalInk],
                      ),
                      border: Border(
                        bottom: BorderSide(color: portalGold, width: 2),
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.inLanguage(labels.localeName),
                      style: goldenGate
                          ? text.titleLarge?.copyWith(color: Colors.white)
                          : text.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.address.inLanguage(labels.localeName),
                      style: text.bodyMedium?.copyWith(color: secondaryText),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          network.cities[station.cityId]!.inLanguage(
                            labels.localeName,
                          ),
                          style: text.labelMedium?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                        if (operator != null && accent != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: goldenGate ? .16 : .09,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              child: Text(
                                _stationOperatorName(labels, operator),
                                style: text.labelMedium?.copyWith(
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labels.availability, style: text.titleSmall),
                  const SizedBox(height: 6),
                  _Availability(network: network, station: station),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          context.push(PortalDestinations.station(station.id));
                        },
                        child: Text(labels.stationDetails),
                      ),
                      if (station.hasDirections)
                        TextButton.icon(
                          onPressed: () => _openDirections(context, station),
                          icon: const Icon(Icons.directions_outlined),
                          label: Text(labels.directions),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Availability extends StatelessWidget {
  const _Availability({required this.network, required this.station});

  final StationNetwork network;
  final FuelStation station;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final MapEntry(key: product, value: status)
            in station.availability.entries)
          _AvailabilityBadge(
            product:
                (station.productNames[product] ?? network.products[product]!)
                    .inLanguage(labels.localeName),
            status: status,
          ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.product, required this.status});

  final String product;
  final FuelAvailability status;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final (label, icon, background, foreground) = switch (status) {
      FuelAvailability.available => (
        labels.available,
        Icons.check_circle_outline,
        const Color(0xffdff5e7),
        const Color(0xff14633b),
      ),
      FuelAvailability.low => (
        labels.runningLow,
        Icons.timelapse,
        const Color(0xffffefad),
        const Color(0xff694a00),
      ),
      FuelAvailability.unavailable => (
        labels.unavailable,
        Icons.remove_circle_outline,
        const Color(0xffffe2e0),
        const Color(0xff9b2226),
      ),
      FuelAvailability.listed => (
        null,
        Icons.local_gas_station_outlined,
        const Color(0xffe8eef5),
        const Color(0xff224263),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: .16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label == null ? product : '$product · $label',
                style: TextStyle(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationDetailsPage extends StatelessWidget {
  const StationDetailsPage({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(labels.stationDetails)),
      body: SafeArea(
        child: NetworkContent(
          builder: (context, network) {
            final station = network.stations[stationId];
            if (station == null) {
              return Center(child: Text(labels.missingStation));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PortalHeroSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_gas_station_outlined),
                      const SizedBox(height: 10),
                      Text(
                        station.name.inLanguage(labels.localeName),
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(labels.address),
                  subtitle: Text(station.address.inLanguage(labels.localeName)),
                ),
                ListTile(
                  leading: const Icon(Icons.location_city_outlined),
                  title: Text(labels.city),
                  subtitle: Text(
                    network.cities[station.cityId]!.inLanguage(
                      labels.localeName,
                    ),
                  ),
                ),
                if (station.operator case final operator?)
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(_stationOperatorName(labels, operator)),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels.availability,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _Availability(network: network, station: station),
                if (station.hasDirections)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: FilledButton.icon(
                      onPressed: () => _openDirections(context, station),
                      icon: const Icon(Icons.directions_outlined),
                      label: Text(labels.directions),
                    ),
                  ),
                if (station.operator != null) const _StationWebsiteLink(),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _stationOperatorName(
  AppLocalizations labels,
  StationOperator operator,
) => switch (operator) {
  StationOperator.goldenGate => labels.stationGoldenGate,
  StationOperator.taiba => labels.stationTaiba,
};

class _StationWebsiteLink extends StatelessWidget {
  const _StationWebsiteLink();

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      try {
        if (await launchUrl(
          officialStationsMap,
          mode: LaunchMode.externalApplication,
        ))
          return;
      } on Exception {
        // A device may have no enabled browser.
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.supportSourceUnavailable),
        ),
      );
    },
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(AppLocalizations.of(context)!.supportStationMap),
  );
}

Future<void> _openDirections(BuildContext context, FuelStation station) async {
  FocusScope.of(context).unfocus();
  final url = station.googleMapsDirections;
  if (url != null) {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } on Exception {
      // A device may have no Maps app or browser available.
    }
  }

  if (!context.mounted) return;
  if (station.directions.isNotEmpty) {
    context.push(PortalDestinations.directions(station.id));
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.mapsUnavailable)),
  );
}

class StationDirectionsPage extends StatelessWidget {
  const StationDirectionsPage({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(labels.mockDirections)),
      body: SafeArea(
        child: NetworkContent(
          builder: (context, network) {
            final station = network.stations[stationId];
            if (station == null || station.directions.isEmpty) {
              return Center(child: Text(labels.missingStation));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  station.name.inLanguage(labels.localeName),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(labels.mockDirectionsHelp),
                const SizedBox(height: 12),
                for (final (index, step) in station.directions.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(step.inLanguage(labels.localeName)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StationFilterSheet extends StatefulWidget {
  const _StationFilterSheet({required this.network, required this.current});

  final StationNetwork network;
  final StationFilter current;

  @override
  State<_StationFilterSheet> createState() => _StationFilterSheetState();
}

class _StationFilterSheetState extends State<_StationFilterSheet> {
  late String? _city = widget.current.cityId;
  late FuelProduct? _product = widget.current.product;
  late StationOperator? _operator = widget.current.operator;

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels.filter, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(labels.stationNetworkFilter),
            Wrap(
              spacing: 8,
              children: [
                for (final operator in [null, ...StationOperator.values])
                  ChoiceChip(
                    label: Text(
                      operator == null
                          ? labels.allNetworks
                          : _stationOperatorName(labels, operator),
                    ),
                    selected: operator == _operator,
                    onSelected: (_) => setState(() => _operator = operator),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(labels.city),
            Wrap(
              spacing: 8,
              children: [
                for (final id in [null, ...widget.network.cities.keys])
                  ChoiceChip(
                    label: Text(
                      id == null
                          ? labels.allCities
                          : widget.network.cities[id]!.inLanguage(
                              labels.localeName,
                            ),
                    ),
                    selected: id == _city,
                    onSelected: (_) => setState(() => _city = id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(labels.product),
            Wrap(
              spacing: 8,
              children: [
                for (final product in [null, ...widget.network.products.keys])
                  ChoiceChip(
                    label: Text(
                      product == null
                          ? labels.allProducts
                          : widget.network.products[product]!.inLanguage(
                              labels.localeName,
                            ),
                    ),
                    selected: product == _product,
                    onSelected: (_) => setState(() => _product = product),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _city = null;
                    _product = null;
                    _operator = null;
                  }),
                  child: Text(labels.clearFilters),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    StationFilter(
                      cityId: _city,
                      product: _product,
                      operator: _operator,
                    ),
                  ),
                  child: Text(labels.applyFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
