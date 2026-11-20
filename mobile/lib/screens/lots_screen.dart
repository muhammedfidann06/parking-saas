import 'dart:async';

import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../money.dart';
import '../widgets/lot_tile.dart';

// Hauptbildschirm: aktive Parkzeiten oben, Parkplätze darunter.
class LotsScreen extends StatefulWidget {
  final ApiClient api;
  final String title;
  final String currency;
  final Future<void> Function() onLogout;

  const LotsScreen({super.key, required this.api, required this.title, required this.currency, required this.onLogout});

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  List<Lot> _lots = [];
  List<ParkingSession> _active = [];
  bool _loading = true;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Jede Minute neu zeichnen, damit die Parkdauer stimmt.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([widget.api.lots(), widget.api.activeSessions()]);
      setState(() {
        _lots = results[0] as List<Lot>;
        _active = results[1] as List<ParkingSession>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String text) {
    // Nach einem await prüfen wir: Ist der Bildschirm noch da?
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _park(Lot lot) async {
    final plate = await showDialog<String>(context: context, builder: (_) => _PlateDialog(lotName: lot.name));
    if (!mounted || plate == null || plate.trim().isEmpty) return;
    try {
      await widget.api.startSession(lot.id, plate);
      _toast('Parken gestartet: ${lot.name}');
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _stop(ParkingSession s) async {
    try {
      final done = await widget.api.stopSession(s.id);
      _toast('Danke! Preis: ${formatMoney(done.amountCents ?? 0, widget.currency)}');
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  String _lotName(int id) => _lots.where((l) => l.id == id).map((l) => l.name).firstOrNull ?? 'Parkplatz';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout), tooltip: 'Abmelden')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (_error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(leading: const Icon(Icons.error_outline), title: Text(_error!)),
                    ),
                  for (final s in _active)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.timer),
                        title: Text('${s.licensePlate} · ${_lotName(s.lotId)}'),
                        subtitle: Text('parkt seit ${formatDuration(DateTime.now().difference(s.startedAt))}'),
                        trailing: FilledButton.tonal(onPressed: () => _stop(s), child: const Text('Beenden')),
                      ),
                    ),
                  for (final lot in _lots) LotTile(lot: lot, currency: widget.currency, onPark: () => _park(lot)),
                  if (_lots.isEmpty && _error == null)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Noch keine Parkplätze.'))),
                ],
              ),
            ),
    );
  }
}

// Dialog für das Kennzeichen.
class _PlateDialog extends StatefulWidget {
  final String lotName;
  const _PlateDialog({required this.lotName});

  @override
  State<_PlateDialog> createState() => _PlateDialogState();
}

class _PlateDialogState extends State<_PlateDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Parken: ${widget.lotName}'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Kennzeichen', hintText: 'z.B. L-123 AB'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Starten')),
      ],
    );
  }
}
