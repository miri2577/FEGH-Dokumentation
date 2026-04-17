/// BEI_NRW - Bedarfsermittlungsinstrument Nordrhein-Westfalen.
/// ICF-basiert, 9 Lebensbereiche analog zu ICF-Komponenten
/// "Aktivitaeten und Teilhabe".
///
/// Quelle: LVR/LWL, Version 2022, LRV NRW.
enum BEINRWLebensbereich {
  /// 1. Lernen und Wissensanwendung (d1)
  lernenWissensanwendung,

  /// 2. Allgemeine Aufgaben und Anforderungen (d2)
  allgemeineAufgabenAnforderungen,

  /// 3. Kommunikation (d3)
  kommunikation,

  /// 4. Mobilitaet (d4)
  mobilitaet,

  /// 5. Selbstversorgung (d5)
  selbstversorgung,

  /// 6. Haeusliches Leben (d6)
  haeuslichesLeben,

  /// 7. Interpersonelle Interaktionen und Beziehungen (d7)
  interpersonelleInteraktionen,

  /// 8. Bedeutende Lebensbereiche (d8)
  bedeutendeLebensbereiche,

  /// 9. Gemeinschafts-, soziales und staatsbuergerliches Leben (d9)
  gemeinschaftsleben,
}

extension BEINRWLebensbereichExtension on BEINRWLebensbereich {
  String get icfCode {
    switch (this) {
      case BEINRWLebensbereich.lernenWissensanwendung: return 'd1';
      case BEINRWLebensbereich.allgemeineAufgabenAnforderungen: return 'd2';
      case BEINRWLebensbereich.kommunikation: return 'd3';
      case BEINRWLebensbereich.mobilitaet: return 'd4';
      case BEINRWLebensbereich.selbstversorgung: return 'd5';
      case BEINRWLebensbereich.haeuslichesLeben: return 'd6';
      case BEINRWLebensbereich.interpersonelleInteraktionen: return 'd7';
      case BEINRWLebensbereich.bedeutendeLebensbereiche: return 'd8';
      case BEINRWLebensbereich.gemeinschaftsleben: return 'd9';
    }
  }

  String get displayName {
    switch (this) {
      case BEINRWLebensbereich.lernenWissensanwendung:
        return 'Lernen und Wissensanwendung';
      case BEINRWLebensbereich.allgemeineAufgabenAnforderungen:
        return 'Allgemeine Aufgaben und Anforderungen';
      case BEINRWLebensbereich.kommunikation:
        return 'Kommunikation';
      case BEINRWLebensbereich.mobilitaet:
        return 'Mobilitaet';
      case BEINRWLebensbereich.selbstversorgung:
        return 'Selbstversorgung';
      case BEINRWLebensbereich.haeuslichesLeben:
        return 'Haeusliches Leben';
      case BEINRWLebensbereich.interpersonelleInteraktionen:
        return 'Interpersonelle Interaktionen und Beziehungen';
      case BEINRWLebensbereich.bedeutendeLebensbereiche:
        return 'Bedeutende Lebensbereiche';
      case BEINRWLebensbereich.gemeinschaftsleben:
        return 'Gemeinschafts-, soziales und staatsbuergerliches Leben';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case BEINRWLebensbereich.lernenWissensanwendung:
        return 'Lernen, Problemloesen, Entscheidungen treffen';
      case BEINRWLebensbereich.allgemeineAufgabenAnforderungen:
        return 'Tagesablauf, Verantwortung, Stressbewaeltigung';
      case BEINRWLebensbereich.kommunikation:
        return 'Verstehen, Sprechen, Lesen, Schreiben';
      case BEINRWLebensbereich.mobilitaet:
        return 'Fortbewegung, Transport, Geraete handhaben';
      case BEINRWLebensbereich.selbstversorgung:
        return 'Koerperpflege, Gesundheit, Ernaehrung';
      case BEINRWLebensbereich.haeuslichesLeben:
        return 'Wohnung, Hausarbeit, Einkaufen';
      case BEINRWLebensbereich.interpersonelleInteraktionen:
        return 'Beziehungen, soziale Interaktionen';
      case BEINRWLebensbereich.bedeutendeLebensbereiche:
        return 'Bildung, Arbeit, Wirtschaftsleben';
      case BEINRWLebensbereich.gemeinschaftsleben:
        return 'Gemeinschaft, Freizeit, Religion, Politik';
    }
  }
}
