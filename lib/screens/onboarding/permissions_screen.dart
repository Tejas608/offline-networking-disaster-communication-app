import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import '../home/home_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  /// REQUEST ALL PERMISSIONS
  Future<void> requestPermissions(BuildContext context) async {
    /// BLUETOOTH
    await Permission.bluetooth.request();

    /// BLUETOOTH CONNECT
    await Permission.bluetoothConnect.request();

    /// BLUETOOTH SCAN
    await Permission.bluetoothScan.request();

    /// LOCATION
    await Permission.location.request();

    /// NOTIFICATION
    await Permission.notification.request();

    /// WIFI DEVICES
    await Permission.nearbyWifiDevices.request();

    if (!context.mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// PERMISSION CARD
  Widget permissionCard({
    required IconData icon,

    required String title,

    required String subtitle,

    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 28,

            backgroundColor: color.withOpacity(0.15),

            child: Icon(icon, color: color, size: 30),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,

                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(title: const Text('Permissions'), centerTitle: true),

      /// FIXED OVERFLOW HERE
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                const SizedBox(height: 10),

                const Text(
                  'Allow Required Permissions',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  'These permissions are required '
                  'for offline communication, '
                  'mesh networking, live maps '
                  'and emergency alerts.',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 30),

                /// BLUETOOTH
                permissionCard(
                  icon: Icons.bluetooth,

                  title: 'Bluetooth Access',

                  subtitle:
                      'Required to discover and '
                      'connect nearby devices.',

                  color: Colors.blue,
                ),

                /// WIFI
                permissionCard(
                  icon: Icons.wifi,

                  title: 'WiFi Mesh Connection',

                  subtitle:
                      'Required for offline mesh '
                      'communication and data sharing.',

                  color: Colors.orange,
                ),

                /// LOCATION
                permissionCard(
                  icon: Icons.location_on,

                  title: 'Location Access',

                  subtitle:
                      'Required for live map tracking '
                      'and nearby users.',

                  color: Colors.red,
                ),

                /// NOTIFICATIONS
                permissionCard(
                  icon: Icons.notifications_active,

                  title: 'Notifications',

                  subtitle:
                      'Required for SOS alerts, '
                      'messages and emergency updates.',

                  color: Colors.green,
                ),

                /// NEARBY DEVICES
                permissionCard(
                  icon: Icons.devices,

                  title: 'Nearby Devices',

                  subtitle:
                      'Required to detect nearby '
                      'phones during emergencies.',

                  color: Colors.purple,
                ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,

                  height: 58,

                  child: ElevatedButton(
                    onPressed: () => requestPermissions(context),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    child: const Text(
                      'Allow All Permissions',

                      style: TextStyle(
                        fontSize: 18,

                        color: Colors.white,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
