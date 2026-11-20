import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

// Fehler vom Server mit einer lesbaren Nachricht.
class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);

  @override
  String toString() => message;
}

/// Kleiner Client für die Laravel-API.
/// Der http.Client kommt von außen. So können wir im Test einen MockClient benutzen.
class ApiClient {
  final String baseUrl; // z.B. "http://10.0.2.2:8000/api" im Android-Emulator
  final String tenant;
  final http.Client _http;
  String? token;

  ApiClient({required this.baseUrl, required this.tenant, http.Client? client, this.token})
      : _http = client ?? http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Tenant': tenant, // Der Tenant geht in jeden Request.
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) req.body = jsonEncode(body);

    final res = await http.Response.fromStream(await _http.send(req));
    final data = res.body.isEmpty ? null : jsonDecode(res.body);

    if (res.statusCode >= 400) {
      final msg = data is Map && data['message'] is String ? data['message'] as String : 'Fehler ${res.statusCode}';
      throw ApiException(res.statusCode, msg);
    }
    return data;
  }

  Future<Branding> branding() async => Branding.fromJson(await _send('GET', '/branding') as Map<String, dynamic>);

  Future<List<Lot>> lots() async {
    final list = await _send('GET', '/lots') as List<dynamic>;
    return list.map((e) => Lot.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Nach dem Login merken wir uns das Token.
  Future<String> login(String email, String password) async {
    final data = await _send('POST', '/login', {
      'email': email,
      'password': password,
      'device_name': 'flutter',
    }) as Map<String, dynamic>;
    token = data['token'] as String;
    return token!;
  }

  Future<void> logout() async {
    await _send('POST', '/logout');
    token = null;
  }

  Future<List<ParkingSession>> activeSessions() async {
    final list = await _send('GET', '/sessions/active') as List<dynamic>;
    return list.map((e) => ParkingSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ParkingSession> startSession(int lotId, String plate) async => ParkingSession.fromJson(
      await _send('POST', '/sessions', {'parking_lot_id': lotId, 'license_plate': plate}) as Map<String, dynamic>);

  Future<ParkingSession> stopSession(int id) async =>
      ParkingSession.fromJson(await _send('POST', '/sessions/$id/stop') as Map<String, dynamic>);
}
