import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String title;
  final String body;
  final String? route;
  final List<String> flags;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final bool isRead;
  final DateTime? readAt;
  final MessagePriority priority;
  final MessageType type;

  const Message({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.flags = const [],
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    this.isRead = false,
    this.readAt,
    this.priority = MessagePriority.normal,
    this.type = MessageType.info,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? title,
    String? body,
    String? route,
    List<String>? flags,
    DateTime? createdAt,
    String? senderId,
    String? senderName,
    bool? isRead,
    DateTime? readAt,
    MessagePriority? priority,
    MessageType? type,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      route: route ?? this.route,
      flags: flags ?? this.flags,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      type: type ?? this.type,
    );
  }
}

enum MessagePriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

enum MessageType {
  @JsonValue('info')
  info,
  @JsonValue('warning')
  warning,
  @JsonValue('error')
  error,
  @JsonValue('success')
  success,
  @JsonValue('announcement')
  announcement,
  @JsonValue('update')
  update,
}

@JsonSerializable()
class EncryptedMessage {
  final String id;
  final int version;
  final String algorithm;
  final String nonce;
  final String ciphertext;
  final String? aad;
  final List<DeviceKey> perDevice;
  final DateTime timestamp;

  const EncryptedMessage({
    required this.id,
    this.version = 1,
    required this.algorithm,
    required this.nonce,
    required this.ciphertext,
    this.aad,
    required this.perDevice,
    required this.timestamp,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) => _$EncryptedMessageFromJson(json);
  Map<String, dynamic> toJson() => _$EncryptedMessageToJson(this);
}

@JsonSerializable()
class DeviceKey {
  final String deviceId;
  final String userId;
  final String wrappedKey;

  const DeviceKey({
    required this.deviceId,
    required this.userId,
    required this.wrappedKey,
  });

  factory DeviceKey.fromJson(Map<String, dynamic> json) => _$DeviceKeyFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceKeyToJson(this);
}

@JsonSerializable()
class MessageAck {
  final String messageId;
  final String userId;
  final String deviceId;
  final DateTime readAt;

  const MessageAck({
    required this.messageId,
    required this.userId,
    required this.deviceId,
    required this.readAt,
  });

  factory MessageAck.fromJson(Map<String, dynamic> json) => _$MessageAckFromJson(json);
  Map<String, dynamic> toJson() => _$MessageAckToJson(this);
}