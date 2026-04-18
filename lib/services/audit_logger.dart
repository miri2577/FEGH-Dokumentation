/// Re-Export aus dem Shared-Package `fegh_compliance`.
///
/// Der AuditLogger wird zentral im Shared-Package gepflegt und
/// von beiden Apps (FEGH-Dokumentation und FEGH-Verwaltung) genutzt.
/// Bestehende App-seitige Imports `import '../services/audit_logger.dart'`
/// funktionieren weiter.
export 'package:fegh_compliance/fegh_compliance.dart';
