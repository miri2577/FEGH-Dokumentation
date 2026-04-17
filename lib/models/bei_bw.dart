/// BEI_BW - Bedarfsermittlungsinstrument Baden-Wuerttemberg.
/// Einheitliches Instrument fuer die Stadt- und Landkreise in BW.
/// Basis KVJS, ICF-orientiert, 9 Lebensbereiche.
///
/// LRV-Neuverhandlung 2025-2026, Wirksamkeit zentrales Thema.
enum BEIBWLebensbereich {
  /// 1. Lernen und Anwenden von Wissen (d1)
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
  /// 7. Interpersonelle Interaktionen und Beziehungen (d7)
  interpersonell,
  /// 8. Bedeutende Lebensbereiche (d8)
  bildungArbeit,
  /// 9. Gemeinschafts-, soziales und staatsbuergerliches Leben (d9)
  gemeinschaftsleben,
}

extension BEIBWLebensbereichExtension on BEIBWLebensbereich {
  String get icfCode {
    switch (this) {
      case BEIBWLebensbereich.lernen: return 'd1';
      case BEIBWLebensbereich.allgemeineAufgaben: return 'd2';
      case BEIBWLebensbereich.kommunikation: return 'd3';
      case BEIBWLebensbereich.mobilitaet: return 'd4';
      case BEIBWLebensbereich.selbstversorgung: return 'd5';
      case BEIBWLebensbereich.haeuslichesLeben: return 'd6';
      case BEIBWLebensbereich.interpersonell: return 'd7';
      case BEIBWLebensbereich.bildungArbeit: return 'd8';
      case BEIBWLebensbereich.gemeinschaftsleben: return 'd9';
    }
  }

  String get displayName {
    switch (this) {
      case BEIBWLebensbereich.lernen: return 'Lernen und Anwenden von Wissen';
      case BEIBWLebensbereich.allgemeineAufgaben: return 'Allgemeine Aufgaben und Anforderungen';
      case BEIBWLebensbereich.kommunikation: return 'Kommunikation';
      case BEIBWLebensbereich.mobilitaet: return 'Mobilitaet';
      case BEIBWLebensbereich.selbstversorgung: return 'Selbstversorgung';
      case BEIBWLebensbereich.haeuslichesLeben: return 'Haeusliches Leben';
      case BEIBWLebensbereich.interpersonell: return 'Interpersonelle Interaktionen und Beziehungen';
      case BEIBWLebensbereich.bildungArbeit: return 'Bedeutende Lebensbereiche';
      case BEIBWLebensbereich.gemeinschaftsleben: return 'Gemeinschafts-, soziales und staatsbuergerliches Leben';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case BEIBWLebensbereich.lernen: return 'Wissen erwerben, anwenden, Problem loesen';
      case BEIBWLebensbereich.allgemeineAufgaben: return 'Routinen, Zeit- und Stressmanagement';
      case BEIBWLebensbereich.kommunikation: return 'Sprache, Schrift, Austausch';
      case BEIBWLebensbereich.mobilitaet: return 'Fortbewegung im Nah- und Fernverkehr';
      case BEIBWLebensbereich.selbstversorgung: return 'Pflege, Ernaehrung, Gesundheit';
      case BEIBWLebensbereich.haeuslichesLeben: return 'Wohnen, Einkaufen, Haushalt';
      case BEIBWLebensbereich.interpersonell: return 'Beziehungen, Familie, Partnerschaft';
      case BEIBWLebensbereich.bildungArbeit: return 'Schule, Ausbildung, Beruf';
      case BEIBWLebensbereich.gemeinschaftsleben: return 'Gemeinde, Freizeit, Religion, Politik';
    }
  }
}
