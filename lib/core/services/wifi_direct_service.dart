import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WifiDirectService {
  WifiDirectService._();

  static const MethodChannel _channel = MethodChannel('wifi_direct_channel');

  /// Starts Wi-Fi Direct discovery and returns real peer details.
  ///
  /// Each returned map contains:
  /// deviceName
  /// deviceAddress
  /// status
  /// statusText
  static Future<List<Map<String, dynamic>>> discoverPeers() async {
    try {
      final dynamic result = await _channel.invokeMethod('discoverPeers');

      if (result is! List) {
        return [];
      }

      return result
          .whereType<Map>()
          .map((Map peer) => Map<String, dynamic>.from(peer))
          .toList();
    } on PlatformException catch (error) {
      debugPrint(
        'Wi-Fi Direct discovery error: '
        '${error.code} - ${error.message}',
      );

      return [];
    } on MissingPluginException catch (error) {
      debugPrint('Wi-Fi Direct plugin is unavailable: $error');

      return [];
    } catch (error) {
      debugPrint('Unexpected Wi-Fi Direct discovery error: $error');

      return [];
    }
  }

  /// Sends a connection request to a discovered peer.
  ///
  /// This does not guarantee that the devices are connected.
  /// The other user must accept the request and Android must form
  /// the Wi-Fi Direct group.
  static Future<String> connectToPeer(String deviceAddress) async {
    if (deviceAddress.trim().isEmpty) {
      return 'Device address is missing';
    }

    try {
      final dynamic result = await _channel.invokeMethod('connectToPeer', {
        'deviceAddress': deviceAddress,
      });

      return result?.toString() ?? 'Connection request sent';
    } on PlatformException catch (error) {
      debugPrint(
        'Wi-Fi Direct connection error: '
        '${error.code} - ${error.message}',
      );

      return error.message ?? 'Unable to send connection request';
    } on MissingPluginException catch (error) {
      debugPrint('Wi-Fi Direct plugin is unavailable: $error');

      return 'Wi-Fi Direct is unavailable';
    } catch (error) {
      debugPrint('Unexpected connection error: $error');

      return 'Unable to connect';
    }
  }

  /// Returns the current Wi-Fi Direct group information.
  static Future<Map<String, dynamic>?> getConnectionInfo() async {
    try {
      final dynamic result = await _channel.invokeMethod('getConnectionInfo');

      if (result is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (error) {
      debugPrint(
        'Connection info error: '
        '${error.code} - ${error.message}',
      );

      return null;
    } on MissingPluginException catch (error) {
      debugPrint('Wi-Fi Direct plugin is unavailable: $error');

      return null;
    } catch (error) {
      debugPrint('Unexpected connection info error: $error');

      return null;
    }
  }

  /// Waits until the user accepts the Wi-Fi Direct request and
  /// Android finishes creating the group.
  static Future<Map<String, dynamic>?> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 1),
  }) async {
    final DateTime endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      final Map<String, dynamic>? info = await getConnectionInfo();

      final bool groupFormed = info?['groupFormed'] == true;

      final String groupOwnerAddress =
          info?['groupOwnerAddress']?.toString() ?? '';

      if (groupFormed && groupOwnerAddress.isNotEmpty) {
        return info;
      }

      await Future<void>.delayed(checkInterval);
    }

    return null;
  }

  /// Disconnects the current Wi-Fi Direct group.
  static Future<bool> removeGroup() async {
    try {
      final dynamic result = await _channel.invokeMethod('removeGroup');

      return result == true;
    } on PlatformException catch (error) {
      debugPrint(
        'Remove Wi-Fi Direct group error: '
        '${error.code} - ${error.message}',
      );

      return false;
    } catch (error) {
      debugPrint('Unexpected remove group error: $error');

      return false;
    }
  }
}
