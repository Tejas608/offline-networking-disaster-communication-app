import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ChatRepository {
  static const int port = 8888;

  ServerSocket? _serverSocket;
  Socket? _socket;

  StreamSubscription<Socket>? _serverSubscription;

  StreamSubscription<String>? _socketSubscription;

  final StreamController<Map<String, dynamic>> _packetController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get packetStream => _packetController.stream;

  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isServerRunning => _serverSocket != null;

  bool get isConnected => _socket != null;

  String? get remoteIpAddress => _socket?.remoteAddress.address;

  Future<bool> startServer() async {
    if (_serverSocket != null) {
      return true;
    }

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

      debugPrint('TCP server started on port $port');

      _serverSubscription = _serverSocket!.listen(
        (Socket client) async {
          debugPrint(
            'TCP client connected: '
            '${client.remoteAddress.address}',
          );

          await _attachSocket(client);
        },
        onError: (Object error) {
          debugPrint('TCP server error: $error');
        },
        onDone: () {
          debugPrint('TCP server closed');
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        'Unable to start TCP server: '
        '$error',
      );

      return false;
    }
  }

  Future<bool> connectToServer(String ipAddress) async {
    if (ipAddress.trim().isEmpty) {
      return false;
    }

    if (_socket != null) {
      return true;
    }

    try {
      final Socket socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 12),
      );

      debugPrint(
        'TCP connected to '
        '$ipAddress:$port',
      );

      await _attachSocket(socket);

      return true;
    } catch (error) {
      debugPrint('TCP connection error: $error');

      return false;
    }
  }

  Future<void> _attachSocket(Socket socket) async {
    await _socketSubscription?.cancel();

    if (_socket != null && !identical(_socket, socket)) {
      _socket!.destroy();
    }

    _socket = socket;

    _connectionController.add(true);

    final Socket activeSocket = socket;

    _socketSubscription = activeSocket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String data) {
            _processIncomingData(data);
          },
          onError: (Object error) {
            debugPrint('TCP socket error: $error');

            _handleSocketClosed(activeSocket);
          },
          onDone: () {
            debugPrint('TCP connection closed');

            _handleSocketClosed(activeSocket);
          },
          cancelOnError: false,
        );
  }

  void _processIncomingData(String data) {
    try {
      final dynamic decoded = jsonDecode(data);

      if (decoded is! Map) {
        return;
      }

      final Map<String, dynamic> packet = Map<String, dynamic>.from(decoded);

      _packetController.add(packet);

      debugPrint(
        'TCP packet received: '
        '${packet['type']}',
      );
    } catch (error) {
      debugPrint('TCP JSON decode error: $error');
    }
  }

  Future<bool> sendPacket(Map<String, dynamic> packet) async {
    final Socket? socket = _socket;

    if (socket == null) {
      debugPrint(
        'Cannot send packet: '
        'socket is not connected',
      );

      return false;
    }

    try {
      final String encodedPacket = '${jsonEncode(packet)}\n';

      socket.add(utf8.encode(encodedPacket));

      await socket.flush();

      debugPrint(
        'TCP packet sent: '
        '${packet['type']}',
      );

      return true;
    } catch (error) {
      debugPrint('TCP send error: $error');

      return false;
    }
  }

  void _handleSocketClosed(Socket socket) {
    if (!identical(_socket, socket)) {
      return;
    }

    _socket = null;
    _connectionController.add(false);
  }

  Future<void> disconnectSocket() async {
    await _socketSubscription?.cancel();

    _socketSubscription = null;

    _socket?.destroy();
    _socket = null;

    _connectionController.add(false);
  }

  Future<void> dispose() async {
    await disconnectSocket();

    await _serverSubscription?.cancel();
    _serverSubscription = null;

    await _serverSocket?.close();
    _serverSocket = null;

    await _packetController.close();
    await _connectionController.close();
  }
}
