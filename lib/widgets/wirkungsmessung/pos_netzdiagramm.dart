import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/pos_messung.dart';

/// Netzdiagramm (Spider/Radar) fuer POS mit 8 Domaenen.
/// Optional: zweite Messung zum Vergleich (Baseline vs. aktuelle).
class PosNetzdiagramm extends StatelessWidget {
  final PosMessung messung;
  final PosMessung? vergleich; // optional: Vorher/Nachher
  final double size;
  final bool showLabels;

  const PosNetzdiagramm({
    super.key,
    required this.messung,
    this.vergleich,
    this.size = 300,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NetzPainter(
          messung: messung,
          vergleich: vergleich,
          theme: Theme.of(context),
          showLabels: showLabels,
        ),
        size: Size.square(size),
      ),
    );
  }
}

class _NetzPainter extends CustomPainter {
  final PosMessung messung;
  final PosMessung? vergleich;
  final ThemeData theme;
  final bool showLabels;

  _NetzPainter({
    required this.messung,
    required this.vergleich,
    required this.theme,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - (showLabels ? 60 : 10);
    final domaenen = PosDomaene.values;
    final n = domaenen.length;
    final anglePerSlice = 2 * math.pi / n;
    // Start ganz oben
    final startAngle = -math.pi / 2;

    // Gitter (4 Ringe = 25/50/75/100%)
    final gridPaint = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int r = 1; r <= 4; r++) {
      final rr = radius * r / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = startAngle + anglePerSlice * i;
        final x = center.dx + rr * math.cos(angle);
        final y = center.dy + rr * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Speichen + Labels
    for (int i = 0; i < n; i++) {
      final angle = startAngle + anglePerSlice * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      if (showLabels) {
        final lx = center.dx + (radius + 20) * math.cos(angle);
        final ly = center.dy + (radius + 20) * math.sin(angle);
        final prozent = messung.domaeneProzent(domaenen[i]);
        final label = '${_kurzName(domaenen[i])}\n${prozent.toStringAsFixed(0)}%';
        _drawLabel(canvas, label, Offset(lx, ly));
      }
    }

    // Vergleich (falls vorhanden) - hinter der aktuellen
    if (vergleich != null) {
      _drawPolygon(
        canvas,
        center,
        radius,
        startAngle,
        anglePerSlice,
        domaenen,
        vergleich!,
        fill: theme.colorScheme.outline.withValues(alpha: 0.18),
        stroke: theme.colorScheme.outline.withValues(alpha: 0.7),
      );
    }

    // Aktuelle Messung
    _drawPolygon(
      canvas,
      center,
      radius,
      startAngle,
      anglePerSlice,
      domaenen,
      messung,
      fill: theme.colorScheme.primary.withValues(alpha: 0.25),
      stroke: theme.colorScheme.primary,
      drawPoints: true,
    );
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double anglePerSlice,
    List<PosDomaene> domaenen,
    PosMessung m, {
    required Color fill,
    required Color stroke,
    bool drawPoints = false,
  }) {
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < domaenen.length; i++) {
      final angle = startAngle + anglePerSlice * i;
      final p = m.domaeneProzent(domaenen[i]) / 100.0;
      final r = radius * p;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    if (drawPoints) {
      for (final p in points) {
        canvas.drawCircle(p, 3.5, Paint()..color = stroke);
      }
    }
  }

  String _kurzName(PosDomaene d) {
    switch (d) {
      case PosDomaene.selbstbestimmung: return 'Selbst-\nbestimmung';
      case PosDomaene.sozialeTeilhabe: return 'Soziale\nTeilhabe';
      case PosDomaene.interpersonelleBeziehungen: return 'Beziehungen';
      case PosDomaene.rechte: return 'Rechte';
      case PosDomaene.emotionalesWohlbefinden: return 'Emotional';
      case PosDomaene.physischesWohlbefinden: return 'Physisch';
      case PosDomaene.materiellesWohlbefinden: return 'Materiell';
      case PosDomaene.persoenlicheEntwicklung: return 'Entwicklung';
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 9,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: 80);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NetzPainter old) =>
      old.messung != messung || old.vergleich != vergleich;
}
