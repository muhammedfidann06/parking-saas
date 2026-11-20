import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking_mobile/models.dart';
import 'package:parking_mobile/widgets/lot_tile.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('LotTile zeigt Name, freie Plätze und Preis', (tester) async {
    const lot = Lot(id: 1, name: 'Altstadt', capacity: 40, free: 12, hourlyRateCents: 450, freeMinutes: 15, dailyCapCents: 2400);
    var tapped = false;

    await tester.pumpWidget(_wrap(LotTile(lot: lot, currency: 'EUR', onPark: () => tapped = true)));

    expect(find.text('Altstadt'), findsOneWidget);
    expect(find.text('12 / 40 frei'), findsOneWidget);
    expect(find.textContaining('4,50 € / h'), findsOneWidget);
    expect(find.textContaining('15 Min. gratis'), findsOneWidget);

    await tester.tap(find.text('Parken'));
    expect(tapped, isTrue);
  });

  testWidgets('Button ist deaktiviert, wenn der Parkplatz voll ist', (tester) async {
    const lot = Lot(id: 2, name: 'Voll', capacity: 5, free: 0, hourlyRateCents: 100, freeMinutes: 0);

    await tester.pumpWidget(_wrap(LotTile(lot: lot, currency: 'EUR', onPark: () {})));

    final button = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Parken'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
    expect(button.onPressed, isNull);
  });
}
