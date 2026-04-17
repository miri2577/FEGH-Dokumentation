/// Generische 9 ICF-Lebensbereiche (d1-d9) fuer Bundeslaender ohne
/// oeffentlich dokumentiertes strukturiertes Instrument.
/// Verwendet von: Bayern (Gesamtplan), Schleswig-Holstein (PerSEH-SH),
/// Rheinland-Pfalz (Teilhabe-RLP), Saarland (SBI).
enum GenerischIcfLebensbereich {
  lernenWissen,
  allgemeineAufgaben,
  kommunikation,
  mobilitaet,
  selbstversorgung,
  haeuslichesLeben,
  interpersonell,
  bildungArbeit,
  gemeinschaftsleben,
}

extension GenerischIcfLebensbereichExtension on GenerischIcfLebensbereich {
  String get icfCode {
    switch (this) {
      case GenerischIcfLebensbereich.lernenWissen: return 'd1';
      case GenerischIcfLebensbereich.allgemeineAufgaben: return 'd2';
      case GenerischIcfLebensbereich.kommunikation: return 'd3';
      case GenerischIcfLebensbereich.mobilitaet: return 'd4';
      case GenerischIcfLebensbereich.selbstversorgung: return 'd5';
      case GenerischIcfLebensbereich.haeuslichesLeben: return 'd6';
      case GenerischIcfLebensbereich.interpersonell: return 'd7';
      case GenerischIcfLebensbereich.bildungArbeit: return 'd8';
      case GenerischIcfLebensbereich.gemeinschaftsleben: return 'd9';
    }
  }

  String get displayName {
    switch (this) {
      case GenerischIcfLebensbereich.lernenWissen: return 'Lernen und Wissensanwendung';
      case GenerischIcfLebensbereich.allgemeineAufgaben: return 'Allgemeine Aufgaben und Anforderungen';
      case GenerischIcfLebensbereich.kommunikation: return 'Kommunikation';
      case GenerischIcfLebensbereich.mobilitaet: return 'Mobilitaet';
      case GenerischIcfLebensbereich.selbstversorgung: return 'Selbstversorgung';
      case GenerischIcfLebensbereich.haeuslichesLeben: return 'Haeusliches Leben';
      case GenerischIcfLebensbereich.interpersonell: return 'Interpersonelle Interaktionen und Beziehungen';
      case GenerischIcfLebensbereich.bildungArbeit: return 'Bildung, Arbeit, Wirtschaftsleben';
      case GenerischIcfLebensbereich.gemeinschaftsleben: return 'Gemeinschafts-, soziales und staatsbuergerliches Leben';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case GenerischIcfLebensbereich.lernenWissen: return 'Wissen, Lernen, Entscheidungen';
      case GenerischIcfLebensbereich.allgemeineAufgaben: return 'Struktur, Verantwortung, Stress';
      case GenerischIcfLebensbereich.kommunikation: return 'Sprechen, Verstehen, Schreiben';
      case GenerischIcfLebensbereich.mobilitaet: return 'Bewegung, Verkehr';
      case GenerischIcfLebensbereich.selbstversorgung: return 'Pflege, Ernaehrung, Gesundheit';
      case GenerischIcfLebensbereich.haeuslichesLeben: return 'Wohnen, Haushalt, Einkaufen';
      case GenerischIcfLebensbereich.interpersonell: return 'Beziehungen, Kontakte';
      case GenerischIcfLebensbereich.bildungArbeit: return 'Schule, Ausbildung, Arbeit';
      case GenerischIcfLebensbereich.gemeinschaftsleben: return 'Freizeit, Gemeinde, Politik, Religion';
    }
  }
}
