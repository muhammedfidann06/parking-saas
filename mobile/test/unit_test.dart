import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parking_mobile/api_client.dart';
import 'package:parking_mobile/models.dart';
import 'package:parking_mobile/money.dart';

void main() {
  group('formatMoney', () {
    test('Cent werden richtig formatiert', () {
      expect(formatMoney(350), '3,50 €');
      expect(formatMoney(5), '0,05 €');
      expect(formatMoney(123456), '1.234,56 €');
      expect(formatMoney(-200), '-2,00 €');
    });
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(minutes: 42)), '42 min');
    expect(formatDuration(const Duration(minutes: 65)), '1 h 05 min');
  });

  test('Branding.colorValue liest Hex-Farben', () {
    const b = Branding(name: 'X', slug: 'x', primaryColor: '#dc2626', currency: 'EUR');
    expect(b.colorValue, 0xFFDC2626);
  });

  test('Lot.occupancy', () {
    const lot = Lot(id: 1, name: 'A', capacity: 10, free: 3, hourlyRateCents: 300, freeMinutes: 0);
    expect(lot.occupancy, closeTo(0.7, 1e-9));
  });

  group('ApiClient', () {
    test('schickt X-Tenant und speichert das Token nach dem Login', () async {
      final seen = <http.BaseRequest>[];
      final client = MockClient((req) async {
        seen.add(req);
        if (req.url.path.endsWith('/login')) {
          return http.Response(jsonEncode({'token': 'abc', 'user': {'id': 1, 'name': 'T', 'role': 'driver'}}), 200);
        }
        return http.Response(jsonEncode([
          {'id': 1, 'name': 'Hauptbahnhof', 'address': null, 'capacity': 10, 'free': 4, 'hourly_rate_cents': 300, 'free_minutes': 15, 'daily_cap_cents': 2400}
        ]), 200);
      });

      final api = ApiClient(baseUrl: 'http://test/api', tenant: 'linz', client: client);
      await api.login('a@b.at', 'pw');
      final lots = await api.lots();

      expect(api.token, 'abc');
      expect(lots.single.name, 'Hauptbahnhof');
      expect(seen.every((r) => r.headers['X-Tenant'] == 'linz'), isTrue);
      expect(seen.last.headers['Authorization'], 'Bearer abc');
    });

    test('wirft ApiException mit der Server-Nachricht', () async {
      final client = MockClient((_) async => http.Response(jsonEncode({'message': 'Der Parkplatz ist voll.'}), 409));
      final api = ApiClient(baseUrl: 'http://test/api', tenant: 'linz', client: client, token: 't');

      expect(
        () => api.startSession(1, 'L1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Der Parkplatz ist voll.')),
      );
    });
  });
}
