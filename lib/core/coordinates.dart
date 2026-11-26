typedef Coordinates = ({double latitude, double longitude});

Coordinates? parseCoordinates(Object? latitude, Object? longitude) {
  if (latitude is! num ||
      longitude is! num ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    return null;
  }
  return (latitude: latitude.toDouble(), longitude: longitude.toDouble());
}
