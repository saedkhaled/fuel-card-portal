import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../core/coordinates.dart';
import '../stations/station_network.dart';

FuelStation? nearestOfficialStation(
  Iterable<FuelStation> stations,
  Coordinates origin,
) {
  FuelStation? nearest;
  var shortest = double.infinity;
  for (final station in stations) {
    final destination = station.coordinates;
    if (station.mobile || station.operator == null || destination == null) {
      continue;
    }
    const radians = math.pi / 180;
    final lat = math.sin(
      (destination.latitude - origin.latitude) * radians / 2,
    );
    final lon = math.sin(
      (destination.longitude - origin.longitude) * radians / 2,
    );
    // The haversine increases with distance, so no conversion to km is needed.
    final distance =
        lat * lat +
        math.cos(origin.latitude * radians) *
            math.cos(destination.latitude * radians) *
            lon *
            lon;
    if (distance < shortest) {
      shortest = distance;
      nearest = station;
    }
  }
  return nearest;
}

const stationLocationChannel = MethodChannel(
  'com.example.fleet_cards_demo/station_location',
);

final stationSearchInGoogleMaps = Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': 'Golden Gate fuel station near me',
});

Future<bool> openStationLocationSettings({required bool permission}) async {
  try {
    return await stationLocationChannel.invokeMethod<bool>('openSettings', {
          'permission': permission,
        }) ??
        false;
  } on Exception {
    return false;
  }
}

Future<Coordinates?> currentStationLocation() async {
  final location = await stationLocationChannel.invokeMapMethod<String, num>(
    'currentLocation',
  );
  return parseCoordinates(location?['latitude'], location?['longitude']);
}
