import 'package:flutter/material.dart';
import '../../models/zielmessung.dart';

/// Widget zur GAS-Bewertung (5-Punkte-Skala mit Farbkodierung).
class GasRatingWidget extends StatelessWidget {
  final GasBewertung? value;
  final ValueChanged<GasBewertung>? onChanged;
  final bool readOnly;
  final bool kompakt;

  const GasRatingWidget({
    super.key,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.kompakt = false,
  });

  static Color colorFor(GasBewertung b) {
    switch (b) {
      case GasBewertung.deutlichSchlechter: return const Color(0xFFC62828);
      case GasBewertung.schlechter: return const Color(0xFFEF6C00);
      case GasBewertung.wieErwartet: return const Color(0xFF757575);
      case GasBewertung.besser: return const Color(0xFF7CB342);
      case GasBewertung.deutlichBesser: return const Color(0xFF2E7D32);
    }
  }

  static IconData iconFor(GasBewertung b) {
    switch (b) {
      case GasBewertung.deutlichSchlechter: return Icons.sentiment_very_dissatisfied;
      case GasBewertung.schlechter: return Icons.sentiment_dissatisfied;
      case GasBewertung.wieErwartet: return Icons.sentiment_neutral;
      case GasBewertung.besser: return Icons.sentiment_satisfied;
      case GasBewertung.deutlichBesser: return Icons.sentiment_very_satisfied;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kompakt) {
      return _buildKompakt(context);
    }
    return _buildVoll(context);
  }

  Widget _buildKompakt(BuildContext context) {
    if (value == null) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    final color = colorFor(value!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(value!), color: color, size: 18),
        const SizedBox(width: 4),
        Text('${value!.wert > 0 ? "+" : ""}${value!.wert}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVoll(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: GasBewertung.values.map((b) {
            final selected = value == b;
            final color = colorFor(b);
            return InkWell(
              onTap: readOnly ? null : () => onChanged?.call(b),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : Colors.grey.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconFor(b), color: color, size: 28),
                    const SizedBox(height: 4),
                    Text('${b.wert > 0 ? "+" : ""}${b.wert}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (value != null) ...[
          const SizedBox(height: 8),
          Text(
            value!.kurzBeschreibung,
            style: TextStyle(
              color: colorFor(value!),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
