import 'package:flutter/material.dart';

import '../models/message_model.dart';

import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  /// CHAT REPOSITORY
  final ChatRepository _chatRepository = ChatRepository();

  /// CHAT MESSAGES
  final List<MessageModel> _messages = [];

  List<MessageModel> get messages => _messages;

  /// CURRENT CONNECTED USER
  String currentUser = 'Remote User';

  ChatProvider() {
    /// AUTO START SERVER
    startServer();

    /// LISTEN FOR INCOMING MESSAGES
    _chatRepository.messagesStream.listen((message) {
      final receivedMessage = MessageModel(
        sender: currentUser,

        text: message,

        time: DateTime.now(),
      );

      _messages.add(receivedMessage);

      notifyListeners();
    });
  }

  /// START SERVER
  Future<void> startServer() async {
    await _chatRepository.startServer();
  }

  /// CONNECT TO PEER
  Future<void> connectToPeer(String ipAddress, String userName) async {
    currentUser = userName;

    await _chatRepository.connectToServer(ipAddress);

    notifyListeners();
  }

  /// SEND MESSAGE
  void sendMessage(String text) {
    /// SEND THROUGH SOCKET
    _chatRepository.sendMessage(text);

    /// LOCAL UI MESSAGE
    final message = MessageModel(
      sender: 'Me',

      text: text,

      time: DateTime.now(),
    );

    _messages.add(message);

    notifyListeners();
  }

  /// CLEAR CHAT
  void clearChat() {
    _messages.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    _chatRepository.dispose();

    super.dispose();
  }
}
