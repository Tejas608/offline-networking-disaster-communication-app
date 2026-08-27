import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_model.dart';
import '../../providers/nearby_users_provider.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final DeviceModel device;

  const DeviceDetailsScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Consumer<NearbyUsersProvider>(
      builder: (
        BuildContext context,
        NearbyUsersProvider provider,
        Widget? child,
      ) {
        final DeviceModel currentDevice =
            provider.getDeviceById(device.id) ?? device;

        final Map<String, dynamic>? connectionInfo = provider.connectionInfo;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F5FA),
          appBar: AppBar(
            title: const Text('Device Details'),
            centerTitle: true,
            backgroundColor: const Color(0xFFFDF7FF),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDeviceHeader(currentDevice),

                const SizedBox(height: 20),

                _buildInformationCard(
                  title: 'Device Information',
                  children: [
                    _buildInformationRow(
                      label: 'Device name',
                      value: currentDevice.displayName,
                    ),
                    _buildInformationRow(
                      label: 'Device address',
                      value: currentDevice.deviceAddress ?? 'Not available',
                    ),
                    _buildInformationRow(
                      label: 'Peer status',
                      value: currentDevice.statusText,
                    ),
                    _buildInformationRow(
                      label: 'Connection',
                      value:
                          currentDevice.isConnected
                              ? 'Connected'
                              : 'Not connected',
                    ),
                    _buildInformationRow(
                      label: 'Group-owner IP',
                      value:
                          currentDevice.ipAddress ??
                          connectionInfo?['groupOwnerAddress']?.toString() ??
                          'Not available',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildInformationCard(
                  title: 'Wi-Fi Direct Group',
                  children: [
                    _buildInformationRow(
                      label: 'Group formed',
                      value:
                          connectionInfo?['groupFormed'] == true ? 'Yes' : 'No',
                    ),
                    _buildInformationRow(
                      label: 'This phone is owner',
                      value:
                          connectionInfo?['isGroupOwner'] == true
                              ? 'Yes'
                              : 'No',
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 51,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context
                          .read<NearbyUsersProvider>()
                          .refreshConnectionInfo();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Connection Info'),
                  ),
                ),

                const SizedBox(height: 12),

                if (currentDevice.isConnected)
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final bool disconnected =
                            await context
                                .read<NearbyUsersProvider>()
                                .disconnect();

                        if (!context.mounted) {
                          return;
                        }

                        if (disconnected) {
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to disconnect.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect Device'),
                    ),
                  ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Wi-Fi Direct creates the '
                          'local network connection. '
                          'TCP socket integration will '
                          'be added next to exchange '
                          'profiles and chat messages.',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceHeader(DeviceModel device) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 43,
            backgroundColor:
                device.isConnected
                    ? Colors.green.shade100
                    : const Color(0xFFEBDDFF),
            child: Icon(
              device.isConnected ? Icons.check_circle : Icons.phone_android,
              size: 43,
              color:
                  device.isConnected
                      ? Colors.green.shade700
                      : const Color(0xFF6D4AB3),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            device.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(
            device.isConnected ? 'Wi-Fi Direct Connected' : device.statusText,
            style: TextStyle(
              color:
                  device.isConnected ? Colors.green.shade700 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInformationRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
