class MessageModel {
  final String messageId;
  final String peerUserId;

  final String senderUserId;
  final String receiverUserId;
  final String senderName;

  final String text;
  final String messageType;

  final DateTime time;

  final String deliveryStatus;

  final bool isOutgoing;
  final bool isRead;

  final double? latitude;
  final double? longitude;

  const MessageModel({
    required this.messageId,
    required this.peerUserId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.senderName,
    required this.text,
    required this.messageType,
    required this.time,
    required this.deliveryStatus,
    required this.isOutgoing,
    required this.isRead,
    this.latitude,
    this.longitude,
  });

  factory MessageModel.fromDatabaseMap(Map<String, Object?> map) {
    return MessageModel(
      messageId: map['message_id']?.toString() ?? '',
      peerUserId: map['peer_user_id']?.toString() ?? '',
      senderUserId: map['sender_user_id']?.toString() ?? '',
      receiverUserId: map['receiver_user_id']?.toString() ?? '',
      senderName: map['sender_name']?.toString() ?? 'Unknown User',
      text: map['content']?.toString() ?? '',
      messageType: map['message_type']?.toString() ?? 'text',
      time:
          DateTime.tryParse(map['timestamp']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      deliveryStatus: map['delivery_status']?.toString() ?? 'sent',
      isOutgoing: _toInt(map['is_outgoing']) == 1,
      isRead: _toInt(map['is_read']) == 1,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
    );
  }

  factory MessageModel.fromNetworkMap(
    Map<String, dynamic> map, {
    required String localUserId,
  }) {
    final String senderId = map['senderId']?.toString() ?? '';

    final String receiverId = map['receiverId']?.toString() ?? '';

    final bool outgoing = senderId == localUserId;

    return MessageModel(
      messageId: map['messageId']?.toString() ?? '',
      peerUserId: outgoing ? receiverId : senderId,
      senderUserId: senderId,
      receiverUserId: receiverId,
      senderName: map['senderName']?.toString() ?? 'Unknown User',
      text: map['content']?.toString() ?? '',
      messageType: map['messageType']?.toString() ?? 'text',
      time:
          DateTime.tryParse(map['timestamp']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      deliveryStatus: 'delivered',
      isOutgoing: outgoing,
      isRead: false,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
    );
  }

  Map<String, dynamic> toNetworkMap() {
    return {
      'type': 'message',
      'messageId': messageId,
      'senderId': senderUserId,
      'receiverId': receiverUserId,
      'senderName': senderName,
      'content': text,
      'messageType': messageType,
      'timestamp': time.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  MessageModel copyWith({String? deliveryStatus, bool? isRead}) {
    return MessageModel(
      messageId: messageId,
      peerUserId: peerUserId,
      senderUserId: senderUserId,
      receiverUserId: receiverUserId,
      senderName: senderName,
      text: text,
      messageType: messageType,
      time: time,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isOutgoing: isOutgoing,
      isRead: isRead ?? this.isRead,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
