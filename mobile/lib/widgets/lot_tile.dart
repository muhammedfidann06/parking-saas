import 'package:flutter/material.dart';

import '../models.dart';
import '../money.dart';

// Eine Karte für einen Parkplatz mit Auslastung und Preis.
class LotTile extends StatelessWidget {
  final Lot lot;
  final String currency;
  final VoidCallback? onPark;

  const LotTile({super.key, required this.lot, required this.currency, this.onPark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Farbe für die Auslastung: grün, orange oder rot.
    final color = lot.free == 0
        ? scheme.error
        : lot.occupancy > 0.7
            ? Colors.orange
            : Colors.green;

    final price = StringBuffer('${formatMoney(lot.hourlyRateCents, currency)} / h');
    if (lot.freeMinutes > 0) price.write(' · ${lot.freeMinutes} Min. gratis');
    if (lot.dailyCapCents != null) price.write(' · max. ${formatMoney(lot.dailyCapCents!, currency)}/Tag');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(lot.name, style: Theme.of(context).textTheme.titleMedium)),
                Chip(
                  label: Text('${lot.free} / ${lot.capacity} frei'),
                  backgroundColor: color.withValues(alpha: 0.15),
                  side: BorderSide(color: color),
                ),
              ],
            ),
            if (lot.address != null) Text(lot.address!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: lot.occupancy, color: color),
            const SizedBox(height: 8),
            Text(price.toString()),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: lot.free == 0 ? null : onPark,
                icon: const Icon(Icons.directions_car),
                label: const Text('Parken'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
