Uri googleMapsDrivingDirections(String destination) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': destination, 'travelmode': 'driving'},
);
