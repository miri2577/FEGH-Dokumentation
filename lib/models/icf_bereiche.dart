class ICFBereiche {
  static const List<ICFBereich> alle = [
    ICFBereich(
      id: 'icf1',
      titel: 'Lernen und Wissensanwendung',
      beschreibung: 'Zuhören, Schauen, Lesen, Schreiben, Rechnen',
      kategorie: ICFKategorie.kognition,
    ),
    ICFBereich(
      id: 'icf2',
      titel: 'Allgemeine Aufgaben und Anforderungen',
      beschreibung: 'Tägliche Routine, Stress bewältigen',
      kategorie: ICFKategorie.kognition,
    ),
    ICFBereich(
      id: 'icf3',
      titel: 'Kommunikation',
      beschreibung: 'Sprechen, Verstehen, Konversation',
      kategorie: ICFKategorie.kommunikation,
    ),
    ICFBereich(
      id: 'icf4',
      titel: 'Mobilität',
      beschreibung: 'Körperposition, Gehen, Transportmittel nutzen',
      kategorie: ICFKategorie.mobilitaet,
    ),
    ICFBereich(
      id: 'icf5',
      titel: 'Selbstversorgung',
      beschreibung: 'Körperpflege, Anziehen, Essen, Trinken',
      kategorie: ICFKategorie.selbstversorgung,
    ),
    ICFBereich(
      id: 'icf6',
      titel: 'Häusliches Leben',
      beschreibung: 'Wohnung, Haushalt, Einkaufen, Kochen',
      kategorie: ICFKategorie.haeuslich,
    ),
    ICFBereich(
      id: 'icf7',
      titel: 'Interpersonelle Interaktionen',
      beschreibung: 'Familie, Freunde, Fremde',
      kategorie: ICFKategorie.sozial,
    ),
    ICFBereich(
      id: 'icf8',
      titel: 'Bedeutende Lebensbereiche',
      beschreibung: 'Bildung, Arbeit, Wirtschaftsleben',
      kategorie: ICFKategorie.lebensbereiche,
    ),
    ICFBereich(
      id: 'icf9',
      titel: 'Gemeinschaftsleben',
      beschreibung: 'Erholung, Religion, Politik, Bürgerrechte',
      kategorie: ICFKategorie.gemeinschaft,
    ),
  ];

  // Bereiche für Familienhilfe (SGB VIII)
  static List<ICFBereich> get familienhilfe => alle.where((bereich) => 
    bereich.kategorie == ICFKategorie.sozial ||
    bereich.kategorie == ICFKategorie.lebensbereiche ||
    bereich.kategorie == ICFKategorie.gemeinschaft ||
    bereich.kategorie == ICFKategorie.haeuslich
  ).toList();

  // Alle Bereiche für Eingliederungshilfe (SGB IX)
  static List<ICFBereich> get eingliederungshilfe => alle;

  static ICFBereich? getById(String id) {
    try {
      return alle.firstWhere((bereich) => bereich.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<ICFBereich> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).where((bereich) => bereich != null).cast<ICFBereich>().toList();
  }
}

class ICFBereich {
  final String id;
  final String titel;
  final String beschreibung;
  final ICFKategorie kategorie;

  const ICFBereich({
    required this.id,
    required this.titel,
    required this.beschreibung,
    required this.kategorie,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ICFBereich &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum ICFKategorie {
  kognition,
  kommunikation,
  mobilitaet,
  selbstversorgung,
  haeuslich,
  sozial,
  lebensbereiche,
  gemeinschaft,
}