import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';

class PrivateChatScreen extends StatefulWidget {
  final String userName;

  const PrivateChatScreen({super.key, required this.userName});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,

          duration: const Duration(milliseconds: 300),

          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(title: Text(widget.userName), centerTitle: true),

      body: Column(
        children: [
          /// MESSAGE AREA
          Expanded(
            child:
                chatProvider.messages.isEmpty
                    ? const Center(
                      child: Text(
                        'No messages yet',

                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      controller: scrollController,

                      padding: const EdgeInsets.all(12),

                      itemCount: chatProvider.messages.length,

                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];

                        final isMe = message.sender == 'Me';

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,

                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),

                            padding: const EdgeInsets.all(14),

                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),

                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.white,

                              borderRadius: BorderRadius.circular(18),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),

                                  blurRadius: 6,

                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  message.sender,

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    color: isMe ? Colors.white70 : Colors.blue,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  message.text,

                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,

                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.bottomRight,

                                  child: Text(
                                    DateFormat('hh:mm a').format(message.time),

                                    style: TextStyle(
                                      fontSize: 11,

                                      color:
                                          isMe ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          /// INPUT AREA
          Container(
            padding: const EdgeInsets.all(12),

            decoration: const BoxDecoration(
              color: Colors.white,

              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,

                    decoration: InputDecoration(
                      hintText: 'Type message...',

                      filled: true,

                      fillColor: Colors.grey.shade100,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  radius: 26,

                  backgroundColor: Colors.blue,

                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),

                    onPressed: () {
                      if (messageController.text.trim().isEmpty) {
                        return;
                      }

                      chatProvider.sendMessage(messageController.text.trim());

                      messageController.clear();

                      scrollToBottom();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
