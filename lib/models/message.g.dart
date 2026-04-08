// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  route: json['route'] as String?,
  flags:
      (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  isRead: json['isRead'] as bool? ?? false,
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  priority:
      $enumDecodeNullable(_$MessagePriorityEnumMap, json['priority']) ??
      MessagePriority.normal,
  type:
      $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
      MessageType.info,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'route': instance.route,
  'flags': instance.flags,
  'createdAt': instance.createdAt.toIso8601String(),
  'senderId': instance.senderId,
  'senderName': instance.senderName,
  'isRead': instance.isRead,
  'readAt': instance.readAt?.toIso8601String(),
  'priority': _$MessagePriorityEnumMap[instance.priority]!,
  'type': _$MessageTypeEnumMap[instance.type]!,
};

const _$MessagePriorityEnumMap = {
  MessagePriority.low: 'low',
  MessagePriority.normal: 'normal',
  MessagePriority.high: 'high',
  MessagePriority.urgent: 'urgent',
};

const _$MessageTypeEnumMap = {
  MessageType.info: 'info',
  MessageType.warning: 'warning',
  MessageType.error: 'error',
  MessageType.success: 'success',
  MessageType.announcement: 'announcement',
  MessageType.update: 'update',
};

EncryptedMessage _$EncryptedMessageFromJson(Map<String, dynamic> json) =>
    EncryptedMessage(
      id: json['id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      algorithm: json['algorithm'] as String,
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      aad: json['aad'] as String?,
      perDevice: (json['perDevice'] as List<dynamic>)
          .map((e) => DeviceKey.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$EncryptedMessageToJson(EncryptedMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'algorithm': instance.algorithm,
      'nonce': instance.nonce,
      'ciphertext': instance.ciphertext,
      'aad': instance.aad,
      'perDevice': instance.perDevice,
      'timestamp': instance.timestamp.toIso8601String(),
    };

DeviceKey _$DeviceKeyFromJson(Map<String, dynamic> json) => DeviceKey(
  deviceId: json['deviceId'] as String,
  userId: json['userId'] as String,
  wrappedKey: json['wrappedKey'] as String,
);

Map<String, dynamic> _$DeviceKeyToJson(DeviceKey instance) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'userId': instance.userId,
  'wrappedKey': instance.wrappedKey,
};

MessageAck _$MessageAckFromJson(Map<String, dynamic> json) => MessageAck(
  messageId: json['messageId'] as String,
  userId: json['userId'] as String,
  deviceId: json['deviceId'] as String,
  readAt: DateTime.parse(json['readAt'] as String),
);

Map<String, dynamic> _$MessageAckToJson(MessageAck instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'userId': instance.userId,
      'deviceId': instance.deviceId,
      'readAt': instance.readAt.toIso8601String(),
    };
