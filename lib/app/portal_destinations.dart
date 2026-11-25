abstract final class PortalDestinations {
  static const cards = '/cards';
  static const balances = '/balances';
  static const sales = '/sales';
  static const notifications = '/notifications';
  static const stations = '/stations';
  static const prices = '/price-bulletins';
  static String station(String id) => '$stations/${Uri.encodeComponent(id)}';
  static String directions(String id) => '${station(id)}/directions';
  static String bulletin(String id) => '$prices/${Uri.encodeComponent(id)}';
  static String card(String id) => '/card/${Uri.encodeComponent(id)}';
  static String operations(String id) => '${card(id)}/operations';
}
