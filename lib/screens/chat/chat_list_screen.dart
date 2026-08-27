import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import 'private_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConnectedUsers();
    });
  }

  Future<void> _openChat(UserModel user) async {
    final ChatProvider chatProvider = context.read<ChatProvider>();

    await chatProvider.openConversation(user);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PrivateChatScreen(user: user)),
    );

    if (!mounted) {
      return;
    }

    await chatProvider.loadConnectedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: AppBar(
        title: const Text('Open Chat'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDF7FF),
      ),
      body: Consumer<ChatProvider>(
        builder: (
          BuildContext context,
          ChatProvider chatProvider,
          Widget? child,
        ) {
          final List<UserModel> users = chatProvider.connectedUsers;

          if (users.isEmpty) {
            return RefreshIndicator(
              onRefresh: chatProvider.loadConnectedUsers,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 75,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 18),
                  Center(
                    child: Text(
                      'No connected users yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 9),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 35),
                    child: Text(
                      'Open Find Nearby Users, '
                      'connect to another phone, '
                      'and complete the TCP '
                      'profile exchange.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: chatProvider.loadConnectedUsers,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final UserModel user = users[index];

                return _buildUserCard(user);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final String timeText;

    if (user.lastMessageAt != null) {
      timeText = DateFormat('hh:mm a').format(user.lastMessageAt!);
    } else if (user.lastConnectedAt != null) {
      timeText = DateFormat('dd MMM').format(user.lastConnectedAt!);
    } else {
      timeText = '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openChat(user),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: const Color(0xFFEBDDFF),
                  child: Text(
                    user.displayName.isEmpty
                        ? '?'
                        : user.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D4AB3),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (user.secondaryLabel != null) ...[
                    Text(
                      user.secondaryLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    user.lastMessage ??
                        (user.isOnline
                            ? 'Connected'
                            : 'Tap to view chat history'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          user.isOnline
                              ? Colors.green.shade700
                              : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              timeText,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
