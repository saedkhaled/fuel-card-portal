abstract final class PortalDestinations {
  static const cards = '/cards';
  static const balances = '/balances';
  static const sales = '/sales';
  static const notifications = '/notifications';
  static const prices = '/price-bulletins';
  static String card(String id) => '/card/${Uri.encodeComponent(id)}';
  static String operations(String id) => '${card(id)}/operations';
}
