// Cent -> schöner Preis im deutschen Format, z.B. 350 -> "3,50 €".
String formatMoney(int cents, [String currency = 'EUR']) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = abs ~/ 100;
  final rest = (abs % 100).toString().padLeft(2, '0');

  // Tausender-Punkt: 1234 -> "1.234"
  final digits = euros.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }

  final symbol = currency == 'EUR' ? '€' : currency;
  return '${negative ? '-' : ''}$buf,$rest $symbol';
}

// Wie lange parkt das Auto schon? z.B. "1 h 05 min"
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h h $m min' : '${d.inMinutes} min';
}
