import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WifiDirectService {
  /// METHOD CHANNEL
  static const MethodChannel _channel = MethodChannel('wifi_direct_channel');

  /// DISCOVER NEARBY PEERS
  static Future<List<dynamic>> discoverPeers() async {
    try {
      final List<dynamic> peers = await _channel.invokeMethod('discoverPeers');

      return peers;
    } on PlatformException catch (e) {
      return ['Failed: ${e.message}'];
    }
  }

  /// CONNECT TO WIFI DIRECT PEER
  static Future<String> connectToPeer(String deviceAddress) async {
    try {
      final String result = await _channel.invokeMethod('connectToPeer', {
        'deviceAddress': deviceAddress,
      });

      return result;
    } on PlatformException catch (e) {
      return 'Failed: ${e.message}';
    }
  }

  /// GET WIFI DIRECT CONNECTION INFO
  static Future<Map?> getConnectionInfo() async {
    try {
      final result = await _channel.invokeMethod('getConnectionInfo');

      return result;
    } on PlatformException catch (e) {
      debugPrint('Connection Info Error: ${e.message}');

      return null;
    }
  }
}
