import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'demo_backend.dart';
import 'models.dart';
import 'screens/login_screen.dart';
import 'screens/lots_screen.dart';

// Konfiguration beim Start, z.B.:
// flutter run --dart-define=API_URL=http://10.0.2.2:8000/api --dart-define=TENANT=berlin
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api');
const tenantSlug = String.fromEnvironment('TENANT', defaultValue: 'berlin');
// Live-Demo ohne Server: flutter build web --dart-define=DEMO=true
const demoMode = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(
    baseUrl: demoMode ? 'https://demo.local/api' : apiUrl,
    tenant: tenantSlug,
    // Im Demo-Modus beantwortet ein Fake-Backend im Browser alle Requests.
    client: demoMode ? DemoBackend().client : null,
    token: prefs.getString('token'),
  );

  // White-Label: Name und Farbe kommen vom Server. Wenn der Server nicht da ist, nehmen wir Standardwerte.
  Branding? branding;
  try {
    branding = await api.branding();
  } catch (_) {
    branding = null;
  }

  runApp(ParkingApp(api: api, prefs: prefs, branding: branding));
}

class ParkingApp extends StatefulWidget {
  final ApiClient api;
  final SharedPreferences prefs;
  final Branding? branding;

  const ParkingApp({super.key, required this.api, required this.prefs, this.branding});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> {
  late bool _loggedIn = widget.api.token != null;

  Future<void> _onLogin(String token) async {
    await widget.prefs.setString('token', token);
    setState(() => _loggedIn = true);
  }

  Future<void> _onLogout() async {
    try {
      await widget.api.logout();
    } catch (_) {
      // Auch wenn der Server nicht antwortet: lokal abmelden.
      widget.api.token = null;
    }
    await widget.prefs.remove('token');
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.branding;
    final seed = Color(b?.colorValue ?? 0xFF2563EB);

    return MaterialApp(
      title: b?.name ?? 'Parking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: _loggedIn
          ? LotsScreen(api: widget.api, title: b?.name ?? 'Parking', currency: b?.currency ?? 'EUR', onLogout: _onLogout)
          : LoginScreen(
              api: widget.api,
              title: b?.name ?? 'Parking',
              onLogin: _onLogin,
              hint: demoMode
                  ? 'Live-Demo ohne Server – Login: operator@$tenantSlug.test / password. '
                      'Alle Daten bleiben im Browser; beim Preis zählt 1 Sekunde wie 1 Minute.'
                  : null,
            ),
    );
  }
}
