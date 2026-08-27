class DeviceModel {
  final String id;
  final String name;
  final int rssi;

  /// Wi-Fi Direct group-owner IP address.
  String? ipAddress;

  /// Wi-Fi Direct device address used for connection.
  final String? deviceAddress;

  /// Native Wi-Fi Direct status value.
  final int? status;

  /// Readable status such as Available or Connected.
  final String statusText;

  /// True after the Wi-Fi Direct group is formed.
  final bool isConnected;

  DeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    this.ipAddress,
    this.deviceAddress,
    this.status,
    this.statusText = 'Available',
    this.isConnected = false,
  });

  bool get hasValidDeviceAddress {
    return deviceAddress != null && deviceAddress!.trim().isNotEmpty;
  }

  String get displayName {
    final String cleanedName = name.replaceFirst('OFFLINE_NET_', '').trim();

    if (cleanedName.isEmpty) {
      return 'Unknown Device';
    }

    return cleanedName;
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    String? ipAddress,
    String? deviceAddress,
    int? status,
    String? statusText,
    bool? isConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  factory DeviceModel.fromWifiDirectMap(Map<String, dynamic> data) {
    final String deviceName = data['deviceName']?.toString().trim() ?? '';

    final String deviceAddress = data['deviceAddress']?.toString().trim() ?? '';

    final int? status = _convertToInt(data['status']);

    return DeviceModel(
      id: deviceAddress.isNotEmpty ? deviceAddress : deviceName,
      name: deviceName.isNotEmpty ? deviceName : 'Unknown Device',
      rssi: 0,
      deviceAddress: deviceAddress.isNotEmpty ? deviceAddress : null,
      status: status,
      statusText: data['statusText']?.toString() ?? _getStatusText(status),
      isConnected: status == 0,
    );
  }

  static int? _convertToInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static String _getStatusText(int? status) {
    switch (status) {
      case 0:
        return 'Connected';

      case 1:
        return 'Invited';

      case 2:
        return 'Failed';

      case 3:
        return 'Available';

      case 4:
        return 'Unavailable';

      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'DeviceModel('
        'id: $id, '
        'name: $name, '
        'deviceAddress: $deviceAddress, '
        'ipAddress: $ipAddress, '
        'statusText: $statusText, '
        'isConnected: $isConnected'
        ')';
  }
}
