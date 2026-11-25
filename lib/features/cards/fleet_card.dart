enum CardStatus { active, stopped }

enum FuelProduct { diesel, benzene, premium }

class FleetCard {
  const FleetCard({
    required this.id,
    required this.accountId,
    required this.number,
    required this.plate,
    required this.status,
    required this.product,
    required this.plan,
    required this.quotaLiters,
    required this.createdAt,
    this.activatedAt,
    this.deliveredAt,
    this.rfid,
    this.seedNote,
  });

  final String id;
  final String accountId;
  final String number;
  final String plate;
  final CardStatus status;
  final FuelProduct product;
  final String plan;
  final int quotaLiters;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? deliveredAt;
  final String? rfid;
  final String? seedNote;

  bool matches(String search, CardStatus? status) =>
      (status == null || status == this.status) &&
      (number.toLowerCase().contains(search.trim().toLowerCase()) ||
          plate.toLowerCase().contains(search.trim().toLowerCase()));
}
