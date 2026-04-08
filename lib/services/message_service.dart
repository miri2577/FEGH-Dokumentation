import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../config/developer_mode.dart';
import 'app_logger.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  late final CryptoStorage _cryptoStorage;
  late final HiDriveWebDAVClient _webdavClient;
  String? _userId;
  String? _organizationId;
  String? _deviceId;
  final Uuid _uuid = const Uuid();

  List<Message> _messages = [];
  int _unreadCount = 0;

  List<Message> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;

  Future<void> initialize({
    required String hidriveUsername,
    required String hidrivePassword,
    required String userId,
    required String organizationId,
    String? deviceId,
    String? rootSubdirectory,
  }) async {
    _cryptoStorage = CryptoStorage();
    _webdavClient = HiDriveWebDAVClient(
      baseUrl: HiDriveConfig.buildWebDAVUrl(hidriveUsername, rootSubdirectory: rootSubdirectory),
      username: hidriveUsername,
      password: hidrivePassword,
      certificatePins: [],
    );
    _userId = userId;
    _organizationId = organizationId;
    _deviceId = deviceId ?? await _generateDeviceId();

    if (DeveloperMode.allowSecurityDebugLogs) {
      AppLogger.info('Messages', 'Initialisierung fuer User $_userId, Device $_deviceId');
    }

    await _registerDevice();
    await syncMessages();
  }

  Future<String> _generateDeviceId() async {
    // Verwende eine Kombination aus Geräteinformationen
    final platform = Platform.operatingSystem;
    final hostname = Platform.localHostname;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final deviceInfo = '$platform-$hostname-$timestamp';
    final bytes = utf8.encode(deviceInfo);
    final digest = sha256.convert(bytes);

    return digest.toString().substring(0, 16);
  }

  Future<void> _registerDevice() async {
    try {
      // Entwicklermodus: Verwende einfache Geräte-Registrierung ohne E2E-Verschlüsselung
      if (!DeveloperMode.useKeychain) {
        if (DeveloperMode.allowSecurityDebugLogs) {
          AppLogger.info('Messages', 'DEV: Ueberspringe E2E-Verschluesselung, verwende Entwicklungs-Registrierung');
        }
        return; // Keine echte Registrierung im Entwicklermodus
      }

      // In Produktionsversion: Echte E2E-Verschlüsselung implementieren
      // TODO: Implementiere vollständige E2E-Verschlüsselung für Produktionsversion
      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: E2E-Verschluesselung noch nicht implementiert');
      }
    } catch (e) {
      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.error('Messages', 'DEV: Geraete-Registrierung uebersprungen', e);
      }
      // In Entwicklermodus: Fehler nicht weiterwerfen
      if (DeveloperMode.useKeychain) {
        rethrow;
      }
    }
  }

  Future<void> syncMessages() async {
    try {
      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: Synchronisiere Nachrichten...');
      }

      final msgPath = 'eingliederungshilfe/organizations/${_organizationId}/shared/messages';
      await _webdavClient.createDirectory(msgPath);
      final result = await _webdavClient.list(msgPath);

      if (!result.isSuccess) {
        if (DeveloperMode.allowSecurityDebugLogs) {
          AppLogger.info('Messages', 'DEV: Inbox nicht verfuegbar oder leer: ${result.error}');
        }
        return;
      }

      final files = result.data ?? [];

      final newMessages = <Message>[];

      for (final file in files) {
        if (file.endsWith('.bin')) {
          try {
            final downloadResult = await _webdavClient.get('$msgPath/$file');
            if (!downloadResult.isSuccess || downloadResult.data == null) {
              if (DeveloperMode.allowSecurityDebugLogs) {
                AppLogger.error('Messages', 'DEV: Download fehlgeschlagen fuer $file: ${downloadResult.error}');
              }
              continue;
            }

            final encJson = jsonDecode(utf8.decode(downloadResult.data!)) as Map<String, dynamic>;
            final pt = await _cryptoStorage.decryptRecord(encJson);
            final decryptedMessage = Message.fromJson(jsonDecode(utf8.decode(pt)) as Map<String, dynamic>);
            if (decryptedMessage != null) {
              newMessages.add(decryptedMessage);
            }
          } catch (e) {
            if (DeveloperMode.allowSecurityDebugLogs) {
              AppLogger.error('Messages', 'DEV: Fehler beim Laden der Nachricht $file', e);
            }
          }
        }
      }

      // Sortiere nach Datum (neueste zuerst)
      newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _messages = newMessages;
      _updateUnreadCount();

      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: ${newMessages.length} Nachrichten geladen, $_unreadCount ungelesen');
      }
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Synchronisieren', e);
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      final msgPath = 'eingliederungshilfe/organizations/${_organizationId}/shared/messages';
      await _webdavClient.createDirectory(msgPath);
      final jsonStr = jsonEncode(message.toJson());
      final rec = await _cryptoStorage.encryptRecord(
        plaintext: utf8.encode(jsonStr),
        aad: {'schema': 'message', 'id': message.id, 'ts': DateTime.now().toUtc().toIso8601String()},
      );
      final data = utf8.encode(jsonEncode(rec));
      await _webdavClient.put('$msgPath/${message.id}.bin', Uint8List.fromList(data));
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Senden', e);
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      // Aktualisiere lokalen Status
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        if (!message.isRead) {
          _messages[messageIndex] = message.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _updateUnreadCount();
        }
      }

      // Schreibe ACK-Datei
      final ack = MessageAck(
        messageId: messageId,
        userId: _userId!,
        deviceId: _deviceId!,
        readAt: DateTime.now().toUtc(),
      );

      // Optional: ACK in shared/messages/acks ablegen
      final ackPath = 'eingliederungshilfe/organizations/${_organizationId}/shared/messages/acks/$messageId.ack';
      await _webdavClient.createDirectory('eingliederungshilfe/organizations/${_organizationId}/shared/messages/acks');
      await _webdavClient.put(ackPath, Uint8List.fromList(utf8.encode(jsonEncode(ack.toJson()))));

      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: Nachricht als gelesen markiert: $messageId');
      }
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Markieren als gelesen', e);
    }
  }

  Future<void> archiveMessage(String messageId) async {
    try {
      final inboxPath = 'app/msg/users/$_userId/inbox/$messageId.msg';
      final archivePath = 'app/msg/users/$_userId/archive/$messageId.msg';

      // First, try to download the message
      final downloadResult = await _webdavClient.get(inboxPath);
      if (downloadResult.isSuccess && downloadResult.data != null) {
        // Upload to archive location
        final archiveResult = await _webdavClient.put(archivePath, downloadResult.data!);
        if (archiveResult.isSuccess) {
          // Delete from inbox
          await _webdavClient.delete(inboxPath);
        } else {
          throw Exception(archiveResult.error ?? 'Archive upload failed');
        }
      } else {
        if (DeveloperMode.allowSecurityDebugLogs) {
          AppLogger.info('Messages', 'DEV: Nachricht nicht gefunden zum Archivieren: $messageId');
        }
      }

      // Entferne aus lokaler Liste
      _messages.removeWhere((msg) => msg.id == messageId);
      _updateUnreadCount();

      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: Nachricht archiviert: $messageId');
      }
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Archivieren', e);
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _messages.where((msg) => !msg.isRead).length;
  }

  Future<void> startPeriodicSync({Duration interval = const Duration(minutes: 1)}) async {
    // TODO: Implementiere periodische Synchronisation
    // Verwende Timer.periodic für Vordergrund
    // Verwende WorkManager/BGFetch für Hintergrund
  }

  // Für Admin/Testing: Sende Testnachricht
  Future<void> sendTestMessage({
    required String title,
    required String body,
    MessagePriority priority = MessagePriority.normal,
    MessageType type = MessageType.info,
  }) async {
    if (!DeveloperMode.isActive) {
      throw Exception('Test-Nachrichten nur im Developer Mode verfügbar');
    }

    try {
      final message = Message(
        id: _uuid.v4(),
        title: title,
        body: body,
        createdAt: DateTime.now().toUtc(),
        senderId: 'test-admin',
        senderName: 'Test Admin',
        priority: priority,
        type: type,
      );

      // Für Test: Direkt zur lokalen Liste hinzufügen
      _messages.insert(0, message);
      _updateUnreadCount();

      if (DeveloperMode.allowSecurityDebugLogs) {
        AppLogger.info('Messages', 'DEV: Test-Nachricht erstellt: ${message.title}');
      }
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Senden der Test-Nachricht', e);
    }
  }
}
