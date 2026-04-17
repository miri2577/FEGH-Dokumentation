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
  final bool beiNrwVerfuegbar; // BEI_NRW-Domaenen beim Klient (NRW)
  final bool beiBwVerfuegbar; // BEI_BW-Domaenen (Baden-Wuerttemberg)
  final bool itpVerfuegbar; // ITP-Familie (HE, BB, MV, SN, ST, TH)
  final bool hmbvVerfuegbar; // HMBV (Hamburg, Bremen)
  final bool bEniVerfuegbar; // B.E.Ni (Niedersachsen)
  final bool generischIcfVerfuegbar; // Generische 9 ICF-Bereiche (restliche Laender)
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
    this.beiBwVerfuegbar = false,
    this.itpVerfuegbar = false,
    this.hmbvVerfuegbar = false,
    this.bEniVerfuegbar = false,
    this.generischIcfVerfuegbar = false,
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
      instrumentName: 'Bayerischer Gesamtplan (ANLEI seit 03/2026)',
      rahmenvertragName: 'LRV Bayern 2019, bezirksgepraegt, ANLEI-Migration 2026',
      generischIcfVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        '7 Bezirke als Traeger',
        'ANLEI-Fachverfahren seit 03/2026',
        'Erfassung ueber ANLEI-Traegerportal',
      ],
    ),
    Bundesland.badenWuerttemberg: BundeslandProfil(
      bundesland: Bundesland.badenWuerttemberg,
      anzeigeName: 'Baden-Wuerttemberg',
      bedarfsinstrument: Bedarfsinstrument.beiBw,
      instrumentName: 'BEI_BW (Bedarfsermittlungsinstrument BW)',
      rahmenvertragName: 'LRV BW (Neuverhandlung 2025-2026)',
      beiBwVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'ICF-basiert mit 9 Lebensbereichen',
        'KVJS als zentrale Stelle',
        'Wirksamkeit zentrales Thema der Neuverhandlung',
      ],
    ),
    Bundesland.hessen: BundeslandProfil(
      bundesland: Bundesland.hessen,
      anzeigeName: 'Hessen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Hessen (Integrierter Teilhabeplan)',
      rahmenvertragName: 'LWV Hessen, neue PiT-Version ab 02/2026',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'ITP-Familie (bundesweit einflussreich)',
        'PerSEH als Traegerportal',
      ],
    ),
    Bundesland.brandenburg: BundeslandProfil(
      bundesland: Bundesland.brandenburg,
      anzeigeName: 'Brandenburg',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Brandenburg',
      rahmenvertragName: 'LRV Brandenburg (Neuverhandlung 2026)',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['ITP-Familie, enge Anlehnung an MV/Sachsen'],
    ),
    Bundesland.mecklenburgVorpommern: BundeslandProfil(
      bundesland: Bundesland.mecklenburgVorpommern,
      anzeigeName: 'Mecklenburg-Vorpommern',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP MV',
      rahmenvertragName: 'LRV MV 2021',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.sachsen: BundeslandProfil(
      bundesland: Bundesland.sachsen,
      anzeigeName: 'Sachsen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Sachsen',
      rahmenvertragName: 'LRV Sachsen 2019, Fortschreibung 2026',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['KSV Sachsen als zentraler Traeger', 'ITP-Familie'],
    ),
    Bundesland.sachsenAnhalt: BundeslandProfil(
      bundesland: Bundesland.sachsenAnhalt,
      anzeigeName: 'Sachsen-Anhalt',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Sachsen-Anhalt',
      rahmenvertragName: 'LRV Sachsen-Anhalt mit Wirksamkeitsanhang',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.thueringen: BundeslandProfil(
      bundesland: Bundesland.thueringen,
      anzeigeName: 'Thueringen',
      bedarfsinstrument: Bedarfsinstrument.itp,
      instrumentName: 'ITP Thueringen',
      rahmenvertragName: 'LRV Thueringen 2021',
      itpVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['ITP-Familie'],
    ),
    Bundesland.hamburg: BundeslandProfil(
      bundesland: Bundesland.hamburg,
      anzeigeName: 'Hamburg',
      bedarfsinstrument: Bedarfsinstrument.hmbv,
      instrumentName: 'HMBV (Hamburger Manual)',
      rahmenvertragName: 'LRV Hamburg 2020/21',
      hmbvVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'HMBV ist Hamburger Eigenentwicklung',
        '5 Kernbereiche mit Unterstuetzungsintensitaet 0-4',
      ],
    ),
    Bundesland.bremen: BundeslandProfil(
      bundesland: Bundesland.bremen,
      anzeigeName: 'Bremen',
      bedarfsinstrument: Bedarfsinstrument.hmbv,
      instrumentName: 'HMBV (Bremen, landesadaptiert)',
      rahmenvertragName: 'Bremer Rahmenvertrag 2022',
      hmbvVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['Kleinstmarkt', 'HMBV-Struktur uebernommen'],
    ),
    Bundesland.niedersachsen: BundeslandProfil(
      bundesland: Bundesland.niedersachsen,
      anzeigeName: 'Niedersachsen',
      bedarfsinstrument: Bedarfsinstrument.bEni,
      instrumentName: 'B.E.Ni (Bedarfsermittlung Niedersachsen)',
      rahmenvertragName: 'LRV Niedersachsen 2024/25 mit Wirksamkeitsklausel',
      bEniVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'GAS-Orientierung in Diskussion',
        '9 ICF-orientierte Lebensbereiche',
        'LS-EH-Portal Dataport',
      ],
    ),
    Bundesland.rheinlandPfalz: BundeslandProfil(
      bundesland: Bundesland.rheinlandPfalz,
      anzeigeName: 'Rheinland-Pfalz',
      bedarfsinstrument: Bedarfsinstrument.teilhabeRlp,
      instrumentName: 'Teilhabeinstrument RLP',
      rahmenvertragName: 'LRV RLP 2022',
      generischIcfVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['PerSEH-Naehe', 'LSJV eFalldaten-Portal im Aufbau'],
    ),
    Bundesland.saarland: BundeslandProfil(
      bundesland: Bundesland.saarland,
      anzeigeName: 'Saarland',
      bedarfsinstrument: Bedarfsinstrument.sbi,
      instrumentName: 'SBI (Saarlaendisches Bedarfsermittlungsinstrument)',
      rahmenvertragName: 'LRV Saarland 2020',
      generischIcfVerfuegbar: true,
      implementiert: true,
      besonderheiten: ['Sehr kleiner Markt', 'SBI nutzt ICF-Lebensbereiche'],
    ),
    Bundesland.schleswigHolstein: BundeslandProfil(
      bundesland: Bundesland.schleswigHolstein,
      anzeigeName: 'Schleswig-Holstein',
      bedarfsinstrument: Bedarfsinstrument.beiSh,
      instrumentName: 'PerSEH-SH / BEI-SH',
      rahmenvertragName: 'LRV SH 2023 mit expliziter §128-Regelung',
      generischIcfVerfuegbar: true,
      implementiert: true,
      besonderheiten: [
        'PerSEH-nahe Auspraegung',
        'ITP.SH als Plantool',
        'Dataport-Sozialportal',
      ],
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
