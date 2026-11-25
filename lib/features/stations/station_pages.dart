import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/portal_destinations.dart';
import '../../app/portal_surfaces.dart';
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
            if (_filter.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_filter.cityId case final id?)
                      InputChip(
                        label: Text(
                          network.cities[id]!.inLanguage(labels.localeName),
                        ),
                        onDeleted: () => setState(
                          () =>
                              _filter = StationFilter(product: _filter.product),
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
                          () => _filter = StationFilter(cityId: _filter.cityId),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name.inLanguage(labels.localeName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(station.address.inLanguage(labels.localeName)),
            Text(network.cities[station.cityId]!.inLanguage(labels.localeName)),
            const SizedBox(height: 10),
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
                if (station.directions.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      context.push(PortalDestinations.directions(station.id));
                    },
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(labels.directions),
                  ),
              ],
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
            product: network.products[product]!.inLanguage(labels.localeName),
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
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
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
                '$product · $label',
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
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels.availability,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _Availability(network: network, station: station),
                if (station.directions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        PortalDestinations.directions(station.id),
                      ),
                      icon: const Icon(Icons.directions_outlined),
                      label: Text(labels.directions),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
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
                  }),
                  child: Text(labels.clearFilters),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    StationFilter(cityId: _city, product: _product),
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
