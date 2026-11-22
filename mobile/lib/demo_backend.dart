import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Demo-Backend für die Live-Demo auf GitHub Pages (dort läuft kein PHP-Server).
///
/// Es spielt die Laravel-API im Speicher nach: gleiche Pfade, gleiche JSON-Felder,
/// gleiche Preisregeln wie der PricingService. Die App merkt keinen Unterschied,
/// weil sie nur einen anderen http.Client bekommt.
class DemoBackend {
  static const token = 'demo-token';

  /// Beim Preis zählt eine echte Sekunde wie [timeFactor] Sekunden (60 = 1 s ≙ 1 min),
  /// damit man in der Demo nicht eine Stunde warten muss.
  final int timeFactor;
  final DateTime Function() _now;

  DemoBackend({this.timeFactor = 60, DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _tenants = <String, Map<String, dynamic>>{
    'berlin': {'name': 'Berlin Parking', 'slug': 'berlin', 'primary_color': '#dc2626', 'logo_url': null, 'currency': 'EUR'},
    'wien': {'name': 'Wien Garagen', 'slug': 'wien', 'primary_color': '#059669', 'logo_url': null, 'currency': 'EUR'},
  };

  // Gleiche Parkplätze wie im DemoSeeder, nur schon teilweise belegt.
  final List<Map<String, dynamic>> _lots = [
    {'id': 1, 'name': 'Hauptbahnhof', 'address': null, 'capacity': 120, 'free': 37, 'hourly_rate_cents': 300, 'free_minutes': 15, 'daily_cap_cents': 2400},
    {'id': 2, 'name': 'Altstadt', 'address': null, 'capacity': 40, 'free': 2, 'hourly_rate_cents': 450, 'free_minutes': 0, 'daily_cap_cents': null},
  ];
  final List<Map<String, dynamic>> _sessions = [];
  int _nextId = 1;

  http.Client get client => MockClient(_handle);

  /// Gleiche Regeln wie PricingService.php: Gratisminuten, angefangene Stunden, Tagesmaximum.
  static int price(int minutes, int hourlyRateCents, int freeMinutes, int? dailyCapCents) {
    if (minutes <= freeMinutes) return 0;
    final fullDays = minutes ~/ (24 * 60);
    final restMinutes = minutes % (24 * 60);
    var restCost = (restMinutes / 60).ceil() * hourlyRateCents;
    var dayCost = 24 * hourlyRateCents;
    if (dailyCapCents != null) {
      if (restCost > dailyCapCents) restCost = dailyCapCents;
      if (dayCost > dailyCapCents) dayCost = dailyCapCents;
    }
    return fullDays * dayCost + restCost;
  }

  Future<http.Response> _handle(http.Request req) async {
    final tenant = req.headers['X-Tenant'];
    if (!_tenants.containsKey(tenant)) return _json({'message': 'Unbekannter Kunde.'}, 404);

    final path = req.url.path.replaceFirst(RegExp(r'^.*/api'), '');
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;

    // Öffentliche Endpunkte
    if (req.method == 'GET' && path == '/branding') return _json(_tenants[tenant]);
    if (req.method == 'GET' && path == '/lots') return _json(_lots);
    if (req.method == 'POST' && path == '/login') {
      if (body['email'] == 'operator@$tenant.test' && body['password'] == 'password') {
        return _json({
          'token': token,
          'user': {'id': 1, 'name': 'Operator ${_tenants[tenant]!['name']}', 'role': 'operator'},
        });
      }
      return _json({'message': 'E-Mail oder Passwort ist falsch.'}, 422);
    }

    // Ab hier nur mit Token
    if (req.headers['Authorization'] != 'Bearer $token') return _json({'message': 'Bitte zuerst anmelden.'}, 401);

    if (req.method == 'POST' && path == '/logout') return http.Response('', 204);
    if (req.method == 'GET' && path == '/sessions/active') {
      return _json(_sessions.where((s) => s['ended_at'] == null).toList());
    }
    if (req.method == 'POST' && path == '/sessions') return _start(body);

    final stop = RegExp(r'^/sessions/(\d+)/stop$').firstMatch(path);
    if (req.method == 'POST' && stop != null) return _stop(int.parse(stop.group(1)!));

    return _json({'message': 'Nicht gefunden.'}, 404);
  }

  http.Response _start(Map<String, dynamic> body) {
    final plate = (body['license_plate'] as String? ?? '').trim().toUpperCase();
    if (plate.isEmpty) return _json({'message': 'Bitte ein Kennzeichen eingeben.'}, 422);
    final lot = _lots.where((l) => l['id'] == body['parking_lot_id']).firstOrNull;
    if (lot == null) return _json({'message': 'Parkplatz nicht gefunden.'}, 404);
    if ((lot['free'] as int) <= 0) return _json({'message': 'Der Parkplatz ist voll.'}, 409);

    lot['free'] = (lot['free'] as int) - 1;
    final session = <String, dynamic>{
      'id': _nextId++,
      'parking_lot_id': lot['id'],
      'license_plate': plate,
      'started_at': _now().toUtc().toIso8601String(),
      'ended_at': null,
      'amount_cents': null,
    };
    _sessions.add(session);
    return _json(session, 201);
  }

  http.Response _stop(int id) {
    final session = _sessions.where((s) => s['id'] == id).firstOrNull;
    if (session == null) return _json({'message': 'Parkzeit nicht gefunden.'}, 404);
    if (session['ended_at'] != null) return _json({'message': 'Diese Parkzeit ist schon beendet.'}, 409);

    final lot = _lots.firstWhere((l) => l['id'] == session['parking_lot_id']);
    final end = _now().toUtc();
    final start = DateTime.parse(session['started_at'] as String);
    // Immer auf volle Minuten aufrunden (wie im Backend)
    final minutes = (end.difference(start).inMilliseconds * timeFactor / 60000).ceil();

    session['ended_at'] = end.toIso8601String();
    session['amount_cents'] = price(minutes, lot['hourly_rate_cents'] as int, lot['free_minutes'] as int, lot['daily_cap_cents'] as int?);
    lot['free'] = (lot['free'] as int) + 1;
    return _json(session);
  }

  static http.Response _json(Object? data, [int status = 200]) =>
      http.Response(jsonEncode(data), status, headers: {'content-type': 'application/json; charset=utf-8'});
}
