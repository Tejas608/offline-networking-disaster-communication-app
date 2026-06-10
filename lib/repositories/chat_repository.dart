import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ChatRepository {
  /// SERVER SOCKET
  ServerSocket? _serverSocket;

  /// CLIENT SOCKET
  Socket? _socket;

  /// MESSAGE CONTROLLER
  final StreamController<String> _messageController =
      StreamController.broadcast();

  /// MESSAGE STREAM
  Stream<String> get messagesStream => _messageController.stream;

  /// START SERVER
  Future<void> startServer() async {
    try {
      _serverSocket ??= await ServerSocket.bind(InternetAddress.anyIPv4, 8888);

      debugPrint('Server Started on Port 8888');

      _serverSocket!.listen(
        (client) {
          debugPrint('Client Connected: ${client.remoteAddress.address}');

          _socket = client;

          _listenForMessages();
        },
        onError: (error) {
          debugPrint('Server Error: $error');
        },
      );
    } catch (e) {
      debugPrint('Start Server Error: $e');
    }
  }

  /// CONNECT TO SERVER
  Future<void> connectToServer(String ipAddress) async {
    try {
      _socket = await Socket.connect(ipAddress, 8888);

      debugPrint('Connected to Server: $ipAddress');

      _listenForMessages();
    } catch (e) {
      debugPrint('Connection Error: $e');
    }
  }

  /// SEND MESSAGE
  void sendMessage(String message) {
    try {
      if (_socket != null) {
        final jsonMessage = jsonEncode({'message': message});

        _socket!.write('$jsonMessage\n');

        debugPrint('Message Sent: $message');
      } else {
        debugPrint('Send Failed: Socket is null');
      }
    } catch (e) {
      debugPrint('Send Message Error: $e');
    }
  }

  /// LISTEN FOR INCOMING MESSAGES
  void _listenForMessages() {
    try {
      _socket
          ?.cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
              try {
                final decoded = jsonDecode(data);

                final message = decoded['message'];

                _messageController.add(message);

                debugPrint('Message Received: $message');
              } catch (e) {
                debugPrint('JSON Decode Error: $e');
              }
            },
            onError: (error) {
              debugPrint('Socket Listen Error: $error');
            },
            onDone: () {
              debugPrint('Connection Closed');
            },
          );
    } catch (e) {
      debugPrint('Listen Error: $e');
    }
  }

  /// CLOSE CONNECTION
  void dispose() {
    try {
      _socket?.destroy();

      _serverSocket?.close();

      _messageController.close();

      debugPrint('Chat Repository Disposed');
    } catch (e) {
      debugPrint('Dispose Error: $e');
    }
  }
}
