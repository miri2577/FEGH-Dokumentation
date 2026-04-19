// Re-Export aus dem Shared-Package `fegh_chat`.
//
// Der Matrix-Chat-Service wird zentral im Shared-Package gepflegt
// und von beiden Apps (FEGH-Dokumentation und FEGH-Verwaltung)
// genutzt. Bestehende Imports
// `import '../services/matrix_chat_service.dart'` funktionieren weiter.
export 'package:fegh_chat/fegh_chat.dart' show MatrixChatService;
