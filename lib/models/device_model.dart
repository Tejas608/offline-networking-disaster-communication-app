class DeviceModel {
  final String id;

  final String name;

  final int rssi;

  /// REAL WIFI DIRECT IP
  String? ipAddress;

  /// WIFI DIRECT ADDRESS
  final String? deviceAddress;

  DeviceModel({
    required this.id,

    required this.name,

    required this.rssi,

    this.ipAddress,

    this.deviceAddress,
  });
}
