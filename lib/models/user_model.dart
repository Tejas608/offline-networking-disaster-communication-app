class UserModel {
  final String deviceId;
  final String name;
  final String phone;

  final String? deviceName;
  final String? deviceAddress;
  final String? ipAddress;

  final bool isOnline;

  final DateTime? lastConnectedAt;

  final String? lastMessage;
  final DateTime? lastMessageAt;

  const UserModel({
    required this.deviceId,
    required this.name,
    required this.phone,
    this.deviceName,
    this.deviceAddress,
    this.ipAddress,
    this.isOnline = false,
    this.lastConnectedAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  String get displayName {
    final String cleanedName = name.trim();

    if (cleanedName.isNotEmpty && cleanedName != 'Offline User') {
      return cleanedName;
    }

    final String cleanedPhone = phone.trim();

    if (cleanedPhone.isNotEmpty) {
      return cleanedPhone;
    }

    final String cleanedDeviceName = deviceName?.trim() ?? '';

    if (cleanedDeviceName.isNotEmpty) {
      return cleanedDeviceName;
    }

    return 'Unknown User';
  }

  String? get secondaryLabel {
    final String cleanedName = name.trim();
    final String cleanedPhone = phone.trim();
    final String cleanedDeviceName = deviceName?.trim() ?? '';

    if (cleanedName.isNotEmpty && cleanedName != 'Offline User') {
      if (cleanedPhone.isNotEmpty && cleanedPhone != cleanedName) {
        return cleanedPhone;
      }

      if (cleanedDeviceName.isNotEmpty && cleanedDeviceName != cleanedName) {
        return cleanedDeviceName;
      }
    }

    if (cleanedPhone.isNotEmpty && cleanedPhone != displayName) {
      return cleanedPhone;
    }

    if (cleanedDeviceName.isNotEmpty && cleanedDeviceName != displayName) {
      return cleanedDeviceName;
    }

    return null;
  }

  factory UserModel.fromDatabaseMap(Map<String, Object?> map) {
    return UserModel(
      deviceId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown User',
      phone: map['phone']?.toString() ?? '',
      deviceName: map['device_name']?.toString(),
      deviceAddress: map['device_address']?.toString(),
      ipAddress: map['last_ip_address']?.toString(),
      isOnline: _toInt(map['connection_status']) == 1,
      lastConnectedAt: _toDateTime(map['last_connected_at']),
      lastMessage: map['last_message']?.toString(),
      lastMessageAt: _toDateTime(map['last_message_at']),
    );
  }

  UserModel copyWith({
    String? deviceId,
    String? name,
    String? phone,
    String? deviceName,
    String? deviceAddress,
    String? ipAddress,
    bool? isOnline,
    DateTime? lastConnectedAt,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return UserModel(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      deviceName: deviceName ?? this.deviceName,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      isOnline: isOnline ?? this.isOnline,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
