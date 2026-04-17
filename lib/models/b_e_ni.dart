/// B.E.Ni - Bedarfsermittlung Niedersachsen.
/// Niedersaechsisches Instrument zur Bedarfsermittlung in der
/// Eingliederungshilfe. Rahmenvertrag 2024/25 mit Wirksamkeitsklausel.
///
/// Struktur: 9 Lebensbereiche angelehnt an ICF, aber mit eigenem
/// Fragebogen-Design und 5-stufiger Bedarfs-Skala.
enum BENiLebensbereich {
  /// 1. Lernen und Wissensanwendung
  lernenWissen,
  /// 2. Allgemeine Aufgaben und Anforderungen
  allgemeineAufgaben,
  /// 3. Kommunikation
  kommunikation,
  /// 4. Mobilitaet
  mobilitaet,
  /// 5. Selbstversorgung
  selbstversorgung,
  /// 6. Haeusliches Leben
  haeuslichesLeben,
  /// 7. Interpersonelle Interaktionen und Beziehungen
  interpersonell,
  /// 8. Bedeutende Lebensbereiche (Bildung, Arbeit)
  bildungArbeit,
  /// 9. Gemeinschafts-, soziales und staatsbuergerliches Leben
  gemeinschaft,
}

extension BENiLebensbereichExtension on BENiLebensbereich {
  String get icfCode {
    switch (this) {
      case BENiLebensbereich.lernenWissen: return 'd1';
      case BENiLebensbereich.allgemeineAufgaben: return 'd2';
      case BENiLebensbereich.kommunikation: return 'd3';
      case BENiLebensbereich.mobilitaet: return 'd4';
      case BENiLebensbereich.selbstversorgung: return 'd5';
      case BENiLebensbereich.haeuslichesLeben: return 'd6';
      case BENiLebensbereich.interpersonell: return 'd7';
      case BENiLebensbereich.bildungArbeit: return 'd8';
      case BENiLebensbereich.gemeinschaft: return 'd9';
    }
  }

  String get displayName {
    switch (this) {
      case BENiLebensbereich.lernenWissen: return 'Lernen und Wissensanwendung';
      case BENiLebensbereich.allgemeineAufgaben: return 'Allgemeine Aufgaben und Anforderungen';
      case BENiLebensbereich.kommunikation: return 'Kommunikation';
      case BENiLebensbereich.mobilitaet: return 'Mobilitaet';
      case BENiLebensbereich.selbstversorgung: return 'Selbstversorgung';
      case BENiLebensbereich.haeuslichesLeben: return 'Haeusliches Leben';
      case BENiLebensbereich.interpersonell: return 'Interpersonelle Interaktionen und Beziehungen';
      case BENiLebensbereich.bildungArbeit: return 'Bedeutende Lebensbereiche (Bildung, Arbeit)';
      case BENiLebensbereich.gemeinschaft: return 'Gemeinschafts-, soziales und staatsbuergerliches Leben';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case BENiLebensbereich.lernenWissen: return 'Lernen, Problemloesen';
      case BENiLebensbereich.allgemeineAufgaben: return 'Tagesablauf, Struktur';
      case BENiLebensbereich.kommunikation: return 'Sprache, Schrift, Austausch';
      case BENiLebensbereich.mobilitaet: return 'Fortbewegung, Transport';
      case BENiLebensbereich.selbstversorgung: return 'Pflege, Gesundheit, Essen';
      case BENiLebensbereich.haeuslichesLeben: return 'Wohnung, Haushalt, Einkauf';
      case BENiLebensbereich.interpersonell: return 'Beziehungen, Kontakte';
      case BENiLebensbereich.bildungArbeit: return 'Schule, Ausbildung, Arbeit';
      case BENiLebensbereich.gemeinschaft: return 'Freizeit, Gemeinde, Politik';
    }
  }
}
