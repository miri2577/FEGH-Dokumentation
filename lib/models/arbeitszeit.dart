// Arbeitszeit lebt jetzt im geteilten Paket fegh_core (gemeinsames Worktime-
// Modell beider Apps). Diese Datei re-exportiert es und ergaenzt App-seitige
// Helfer: Kompatibilitaets-Getter fuer die frueheren Namen sowie die
// Status-Farben (fegh_core importiert bewusst kein dart:ui).
import 'package:flutter/material.dart';
import 'package:fegh_core/fegh_core.dart';

export 'package:fegh_core/fegh_core.dart'
    show
        Arbeitszeit,
        ArbeitszeitStatus,
        ArbeitszeitTyp,
        ArbeitszeitTaetigkeiten,
        ArbeitszeitStatusDisplay,
        ArbeitszeitTypDisplay;

/// Frueher in der Doku-App verwendete Getter-Namen, delegieren auf fegh_core.
extension ArbeitszeitKompat on Arbeitszeit {
  Duration get arbeitszeit => dauer;
  double get arbeitszeitInStunden => stunden;
  String get formatierteArbeitszeit => formatierteDauer;
}

/// UI-Helfer fuer den Genehmigungsstatus (App-Schicht wegen dart:ui).
class ArbeitszeitUi {
  static Color statusColor(ArbeitszeitStatus status) {
    switch (status) {
      case ArbeitszeitStatus.eingereicht:
        return const Color(0xFFFFA726); // Orange
      case ArbeitszeitStatus.genehmigt:
        return const Color(0xFF66BB6A); // Gruen
      case ArbeitszeitStatus.abgelehnt:
        return const Color(0xFFEF5350); // Rot
      case ArbeitszeitStatus.korrektur:
        return const Color(0xFF42A5F5); // Blau
    }
  }

  static String statusName(ArbeitszeitStatus status) => status.displayName;
}
