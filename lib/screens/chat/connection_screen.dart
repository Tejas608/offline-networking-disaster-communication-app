import 'package:flutter/material.dart';

import 'chat_list_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool isScanning = false;

  final List<String> nearbyUsers = [];

  /// FAKE SCAN
  Future<void> scanNearbyUsers() async {
    setState(() {
      isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    nearbyUsers.clear();

    nearbyUsers.addAll(['Rahul Phone', 'Emergency Rescue', 'Tejas Device']);

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Nearby Users')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),

              label: Text(isScanning ? 'Scanning...' : 'Scan Nearby Users'),

              onPressed: isScanning ? null : scanNearbyUsers,
            ),

            const SizedBox(height: 20),

            if (isScanning) const CircularProgressIndicator(),

            const SizedBox(height: 20),

            Expanded(
              child:
                  nearbyUsers.isEmpty
                      ? const Center(child: Text('No nearby users found'))
                      : ListView.builder(
                        itemCount: nearbyUsers.length,

                        itemBuilder: (context, index) {
                          final user = nearbyUsers[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),

                              title: Text(user),

                              subtitle: const Text('Offline User Detected'),

                              trailing: ElevatedButton(
                                child: const Text('Connect'),

                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Connected to $user'),
                                    ),
                                  );

                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder: (_) => const ChatListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
