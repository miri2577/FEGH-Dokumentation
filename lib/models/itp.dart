/// ITP - Integrierter Teilhabeplan.
/// Genutzt in Hessen (Urheber), Brandenburg, Mecklenburg-Vorpommern,
/// Sachsen, Sachsen-Anhalt, Thueringen.
///
/// Struktur: 9 Lebensbereiche nach ICF (d1-d9), analog zu BEI_NRW,
/// jedoch mit zusaetzlichen Freitext-Zielfeldern und Leistungsbausteinen.
enum ITPLebensbereich {
  /// 1. Lernen und Wissensanwendung (d1)
  lernen,
  /// 2. Allgemeine Aufgaben und Anforderungen (d2)
  allgemeineAufgaben,
  /// 3. Kommunikation (d3)
  kommunikation,
  /// 4. Mobilitaet (d4)
  mobilitaet,
  /// 5. Selbstversorgung (d5)
  selbstversorgung,
  /// 6. Haeusliches Leben (d6)
  haeuslichesLeben,
  /// 7. Interpersonelle Interaktionen (d7)
  interpersonell,
  /// 8. Bedeutende Lebensbereiche (d8)
  bedeutende,
  /// 9. Gemeinschafts-, soziales und staatsbuergerliches Leben (d9)
  gemeinschaft,
}

extension ITPLebensbereichExtension on ITPLebensbereich {
  String get icfCode {
    switch (this) {
      case ITPLebensbereich.lernen: return 'd1';
      case ITPLebensbereich.allgemeineAufgaben: return 'd2';
      case ITPLebensbereich.kommunikation: return 'd3';
      case ITPLebensbereich.mobilitaet: return 'd4';
      case ITPLebensbereich.selbstversorgung: return 'd5';
      case ITPLebensbereich.haeuslichesLeben: return 'd6';
      case ITPLebensbereich.interpersonell: return 'd7';
      case ITPLebensbereich.bedeutende: return 'd8';
      case ITPLebensbereich.gemeinschaft: return 'd9';
    }
  }

  String get displayName {
    switch (this) {
      case ITPLebensbereich.lernen: return 'Lernen und Wissensanwendung';
      case ITPLebensbereich.allgemeineAufgaben: return 'Allgemeine Aufgaben und Anforderungen';
      case ITPLebensbereich.kommunikation: return 'Kommunikation';
      case ITPLebensbereich.mobilitaet: return 'Mobilitaet';
      case ITPLebensbereich.selbstversorgung: return 'Selbstversorgung';
      case ITPLebensbereich.haeuslichesLeben: return 'Haeusliches Leben';
      case ITPLebensbereich.interpersonell: return 'Interpersonelle Interaktionen';
      case ITPLebensbereich.bedeutende: return 'Bedeutende Lebensbereiche';
      case ITPLebensbereich.gemeinschaft: return 'Gemeinschafts-, soziales und staatsbuergerliches Leben';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case ITPLebensbereich.lernen: return 'Lernen, Problemloesen, Entscheidungen';
      case ITPLebensbereich.allgemeineAufgaben: return 'Tagesablauf, Verantwortung, Stress';
      case ITPLebensbereich.kommunikation: return 'Verstehen, Sprechen, Lesen, Schreiben';
      case ITPLebensbereich.mobilitaet: return 'Fortbewegung, Transport';
      case ITPLebensbereich.selbstversorgung: return 'Koerperpflege, Gesundheit, Ernaehrung';
      case ITPLebensbereich.haeuslichesLeben: return 'Wohnung, Hausarbeit, Einkaufen';
      case ITPLebensbereich.interpersonell: return 'Beziehungen, soziale Interaktionen';
      case ITPLebensbereich.bedeutende: return 'Bildung, Arbeit, Wirtschaftsleben';
      case ITPLebensbereich.gemeinschaft: return 'Gemeinde, Freizeit, Politik, Religion';
    }
  }
}
