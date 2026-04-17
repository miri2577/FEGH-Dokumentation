import 'package:json_annotation/json_annotation.dart';

/// Die 16 deutschen Bundeslaender.
/// Das gewaehlte Bundesland steuert laenderspezifische Profile:
/// Bedarfsinstrument, Formulare, Wirksamkeitsverfahren etc.
enum Bundesland {
  @JsonValue('baden-wuerttemberg')
  badenWuerttemberg,
  @JsonValue('bayern')
  bayern,
  @JsonValue('berlin')
  berlin,
  @JsonValue('brandenburg')
  brandenburg,
  @JsonValue('bremen')
  bremen,
  @JsonValue('hamburg')
  hamburg,
  @JsonValue('hessen')
  hessen,
  @JsonValue('mecklenburg-vorpommern')
  mecklenburgVorpommern,
  @JsonValue('niedersachsen')
  niedersachsen,
  @JsonValue('nordrhein-westfalen')
  nordrheinWestfalen,
  @JsonValue('rheinland-pfalz')
  rheinlandPfalz,
  @JsonValue('saarland')
  saarland,
  @JsonValue('sachsen')
  sachsen,
  @JsonValue('sachsen-anhalt')
  sachsenAnhalt,
  @JsonValue('schleswig-holstein')
  schleswigHolstein,
  @JsonValue('thueringen')
  thueringen,
}

/// Bedarfserhebungsinstrument pro Bundesland.
enum Bedarfsinstrument {
  tib,          // Teilhabe-Instrument Berlin
  beiNrw,       // BEI_NRW (Nordrhein-Westfalen)
  beiBw,        // BEI_BW (Baden-Wuerttemberg)
  beiSh,        // BEI_SH (Schleswig-Holstein)
  itp,          // Integrierter Teilhabeplan (HE, BB, MV, SN, ST, TH)
  hmbv,         // Hamburger Manual (HH, HB)
  bEni,         // B.E.Ni (Niedersachsen)
  perseh,       // PerSEH (RLP, SH)
  bayerischGesamtplan,
  sbi,          // Saarlaendisches Bedarfsermittlungsinstrument
  teilhabeRlp,  // Teilhabeinstrument RLP
}

/// Konkretes Profil pro Bundesland. Kapselt alle laenderspezifischen
/// Konfigurationen: welches Instrument, welche Formulare, welche Features.
class BundeslandProfil {
  final Bundesland bundesland;
  final String anzeigeName;
  final Bedarfsinstrument bedarfsinstrument;
  final String instrumentName;
  final String rahmenvertragName;
  final bool informationsberichtBerlin101; // Formular 101 (BE-spezifisch)
  final bool tibBereicheVerfuegbar; // TIB-Bereich-Auswahl beim Klient
  final bool beiNrwVerfuegbar; // BEI_NRW-Domaenen beim Klient
  final bool implementiert; // false = experimentell, nicht produktionsreif
  final List<String> besonderheiten;

  const BundeslandProfil({
    required this.bundesland,
    required this.anzeigeName,
    required this.bedarfsinstrument,
    required this.instrumentName,
    required this.rahmenvertragName,
    this.informationsberichtBerlin101 = false,
    this.tibBereicheVerfuegbar = false,
    this.beiNrwVerfuegbar = false,
    this.implementiert = false,
    this.besonderheiten = const [],
  });
}

/// Statischer Zugriff auf alle Bundesland-Profile.
class BundeslandProfile {
  static const Map<Bundesland, BundeslandProfil> _profile = {
    Bundesland.berlin: BundeslandProfil(
      bundesland: Bundesland.berlin,
      anzeigeName: 'Berlin',
      bedarfsinstrument: Bedarfsinstrument.tib,
      instrumentName: 'TIB (Teilhabe-Instrument Berlin)',
      rahmenvertragName: 'Berliner Rahmenvertrag (BRV) 2021, Neuverhandlung ab 2027',
      informationsberichtBerlin101: true,
      tibBereicheVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'Formular 101 (Informationsbericht) verbindlich',
        'Formular 102 (Stundennachweis) verbindlich',
        'Wirksamkeitsmessung nach §128 SGB IX ab 01.01.2027',
      ],
    ),
    Bundesland.nordrheinWestfalen: BundeslandProfil(
      bundesland: Bundesland.nordrheinWestfalen,
      anzeigeName: 'Nordrhein-Westfalen',
      bedarfsinstrument: Bedarfsinstrument.beiNrw,
      instrumentName: 'BEI_NRW (Bedarfsermittlungsinstrument)',
      rahmenvertragName: 'LRV NRW (LVR/LWL), Fortschreibung 2025-2027',
      beiNrwVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'Groesster EGH-Markt (ca. 25%)',
        'LVR und LWL als zentrale Traeger',
        'BEI_NRW: 9 ICF-Lebensbereiche (d1-d9)',
        'BEI_NRW-Bogen formgebunden',
      ],
    ),
    Bundesland.bayern: BundeslandProfil(
      bundesland: Bundesland.bayern,
      anzeigeName: 'Bayern',
      bedarfsinstrument: Bedarfsinstrument.bayerischGesamtplan,
      instrumentName: 'Bayerischer Gesamtplan',
      rahmenvertragName: 'LRV Bayern 2019 (bezirks-gepraegt)',
      besonderheiten: [
        '7 Bezirke als Traeger',
        'LWV-Einfluss stark',
      ],
    ),
    Bundesland.badenWuerttemberg: BundeslandProfil(
      bundesland: Bundesland.badenWuerttemberg,
      anzeigeName: 'Baden-Wuerttemberg',
      bedarfsinstrument: Bedarfsinstrument.beiBw,
      instrumentName: 'BEI_BW',
      rahmenvertragName: 'LRV BW (Neuverhandlung 2025-2026)',
      besonderheiten: [
        'ICF-basiert',
        'Wirksamkeit zentrales Thema der Neuverhandlung',
      ],
    ),
    Bundesland.hessen: BundeslandProfil(
      bundesland: Bundesland.hessen,
      anzeigeName: 'Hessen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Hessen (Integrierter Teilhabeplan)',
      rahmenvertragName: 'LWV Hessen - Kompetenzzentrum Teilhabeberatung',
      besonderheiten: [
        'ITP-Familie (bundesweit einflussreich)',
      ],
    ),
    Bundesland.brandenburg: BundeslandProfil(
      bundesland: Bundesland.brandenburg,
      anzeigeName: 'Brandenburg',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Brandenburg',
      rahmenvertragName: 'LRV Brandenburg (Neuverhandlung 2026)',
      besonderheiten: ['ITP-Familie, enge Anlehnung an MV/Sachsen'],
    ),
    Bundesland.mecklenburgVorpommern: BundeslandProfil(
      bundesland: Bundesland.mecklenburgVorpommern,
      anzeigeName: 'Mecklenburg-Vorpommern',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP MV',
      rahmenvertragName: 'LRV MV 2021',
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.sachsen: BundeslandProfil(
      bundesland: Bundesland.sachsen,
      anzeigeName: 'Sachsen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Sachsen',
      rahmenvertragName: 'LRV Sachsen 2019, Fortschreibung 2026',
      besonderheiten: ['KSV Sachsen als zentraler Traeger', 'ITP-Familie'],
    ),
    Bundesland.sachsenAnhalt: BundeslandProfil(
      bundesland: Bundesland.sachsenAnhalt,
      anzeigeName: 'Sachsen-Anhalt',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Sachsen-Anhalt',
      rahmenvertragName: 'LRV Sachsen-Anhalt mit Wirksamkeitsanhang',
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.thueringen: BundeslandProfil(
      bundesland: Bundesland.thueringen,
      anzeigeName: 'Thueringen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Thueringen',
      rahmenvertragName: 'LRV Thueringen 2021',
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.hamburg: BundeslandProfil(
      bundesland: Bundesland.hamburg,
      anzeigeName: 'Hamburg',
      bedarfsinstrument: Bedarfsinstrument.hmbv,
      instrumentName: 'HMBV (Hamburger Manual)',
      rahmenvertragName: 'LRV Hamburg 2020/21',
      besonderheiten: ['HMBV ist Hamburger Eigenentwicklung'],
    ),
    Bundesland.bremen: BundeslandProfil(
      bundesland: Bundesland.bremen,
      anzeigeName: 'Bremen',
      bedarfsinstrument: Bedarfsinstrument.hmbv,
      instrumentName: 'HMBV (landesadaptiert)',
      rahmenvertragName: 'Bremer Rahmenvertrag 2022',
      besonderheiten: ['Kleinstmarkt'],
    ),
    Bundesland.niedersachsen: BundeslandProfil(
      bundesland: Bundesland.niedersachsen,
      anzeigeName: 'Niedersachsen',
      bedarfsinstrument: Bedarfsinstrument.bEni,
      instrumentName: 'B.E.Ni (Bedarfsermittlung Niedersachsen)',
      rahmenvertragName: 'LRV Niedersachsen 2024/25 mit Wirksamkeitsklausel',
      besonderheiten: ['GAS-Orientierung in Diskussion'],
    ),
    Bundesland.rheinlandPfalz: BundeslandProfil(
      bundesland: Bundesland.rheinlandPfalz,
      anzeigeName: 'Rheinland-Pfalz',
      bedarfsinstrument: Bedarfsinstrument.teilhabeRlp,
      instrumentName: 'Teilhabeinstrument RLP',
      rahmenvertragName: 'LRV RLP 2022',
      besonderheiten: ['PerSEH-Naehe'],
    ),
    Bundesland.saarland: BundeslandProfil(
      bundesland: Bundesland.saarland,
      anzeigeName: 'Saarland',
      bedarfsinstrument: Bedarfsinstrument.sbi,
      instrumentName: 'SBI (Saarlaendisches Bedarfsermittlungsinstrument)',
      rahmenvertragName: 'LRV Saarland 2020',
      besonderheiten: ['Sehr kleiner Markt'],
    ),
    Bundesland.schleswigHolstein: BundeslandProfil(
      bundesland: Bundesland.schleswigHolstein,
      anzeigeName: 'Schleswig-Holstein',
      bedarfsinstrument: Bedarfsinstrument.beiSh,
      instrumentName: 'PerSEH-SH / BEI-SH',
      rahmenvertragName: 'LRV SH 2023 mit expliziter §128-Regelung',
      besonderheiten: ['PerSEH-nahe Auspraegung'],
    ),
  };

  static BundeslandProfil forLand(Bundesland land) {
    return _profile[land]!;
  }

  static List<BundeslandProfil> alle() {
    return Bundesland.values.map((b) => _profile[b]!).toList();
  }

  static List<BundeslandProfil> implementierte() {
    return alle().where((p) => p.implementiert).toList();
  }

  static List<BundeslandProfil> experimentelle() {
    return alle().where((p) => !p.implementiert).toList();
  }
}
