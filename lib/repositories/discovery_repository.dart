import 'dart:async';

import 'dart:convert';

import 'dart:io';

class DiscoveryRepository {
  static const int discoveryPort = 8888;

  RawDatagramSocket? receiverSocket;

  Timer? broadcastTimer;

  /// START BROADCASTING DEVICE INFO
  Future<void> startBroadcast({
    required String username,

    required String ipAddress,
  }) async {
    broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final message = jsonEncode({'username': username, 'ip': ipAddress});

      sender.send(
        utf8.encode(message),

        InternetAddress('255.255.255.255'),

        discoveryPort,
      );

      sender.close();
    });
  }

  /// START LISTENING FOR DEVICES
  Future<void> startListening(
    Function(Map<String, dynamic>) onDeviceFound,
  ) async {
    receiverSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,

      discoveryPort,

      reuseAddress: true,

      reusePort: true,
    );

    receiverSocket!.broadcastEnabled = true;

    receiverSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final packet = receiverSocket!.receive();

        if (packet != null) {
          final message = utf8.decode(packet.data);

          final data = jsonDecode(message);

          onDeviceFound(data);
        }
      }
    });
  }

  /// STOP DISCOVERY
  void dispose() {
    broadcastTimer?.cancel();

    receiverSocket?.close();
  }
}
