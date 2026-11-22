import 'package:flutter_test/flutter_test.dart';
import 'package:parking_mobile/api_client.dart';
import 'package:parking_mobile/demo_backend.dart';

void main() {
  group('DemoBackend.price (gleiche Regeln wie PricingService)', () {
    test('Gratisminuten, angefangene Stunden, Tagesmaximum', () {
      expect(DemoBackend.price(15, 300, 15, 2400), 0);
      expect(DemoBackend.price(16, 300, 15, 2400), 300);
      expect(DemoBackend.price(61, 300, 0, null), 600);
      expect(DemoBackend.price(20 * 60, 300, 0, 2400), 2400);
      expect(DemoBackend.price(24 * 60 + 30, 300, 0, 2400), 2400 + 300);
    });
  });

  group('DemoBackend über den echten ApiClient', () {
    late DateTime now;
    late ApiClient api;

    setUp(() {
      now = DateTime.utc(2026, 1, 1, 12);
      final backend = DemoBackend(timeFactor: 1, now: () => now);
      api = ApiClient(baseUrl: 'https://demo.local/api', tenant: 'berlin', client: backend.client);
    });

    test('Branding und Parkplätze', () async {
      final b = await api.branding();
      expect(b.name, 'Berlin Parking');
      final lots = await api.lots();
      expect(lots.map((l) => l.name), ['Hauptbahnhof', 'Altstadt']);
    });

    test('falsches Passwort und fehlendes Token', () async {
      expect(() => api.login('operator@berlin.test', 'falsch'), throwsA(isA<ApiException>()));
      expect(() => api.activeSessions(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    });

    test('Parken starten und beenden berechnet den Preis', () async {
      await api.login('operator@berlin.test', 'password');
      final s = await api.startSession(1, 'b-ab 123');
      expect(s.licensePlate, 'B-AB 123');
      expect((await api.lots()).first.free, 36);
      expect((await api.activeSessions()).single.id, s.id);

      now = now.add(const Duration(minutes: 70)); // 15 gratis, dann 2 angefangene Stunden
      final done = await api.stopSession(s.id);
      expect(done.amountCents, 600);
      expect((await api.lots()).first.free, 37);
      expect(await api.activeSessions(), isEmpty);
    });

    test('voller Parkplatz liefert 409', () async {
      await api.login('operator@berlin.test', 'password');
      await api.startSession(2, 'A1');
      await api.startSession(2, 'A2');
      expect(() => api.startSession(2, 'A3'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)));
    });
  });
}
