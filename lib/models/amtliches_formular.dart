import 'bundesland.dart';

/// Art der Einreichung bei der Behoerde.
enum EinreichungsArt {
  /// Direktes Ausfuellen im PDF (Berlin Formular 101)
  pdfAusfuellen,
  /// PDF herunterladen, ausdrucken, manuell ausfuellen, per Post/beA senden
  pdfBlanko,
  /// Webportal der Behoerde - App liefert nur strukturierte Daten
  webportal,
  /// Nur Hinweis: Instrument ueber Traegersoftware (z.B. PerSEH)
  traegerportal,
}

/// Beschreibt ein amtliches Formular / Bedarfserhebungsinstrument
/// fuer ein bestimmtes Bundesland.
class AmtlichesFormular {
  final Bundesland bundesland;
  final String titel;
  final String kurzbeschreibung;
  final EinreichungsArt art;

  /// Asset-Pfad zum Blanko-PDF (wenn vorhanden).
  final String? assetPfad;

  /// Direkt-URL zum offiziellen Download (fallback).
  final String? downloadUrl;

  /// URL zum Einreichungsportal der Behoerde (z.B. PerSEH).
  final String? portalUrl;

  /// Hinweise fuer die Nutzung (mehrzeilig moeglich).
  final String hinweise;

  /// Stand der Information (Monat/Jahr).
  final String stand;

  const AmtlichesFormular({
    required this.bundesland,
    required this.titel,
    required this.kurzbeschreibung,
    required this.art,
    this.assetPfad,
    this.downloadUrl,
    this.portalUrl,
    required this.hinweise,
    required this.stand,
  });
}

/// Statischer Katalog aller bekannten Formulare pro Bundesland.
class AmtlicheFormulareKatalog {
  static const List<AmtlichesFormular> alle = [
    // ── Berlin ─────────────────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.berlin,
      titel: 'Informationsbericht (Formular 101)',
      kurzbeschreibung: 'Pflicht-Jahresbericht fuer Leistungen der EGH (§128 SGB IX)',
      art: EinreichungsArt.pdfAusfuellen,
      assetPfad: 'assets/informationsbericht_101.pdf',
      downloadUrl: 'https://www.berlin.de/sen/soziales/besondere-lebenssituationen/'
          'menschen-mit-behinderung/eingliederungshilfe-sgb-ix/dokumente-und-links/'
          'informationsbericht_101.pdf',
      hinweise: 'Abgabe jaehrlich bis 15.04. des Folgejahres. '
          'Einreichung nur verschluesselt (beA, DE-Mail). '
          'In der App unter Berichte > Informationsbericht bearbeitbar.',
      stand: '07/2025',
    ),

    // ── Nordrhein-Westfalen ────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.nordrheinWestfalen,
      titel: 'BEI_NRW (Bedarfsermittlungsinstrument NRW)',
      kurzbeschreibung: 'Einheitliches Instrument fuer LVR und LWL, 9 ICF-Lebensbereiche',
      art: EinreichungsArt.traegerportal,
      assetPfad: 'assets/formulare/nrw/bei_nrw_leer.pdf',
      downloadUrl: 'https://www.lwl-inklusionsamt-soziale-teilhabe.de/de/informationen-fur-fachleute/',
      portalUrl: 'https://www.lvr.de/de/nav_main/soziales_1/menschenmitbehinderung/'
          'antraege_und_verfahren/hilfeplanverfahren_2/',
      hinweise: 'Die eigentliche Erfassung erfolgt im Traegerportal PerSEH '
          '(www.lvr.de bzw. www.lwl-soziales.de). '
          'Das Blanko-PDF dient zur Vorbereitung und fuer Akteneinlagen.',
      stand: '11/2017',
    ),

    // ── Hessen ─────────────────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.hessen,
      titel: 'PiT Hessen (Personenzentrierter integrierter Teilhabeplan)',
      kurzbeschreibung: 'Manual + Vorlage des LWV Hessen',
      art: EinreichungsArt.traegerportal,
      assetPfad: 'assets/formulare/hessen/pit_hessen_manual.pdf',
      downloadUrl: 'https://www.lwv-hessen.de/service/formulare/'
          '3-personenzentrierter-integrierter-teilhabeplan-pit.html',
      portalUrl: 'https://www.lwv-hessen.de/leben-wohnen/wie-unterstuetzt-der-lwv/'
          'umsetzung-des-bundesteilhabegesetzes/der-pit-hessen/',
      hinweise: 'Das PiT-PDF ist nicht ausfuellbar - es dient der Einsicht und '
          'als Unterlage fuer den Teilhabeplanungs-Termin. '
          'Neue PiT-Version gilt ab Ende Februar 2026.',
      stand: '02/2026',
    ),

    // ── Hamburg ────────────────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.hamburg,
      titel: 'HMBV (Hamburger Manual zur Bedarfsermittlung)',
      kurzbeschreibung: 'Hamburger Eigenentwicklung, bundesweit adaptiert',
      art: EinreichungsArt.traegerportal,
      downloadUrl: null,
      portalUrl: 'https://www.hamburg.de/politik-und-verwaltung/behoerden/sozialbehoerde/'
          'themen/behinderung/',
      hinweise: 'HMBV wird direkt im Portal des Sozialhilfetraegers gefuehrt. '
          'Blanko-Vordruck nicht oeffentlich zugaenglich.',
      stand: '2021',
    ),

    // ── Niedersachsen ──────────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.niedersachsen,
      titel: 'B.E.Ni (Bedarfsermittlung Niedersachsen)',
      kurzbeschreibung: 'Landesrahmenvertrag 2024/25 mit Wirksamkeitsklausel',
      art: EinreichungsArt.traegerportal,
      downloadUrl: null,
      portalUrl: 'https://www.ms.niedersachsen.de/',
      hinweise: 'B.E.Ni wird von den zustaendigen Traegern (Landkreise, kreisfreie Staedte) '
          'vorgehalten. Bitte beim zustaendigen Traeger erfragen.',
      stand: '2025',
    ),

    // ── Bayern ─────────────────────────────────────────────────────
    AmtlichesFormular(
      bundesland: Bundesland.bayern,
      titel: 'Bayerischer Gesamtplan (ANLEI-Verbund seit 2026)',
      kurzbeschreibung: 'Bezirke nutzen ANLEI-Fachverfahren',
      art: EinreichungsArt.traegerportal,
      downloadUrl: null,
      portalUrl: 'https://www.anlei-service-gmbh.de/',
      hinweise: 'Bayern nutzt das bezirksuebergreifende ANLEI-Fachverfahren '
          '(seit 03/2026). Gesamtplan-Formulare sind dort hinterlegt. '
          'Leistungserbringer erhalten Portalzugang vom Bezirk.',
      stand: '03/2026',
    ),
  ];

  static List<AmtlichesFormular> fuerLand(Bundesland b) {
    return alle.where((f) => f.bundesland == b).toList();
  }

  static AmtlichesFormular? einziges(Bundesland b) {
    final liste = fuerLand(b);
    return liste.isEmpty ? null : liste.first;
  }
}
