import 'package:flutter/material.dart';

import '../nearby/nearby_users_screen.dart';
import '../chat/connection_screen.dart';
import '../sos/sos_screen.dart';
import '../map/location_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget homeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 250,
      height: 55,
      child: ElevatedButton(onPressed: onPressed, child: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Disaster Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'System Active',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            homeButton(
              text: 'Find Nearby Users',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyUsersScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            homeButton(
              text: 'Open Chat',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            homeButton(
              text: 'Send SOS',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            homeButton(
              text: 'My Location',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            homeButton(
              text: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
