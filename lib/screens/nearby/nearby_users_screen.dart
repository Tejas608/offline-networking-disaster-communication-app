import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:provider/provider.dart';

import '../../providers/bluetooth_provider.dart';

import '../../providers/chat_provider.dart';

import '../chat/private_chat_screen.dart';

import '../../core/services/wifi_direct_service.dart';

class NearbyUsersScreen extends StatelessWidget {
  const NearbyUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(title: const Text('Nearby Users'), centerTitle: true),

      body: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                const SizedBox(height: 20),

                /// TITLE
                const Text(
                  'Discover Nearby Devices',

                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  'Scan nearby users using Bluetooth and offline networking.',

                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),

                const SizedBox(height: 30),

                /// SCANNING ANIMATION
                if (bluetoothProvider.isScanning)
                  Column(
                    children: [
                      const SpinKitRipple(color: Colors.blue, size: 140),

                      const SizedBox(height: 20),

                      const Text(
                        'Scanning nearby devices...',

                        style: TextStyle(
                          fontSize: 16,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                /// SCAN BUTTON
                if (!bluetoothProvider.isScanning)
                  SizedBox(
                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton.icon(
                      onPressed: () async {
                        /// START BLUETOOTH SCAN
                        await bluetoothProvider.startScan();

                        /// START WIFI DIRECT DISCOVERY
                        final peers = await WifiDirectService.discoverPeers();

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nearby Peers Found: ${peers.length}',
                            ),
                          ),
                        );
                      },

                      icon: const Icon(Icons.radar, color: Colors.white),

                      label: const Text(
                        'Scan Devices',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                /// DEVICE LIST
                Expanded(
                  child:
                      bluetoothProvider.nearbyDevices.isEmpty
                          ? Center(
                            child: Text(
                              bluetoothProvider.isScanning
                                  ? ''
                                  : 'No nearby devices found',

                              style: TextStyle(
                                color: Colors.grey.shade600,

                                fontSize: 16,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: bluetoothProvider.nearbyDevices.length,

                            itemBuilder: (context, index) {
                              final device =
                                  bluetoothProvider.nearbyDevices[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),

                                padding: const EdgeInsets.all(16),

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

                                      backgroundColor: Colors.blue.withOpacity(
                                        0.15,
                                      ),

                                      child: const Icon(
                                        Icons.devices,

                                        color: Colors.blue,

                                        size: 30,
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            device.name.replaceFirst(
                                              'OFFLINE_NET_',
                                              '',
                                            ),

                                            style: const TextStyle(
                                              fontSize: 17,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 5),

                                          Text(
                                            'Signal Strength: ${device.rssi}',

                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// CONNECT BUTTON
                                    ElevatedButton(
                                      onPressed: () async {
                                        /// CONNECT WIFI DIRECT
                                        final result =
                                            await WifiDirectService.connectToPeer(
                                              device.deviceAddress!,
                                            );

                                        debugPrint(result);

                                        /// WAIT FOR GROUP FORMATION
                                        await Future.delayed(
                                          const Duration(seconds: 5),
                                        );

                                        /// GET CONNECTION INFO
                                        final connectionInfo =
                                            await WifiDirectService.getConnectionInfo();

                                        debugPrint(
                                          'Connection Info: '
                                          '$connectionInfo',
                                        );

                                        if (connectionInfo == null) {
                                          return;
                                        }

                                        /// GET REAL GROUP OWNER IP
                                        final groupOwnerIp =
                                            connectionInfo['groupOwnerAddress'];

                                        debugPrint('REAL IP: $groupOwnerIp');

                                        /// CHAT PROVIDER
                                        final chatProvider =
                                            Provider.of<ChatProvider>(
                                              context,
                                              listen: false,
                                            );

                                        /// AUTO SOCKET CONNECT
                                        await chatProvider.connectToPeer(
                                          groupOwnerIp,
                                          device.name,
                                        );

                                        if (!context.mounted) {
                                          return;
                                        }

                                        /// OPEN CHAT SCREEN
                                        Navigator.push(
                                          context,

                                          MaterialPageRoute(
                                            builder:
                                                (_) => PrivateChatScreen(
                                                  userName: device.name
                                                      .replaceFirst(
                                                        'OFFLINE_NET_',
                                                        '',
                                                      ),
                                                ),
                                          ),
                                        );
                                      },

                                      child: const Text(
                                        'Connect',

                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),

                /// STOP BUTTON
                if (bluetoothProvider.isScanning)
                  SizedBox(
                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(
                      onPressed: () async {
                        await bluetoothProvider.stopScan();
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      child: const Text(
                        'Stop Scan',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
