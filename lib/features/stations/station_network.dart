import '../../demo/demo_fixtures.dart';
import '../cards/fleet_card.dart';

class NetworkText {
  const NetworkText(this.en, this.ar);

  final String en;
  final String ar;

  String inLanguage(String language) => language == 'ar' ? ar : en;
}

enum FuelAvailability { available, low, unavailable }

class FuelStation {
  const FuelStation({
    required this.id,
    required this.cityId,
    required this.name,
    required this.address,
    required this.availability,
    required this.directions,
  });

  final String id;
  final String cityId;
  final NetworkText name;
  final NetworkText address;
  final Map<FuelProduct, FuelAvailability> availability;
  final List<NetworkText> directions;
}

class PriceBulletin {
  const PriceBulletin(this.id, this.effectiveOn, this.prices);

  final String id;
  final DateTime effectiveOn;
  final Map<FuelProduct, int> prices;
}

class StationNetwork {
  const StationNetwork({
    required this.cities,
    required this.products,
    required this.stations,
    required this.bulletins,
    required this.currentBulletinId,
  });

  final Map<String, NetworkText> cities;
  final Map<FuelProduct, NetworkText> products;
  final Map<String, FuelStation> stations;
  final Map<String, PriceBulletin> bulletins;
  final String? currentBulletinId;

  PriceBulletin? get current => bulletins[currentBulletinId];

  List<PriceBulletin> get history =>
      bulletins.values.where((item) => item.id != currentBulletinId).toList()
        ..sort((a, b) => b.effectiveOn.compareTo(a.effectiveOn));
}

class StationFilter {
  const StationFilter({this.cityId, this.product});

  final String? cityId;
  final FuelProduct? product;

  bool get isActive => cityId != null || product != null;

  List<FuelStation> results(
    StationNetwork data, {
    required String language,
    String search = '',
  }) {
    final query = _normalize(search);
    return [
      for (final station in data.stations.values)
        if ((cityId == null || cityId == station.cityId) &&
            (product == null || station.availability.containsKey(product)) &&
            (_normalize(station.name.inLanguage(language)).contains(query) ||
                _normalize(
                  station.address.inLanguage(language),
                ).contains(query)))
          station,
    ];
  }

  static final _spaces = RegExp(r'\s+');

  static String _normalize(String text) =>
      text.trim().toLowerCase().replaceAll(_spaces, ' ');
}

class NetworkRepository {
  NetworkRepository(this._loader, this._path);

  final FixtureLoader _loader;
  final String? _path;
  Future<StationNetwork>? _data;

  Future<StationNetwork> load() => _data ??= _load();
  Future<StationNetwork> retry() => _data = _load();

  Future<StationNetwork> _load() async {
    final path = _path;
    if (path == null) {
      throw const FixtureException(
        FixtureLoader.manifestPath,
        'missing network mapping',
      );
    }
    return _NetworkDecoder(path).decode(await _loader.readObject(path));
  }
}

class _NetworkDecoder {
  const _NetworkDecoder(this.path);
  final String path;

  StationNetwork decode(Map<String, dynamic> json) {
    final cities = <String, NetworkText>{};
    for (final row in _rows(json['cities'], 'cities')) {
      _insert(
        cities,
        _string(row['id'], 'city id'),
        _localized(row['name']),
        'city',
      );
    }
    final products = <FuelProduct, NetworkText>{};
    for (final row in _rows(json['products'], 'products')) {
      _insert(
        products,
        _enum(FuelProduct.values, row['id'], 'product'),
        _localized(row['name']),
        'product',
      );
    }
    if (products.length != FuelProduct.values.length) {
      _fail('missing fuel product');
    }

    final stations = <String, FuelStation>{};
    for (final row in _rows(json['stations'], 'stations')) {
      final id = _string(row['id'], 'station id');
      final city = _string(row['cityId'], 'station city');
      if (!cities.containsKey(city)) _fail('unknown city for $id');
      final availability = <FuelProduct, FuelAvailability>{};
      for (final entry in _object(
        row['availability'],
        'availability',
      ).entries) {
        availability[_enum(FuelProduct.values, entry.key, 'station product')] =
            _enum(FuelAvailability.values, entry.value, 'availability state');
      }
      if (availability.isEmpty) _fail('empty availability for $id');
      final rawDirections = row['directions'];
      final directions = switch (rawDirections) {
        null => const <NetworkText>[],
        List<Object?> items when items.isNotEmpty =>
          items.map(_localized).toList(),
        _ => _fail('invalid directions for $id'),
      };
      _insert(
        stations,
        id,
        FuelStation(
          id: id,
          cityId: city,
          name: _localized(row['name']),
          address: _localized(row['address']),
          availability: Map.unmodifiable(availability),
          directions: List.unmodifiable(directions),
        ),
        'station',
      );
    }

    final bulletins = <String, PriceBulletin>{};
    for (final row in _rows(json['bulletins'], 'bulletins')) {
      final id = _string(row['id'], 'bulletin id');
      final effectiveOn = _date(row['effectiveDate']);
      final prices = <FuelProduct, int>{};
      for (final entry in _object(row['prices'], 'prices').entries) {
        final product = _enum(
          FuelProduct.values,
          entry.key,
          'bulletin product',
        );
        final minorUnits = entry.value;
        if (minorUnits is! int || minorUnits < 0) {
          _fail('invalid price for $id');
        }
        prices[product] = minorUnits;
      }
      if (prices.length != products.length) _fail('incomplete prices for $id');
      _insert(
        bulletins,
        id,
        PriceBulletin(id, effectiveOn, Map.unmodifiable(prices)),
        'bulletin',
      );
    }
    final currentRaw = json['currentBulletinId'];
    final current = currentRaw == null
        ? null
        : _string(currentRaw, 'current bulletin');
    final currentDate = bulletins[current]?.effectiveOn;
    if (bulletins.isNotEmpty
        ? currentDate == null ||
              bulletins.values.any(
                (item) => item.effectiveOn.isAfter(currentDate),
              )
        : current != null) {
      _fail('invalid current bulletin');
    }

    return StationNetwork(
      cities: Map.unmodifiable(cities),
      products: Map.unmodifiable(products),
      stations: Map.unmodifiable(stations),
      bulletins: Map.unmodifiable(bulletins),
      currentBulletinId: current,
    );
  }

  Never _fail(String why) => throw FixtureException(path, why);

  Map<String, dynamic> _object(Object? value, String label) =>
      value is Map<String, dynamic> ? value : _fail('invalid $label');

  Iterable<Map<String, dynamic>> _rows(Object? value, String label) =>
      value is List<Object?>
      ? value.map((item) => _object(item, label))
      : _fail('invalid $label');

  String _string(Object? value, String label) =>
      value is String && value.trim().isNotEmpty
      ? value
      : _fail('invalid $label');

  NetworkText _localized(Object? value) {
    final strings = _object(value, 'localized text');
    return NetworkText(
      _string(strings['en'], 'en text'),
      _string(strings['ar'], 'ar text'),
    );
  }

  T _enum<T extends Enum>(List<T> values, Object? value, String label) =>
      values.where((item) => item.name == value).firstOrNull ??
      _fail('unknown $label');

  void _insert<K, V>(Map<K, V> map, K id, V item, String type) {
    if (map.containsKey(id)) _fail('duplicate $type id');
    map[id] = item;
  }

  DateTime _date(Object? value) {
    final label = _string(value, 'effective date');
    final date = DateTime.tryParse('${label}T00:00:00Z');
    if (date == null || date.toIso8601String().split('T').first != label) {
      _fail('invalid effective date');
    }
    return date;
  }
}
