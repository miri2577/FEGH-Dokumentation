class FamilienhilfeKategorien {
  static const List<FamilienhilfeKategorie> alle = [
    FamilienhilfeKategorie(
      id: 'einzelgespraech',
      titel: 'Einzelgespräch',
      beschreibung: 'Gespräche mit einzelnen Familienmitgliedern',
      icon: 'person',
    ),
    FamilienhilfeKategorie(
      id: 'paargespraech',
      titel: 'Paargespräch',
      beschreibung: 'Gespräche mit dem Elternpaar',
      icon: 'people',
    ),
    FamilienhilfeKategorie(
      id: 'familiengespraech',
      titel: 'Familiengespräch',
      beschreibung: 'Gespräche mit der ganzen Familie',
      icon: 'family_restroom',
    ),
    FamilienhilfeKategorie(
      id: 'erziehungsberatung',
      titel: 'Erziehungsberatung',
      beschreibung: 'Beratung zu Erziehungsfragen und -methoden',
      icon: 'school',
    ),
    FamilienhilfeKategorie(
      id: 'krisenmanagement',
      titel: 'Krisenmanagement',
      beschreibung: 'Akute Krisensituationen und Konfliktbewältigung',
      icon: 'emergency',
    ),
    FamilienhilfeKategorie(
      id: 'resilienzoerderung',
      titel: 'Resilienz- und Kompetenzförderung',
      beschreibung: 'Stärkung der Familienkompetenzen und Widerstandsfähigkeit',
      icon: 'trending_up',
    ),
  ];

  static FamilienhilfeKategorie? getById(String id) {
    try {
      return alle.firstWhere((kategorie) => kategorie.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<FamilienhilfeKategorie> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).where((kategorie) => kategorie != null).cast<FamilienhilfeKategorie>().toList();
  }
}

class FamilienhilfeKategorie {
  final String id;
  final String titel;
  final String beschreibung;
  final String icon;

  const FamilienhilfeKategorie({
    required this.id,
    required this.titel,
    required this.beschreibung,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilienhilfeKategorie &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}