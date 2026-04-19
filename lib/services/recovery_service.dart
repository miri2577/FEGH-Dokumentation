// Re-Export aus dem Shared-Package `fegh_backup`.
//
// Der RecoveryService wird zentral im Shared-Package gepflegt und von
// beiden Apps (FEGH-Dokumentation und FEGH-Verwaltung) genutzt.
// Bestehende App-seitige Imports `import '../services/recovery_service.dart'`
// funktionieren weiter.
export 'package:fegh_backup/fegh_backup.dart' show RecoveryService;
