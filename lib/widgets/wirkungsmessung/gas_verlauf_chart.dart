import 'package:flutter/material.dart';
import '../../models/zielmessung.dart';
import 'gas_rating_widget.dart';

/// Liniendiagramm fuer GAS-Verlauf eines Ziels ueber die Zeit.
class GasVerlaufChart extends StatelessWidget {
  final List<Zielmessung> messungen;
  final double height;

  const GasVerlaufChart({
    super.key,
    required this.messungen,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (messungen.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Keine Messungen vorhanden',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
      );
    }
    final sorted = List<Zielmessung>.from(messungen)
      ..sort((a, b) => a.messdatum.compareTo(b.messdatum));
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _GasChartPainter(sorted, Theme.of(context)),
        size: Size.infinite,
      ),
    );
  }
}

class _GasChartPainter extends CustomPainter {
  final List<Zielmessung> messungen;
  final ThemeData theme;

  _GasChartPainter(this.messungen, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 40.0;
    const padR = 12.0;
    const padT = 12.0;
    const padB = 28.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    final axis = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final grid = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Y-Achse: -2 bis +2 (5 Linien)
    for (int i = 0; i <= 4; i++) {
      final y = padT + (h / 4) * i;
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), grid);
      final label = '${2 - i > 0 ? "+" : ""}${2 - i}';
      _drawText(canvas, label, Offset(padL - 8, y), align: TextAlign.right, y0: y - 7);
    }
    // Y-Achse
    canvas.drawLine(Offset(padL, padT), Offset(padL, padT + h), axis);
    // Null-Linie betont
    final zeroY = padT + (h / 4) * 2;
    canvas.drawLine(
      Offset(padL, zeroY),
      Offset(padL + w, zeroY),
      Paint()
        ..color = theme.colorScheme.outline.withValues(alpha: 0.5)
        ..strokeWidth = 1.2,
    );

    // X-Positionen fuer die Messungen
    final n = messungen.length;
    final xStep = n == 1 ? 0.0 : w / (n - 1);
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final m = messungen[i];
      final x = padL + (n == 1 ? w / 2 : xStep * i);
      // Wertebereich -2..+2 → y
      final valNorm = (2 - m.bewertung.wert) / 4.0; // 0 oben, 1 unten
      final y = padT + valNorm * h;
      points.add(Offset(x, y));
    }

    // Linie
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = theme.colorScheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], linePaint);
      }
    }

    // Punkte
    for (int i = 0; i < points.length; i++) {
      final m = messungen[i];
      final color = GasRatingWidget.colorFor(m.bewertung);
      canvas.drawCircle(points[i], 6, Paint()..color = color);
      canvas.drawCircle(
        points[i],
        6,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // X-Achse Beschriftung (erste, letzte, ggf. mittlere)
    void drawDate(int i) {
      if (i < 0 || i >= n) return;
      final m = messungen[i];
      final x = points[i].dx;
      final label =
          '${m.messdatum.day.toString().padLeft(2, '0')}.${m.messdatum.month.toString().padLeft(2, '0')}.${m.messdatum.year.toString().substring(2)}';
      _drawText(canvas, label, Offset(x, padT + h + 4), align: TextAlign.center);
    }

    drawDate(0);
    if (n > 2) drawDate(n ~/ 2);
    if (n > 1) drawDate(n - 1);
  }

  void _drawText(Canvas canvas, String text, Offset pos,
      {TextAlign align = TextAlign.center, double? y0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 10),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    double dx;
    switch (align) {
      case TextAlign.right:
        dx = pos.dx - tp.width;
        break;
      case TextAlign.center:
        dx = pos.dx - tp.width / 2;
        break;
      default:
        dx = pos.dx;
    }
    tp.paint(canvas, Offset(dx, y0 ?? pos.dy));
  }

  @override
  bool shouldRepaint(covariant _GasChartPainter old) =>
      old.messungen != messungen;
}
