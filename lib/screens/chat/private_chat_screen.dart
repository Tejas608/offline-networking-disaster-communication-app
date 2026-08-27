import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';

class PrivateChatScreen extends StatefulWidget {
  final UserModel user;

  const PrivateChatScreen({super.key, required this.user});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().openConversation(widget.user);

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final ChatProvider provider = context.read<ChatProvider>();

    final bool sent = await provider.sendMessage(text);

    if (!mounted) {
      return;
    }

    if (sent) {
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(provider.errorMessage ?? 'Message could not be sent.'),
        ),
      );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (
        BuildContext context,
        ChatProvider chatProvider,
        Widget? child,
      ) {
        final bool isOnline =
            chatProvider.isConnected &&
            chatProvider.currentPeer?.deviceId == widget.user.deviceId;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text(widget.user.displayName),
                if (widget.user.secondaryLabel != null)
                  Text(
                    widget.user.secondaryLabel!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child:
                    chatProvider.isLoadingMessages
                        ? const Center(child: CircularProgressIndicator())
                        : chatProvider.messages.isEmpty
                        ? const Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 17, color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final MessageModel message =
                                chatProvider.messages[index];

                            return _buildMessageBubble(context, message);
                          },
                        ),
              ),

              _buildInputArea(isOnline),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message) {
    final bool isMe = message.isOutgoing;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.77,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF7152B8) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7152B8),
                ),
              ),
              const SizedBox(height: 5),
            ],

            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.time),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),

                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    message.deliveryStatus == 'failed'
                        ? Icons.error_outline
                        : Icons.done,
                    size: 14,
                    color:
                        message.deliveryStatus == 'failed'
                            ? Colors.redAccent
                            : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isOnline) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: isOnline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText:
                      isOnline
                          ? 'Type message...'
                          : 'Reconnect to send messages',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 9),

            CircleAvatar(
              radius: 25,
              backgroundColor: isOnline ? const Color(0xFF7152B8) : Colors.grey,
              child: IconButton(
                onPressed: isOnline ? _sendMessage : null,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
