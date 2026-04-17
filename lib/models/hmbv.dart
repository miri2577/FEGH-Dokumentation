/// HMBV - Hamburger Manual zur Bedarfsermittlung bei Verbehinderungen.
/// Genutzt in Hamburg (Urheber) und Bremen (adaptiert).
///
/// Struktur: 5 Kernbereiche mit jeweils mehreren Indikatoren.
/// Charakteristisch: starker Fokus auf Unterstuetzungsbedarf-Einstufung
/// (Unterstuetzungsintensitaet-Skala).
enum HMBVBereich {
  /// 1. Selbstversorgung und Pflege
  selbstversorgung,
  /// 2. Wohnen und Gestaltung des Alltags
  wohnen,
  /// 3. Kommunikation und soziale Teilhabe
  kommunikationTeilhabe,
  /// 4. Tagesstruktur, Bildung, Arbeit
  tagesstrukturBildungArbeit,
  /// 5. Gesundheit und Krisenbewaeltigung
  gesundheitKrise,
}

extension HMBVBereichExtension on HMBVBereich {
  String get displayName {
    switch (this) {
      case HMBVBereich.selbstversorgung: return 'Selbstversorgung und Pflege';
      case HMBVBereich.wohnen: return 'Wohnen und Gestaltung des Alltags';
      case HMBVBereich.kommunikationTeilhabe: return 'Kommunikation und soziale Teilhabe';
      case HMBVBereich.tagesstrukturBildungArbeit: return 'Tagesstruktur, Bildung, Arbeit';
      case HMBVBereich.gesundheitKrise: return 'Gesundheit und Krisenbewaeltigung';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case HMBVBereich.selbstversorgung: return 'Koerperpflege, Ernaehrung, Medikamente';
      case HMBVBereich.wohnen: return 'Haushalt, Tagesablauf, Freizeit';
      case HMBVBereich.kommunikationTeilhabe: return 'Kontakte, Beziehungen, Gesellschaft';
      case HMBVBereich.tagesstrukturBildungArbeit: return 'Beschaeftigung, Lernen, Qualifikation';
      case HMBVBereich.gesundheitKrise: return 'Krankheit, Psyche, Krisenintervention';
    }
  }

  /// Kurzform fuer Anzeige/ICF-Verknuepfung.
  String get kurzCode {
    switch (this) {
      case HMBVBereich.selbstversorgung: return 'SP';
      case HMBVBereich.wohnen: return 'WA';
      case HMBVBereich.kommunikationTeilhabe: return 'KT';
      case HMBVBereich.tagesstrukturBildungArbeit: return 'TBA';
      case HMBVBereich.gesundheitKrise: return 'GK';
    }
  }
}

/// HMBV-spezifische Unterstuetzungsintensitaets-Skala.
/// Bedeutung: wie viel Hilfe braucht der Klient in diesem Bereich?
enum HMBVUnterstuetzung {
  keine,       // 0 - keine Unterstuetzung noetig
  gering,      // 1 - geringe Unterstuetzung
  mittel,      // 2 - mittlere Unterstuetzung
  hoch,        // 3 - hohe Unterstuetzung
  sehrHoch,    // 4 - sehr hohe / vollstaendige Unterstuetzung
}

extension HMBVUnterstuetzungExtension on HMBVUnterstuetzung {
  int get wert {
    switch (this) {
      case HMBVUnterstuetzung.keine: return 0;
      case HMBVUnterstuetzung.gering: return 1;
      case HMBVUnterstuetzung.mittel: return 2;
      case HMBVUnterstuetzung.hoch: return 3;
      case HMBVUnterstuetzung.sehrHoch: return 4;
    }
  }

  String get displayName {
    switch (this) {
      case HMBVUnterstuetzung.keine: return '0 - Keine Unterstuetzung';
      case HMBVUnterstuetzung.gering: return '1 - Gering';
      case HMBVUnterstuetzung.mittel: return '2 - Mittel';
      case HMBVUnterstuetzung.hoch: return '3 - Hoch';
      case HMBVUnterstuetzung.sehrHoch: return '4 - Sehr hoch / vollstaendig';
    }
  }
}
