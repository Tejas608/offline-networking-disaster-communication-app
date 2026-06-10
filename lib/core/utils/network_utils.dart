import 'dart:io';

class NetworkUtils {
  /// GET CURRENT DEVICE IP ADDRESS
  static Future<String> getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return '0.0.0.0';
    } catch (e) {
      return '0.0.0.0';
    }
  }
}
