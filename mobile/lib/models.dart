// Datenklassen für die API-Antworten.

class Branding {
  final String name;
  final String slug;
  final String primaryColor; // z.B. "#dc2626"
  final String? logoUrl;
  final String currency;

  const Branding({
    required this.name,
    required this.slug,
    required this.primaryColor,
    required this.currency,
    this.logoUrl,
  });

  factory Branding.fromJson(Map<String, dynamic> j) => Branding(
        name: j['name'] as String,
        slug: j['slug'] as String,
        primaryColor: (j['primary_color'] as String?) ?? '#2563eb',
        logoUrl: j['logo_url'] as String?,
        currency: (j['currency'] as String?) ?? 'EUR',
      );

  // "#dc2626" -> 0xFFDC2626 (für Flutter Color).
  int get colorValue {
    final hex = primaryColor.replaceFirst('#', '');
    return int.tryParse('FF$hex', radix: 16) ?? 0xFF2563EB;
  }
}

class Lot {
  final int id;
  final String name;
  final String? address;
  final int capacity;
  final int free;
  final int hourlyRateCents;
  final int freeMinutes;
  final int? dailyCapCents;

  const Lot({
    required this.id,
    required this.name,
    required this.capacity,
    required this.free,
    required this.hourlyRateCents,
    required this.freeMinutes,
    this.address,
    this.dailyCapCents,
  });

  factory Lot.fromJson(Map<String, dynamic> j) => Lot(
        id: j['id'] as int,
        name: j['name'] as String,
        address: j['address'] as String?,
        capacity: j['capacity'] as int,
        free: j['free'] as int,
        hourlyRateCents: j['hourly_rate_cents'] as int,
        freeMinutes: (j['free_minutes'] as int?) ?? 0,
        dailyCapCents: j['daily_cap_cents'] as int?,
      );

  // Wie voll ist der Parkplatz? 0.0 = leer, 1.0 = voll.
  double get occupancy => capacity == 0 ? 1 : 1 - free / capacity;
}

class ParkingSession {
  final int id;
  final int lotId;
  final String licensePlate;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? amountCents;

  const ParkingSession({
    required this.id,
    required this.lotId,
    required this.licensePlate,
    required this.startedAt,
    this.endedAt,
    this.amountCents,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> j) => ParkingSession(
        id: j['id'] as int,
        lotId: j['parking_lot_id'] as int,
        licensePlate: j['license_plate'] as String,
        startedAt: DateTime.parse(j['started_at'] as String).toLocal(),
        endedAt: j['ended_at'] == null ? null : DateTime.parse(j['ended_at'] as String).toLocal(),
        amountCents: j['amount_cents'] as int?,
      );

  bool get isActive => endedAt == null;
}
