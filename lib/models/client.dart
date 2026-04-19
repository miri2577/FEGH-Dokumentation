// Re-Export aus dem Shared-Package `fegh_core`.
//
// Die Doku-App nutzt ab jetzt das gemeinsame Client-Modell.
// Bestehende Imports `import '../models/client.dart'` funktionieren
// weiter. Das frueher generierte `client.g.dart` wird nicht mehr
// gebraucht.
export 'package:fegh_core/fegh_core.dart';
