import 'package:flutter/material.dart';

import 'private_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// TEMP CONNECTED USERS
    final connectedUsers = ['Rahul', 'Tejas', 'Emergency Team'];

    return Scaffold(
      appBar: AppBar(title: const Text('Connected Chats')),

      body:
          connectedUsers.isEmpty
              ? const Center(
                child: Text(
                  'No connected users',

                  style: TextStyle(fontSize: 18),
                ),
              )
              : ListView.builder(
                itemCount: connectedUsers.length,

                itemBuilder: (context, index) {
                  final user = connectedUsers[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),

                      title: Text(user),

                      subtitle: const Text('Tap to open chat'),

                      trailing: const Icon(Icons.chat),

                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => PrivateChatScreen(userName: user),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
