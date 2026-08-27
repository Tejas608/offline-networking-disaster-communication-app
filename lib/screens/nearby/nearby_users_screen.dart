import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_model.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/nearby_users_provider.dart';
import '../chat/private_chat_screen.dart';
import 'device_details_screen.dart';

class NearbyUsersScreen extends StatelessWidget {
  const NearbyUsersScreen({super.key});

  Future<void> _startScan(BuildContext context) async {
    final NearbyUsersProvider provider = context.read<NearbyUsersProvider>();

    await provider.scanNearbyUsers();

    if (!context.mounted) {
      return;
    }

    final String message;

    if (provider.errorMessage != null) {
      message = provider.errorMessage!;
    } else if (provider.nearbyUsers.isEmpty) {
      message = 'No nearby Wi-Fi Direct devices found.';
    } else {
      message =
          '${provider.nearbyUsers.length} nearby '
          '${provider.nearbyUsers.length == 1 ? 'device' : 'devices'} found.';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _connectToDevice(
    BuildContext context,
    DeviceModel device,
  ) async {
    final NearbyUsersProvider nearbyProvider =
        context.read<NearbyUsersProvider>();

    final ChatProvider chatProvider = context.read<ChatProvider>();

    final bool wifiConnected = await nearbyProvider.connectToDevice(device);

    if (!context.mounted) {
      return;
    }

    if (!wifiConnected) {
      _showError(
        context,
        nearbyProvider.errorMessage ?? 'Wi-Fi Direct connection failed.',
      );

      return;
    }

    final Map<String, dynamic>? connectionInfo = nearbyProvider.connectionInfo;

    if (connectionInfo == null || connectionInfo['groupFormed'] != true) {
      _showError(
        context,
        'Wi-Fi Direct group information '
        'is unavailable.',
      );

      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Wi-Fi Direct connected. '
            'Starting TCP chat...',
          ),
        ),
      );

    final UserModel? connectedUser = await chatProvider
        .completeWifiDirectConnection(
          connectionInfo: connectionInfo,
          fallbackDeviceName: device.displayName,
          deviceAddress: device.deviceAddress,
        );

    if (!context.mounted) {
      return;
    }

    if (connectedUser == null) {
      _showError(
        context,
        chatProvider.errorMessage ?? 'TCP profile exchange failed.',
      );

      return;
    }

    await chatProvider.openConversation(connectedUser);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Connected to '
            '${connectedUser.displayName}.',
          ),
        ),
      );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivateChatScreen(user: connectedUser),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(message)),
      );
  }

  void _openDeviceDetails(BuildContext context, DeviceModel device) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceDetailsScreen(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: AppBar(
        title: const Text('Find Nearby Users'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDF7FF),
      ),
      body: Consumer<NearbyUsersProvider>(
        builder: (
          BuildContext context,
          NearbyUsersProvider provider,
          Widget? child,
        ) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                children: [
                  _buildHeader(),

                  const SizedBox(height: 22),

                  _buildScanButton(context, provider),

                  const SizedBox(height: 16),

                  if (provider.statusMessage != null)
                    _buildStatusMessage(
                      provider.statusMessage!,
                      isError: false,
                    ),

                  if (provider.errorMessage != null)
                    _buildStatusMessage(provider.errorMessage!, isError: true),

                  const SizedBox(height: 14),

                  Expanded(child: _buildDeviceArea(context, provider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Color(0xFFEDE1FF),
            child: Icon(
              Icons.wifi_tethering,
              size: 34,
              color: Color(0xFF6D4AB3),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Discover Nearby Devices',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Find nearby phones using '
            'Wi-Fi Direct. Internet and a '
            'Wi-Fi router are not required.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, NearbyUsersProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: provider.isScanning ? null : () => _startScan(context),
        icon:
            provider.isScanning
                ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
                : const Icon(Icons.radar, color: Colors.white),
        label: Text(
          provider.isScanning
              ? 'Scanning Nearby Devices...'
              : 'Scan Nearby Users',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7152B8),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD4C8E8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message, {required bool isError}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceArea(BuildContext context, NearbyUsersProvider provider) {
    if (provider.isScanning && provider.nearbyUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Scanning nearby devices...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (provider.nearbyUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_other_outlined, size: 68, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No nearby users found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Turn on Wi-Fi on both phones '
              'and press Scan Nearby Users.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.scanNearbyUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.nearbyUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 13),
        itemBuilder: (BuildContext context, int index) {
          final DeviceModel device = provider.nearbyUsers[index];

          return _buildDeviceCard(context, provider, device);
        },
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    NearbyUsersProvider provider,
    DeviceModel device,
  ) {
    final bool isConnecting = provider.isConnectingTo(device.id);

    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () => _openDeviceDetails(context, device),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color:
                device.isConnected
                    ? Colors.green.shade300
                    : const Color(0xFFE9E1F1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  device.isConnected
                      ? Colors.green.shade100
                      : const Color(0xFFEBDDFF),
              child: Icon(
                device.isConnected ? Icons.check_circle : Icons.phone_android,
                color:
                    device.isConnected
                        ? Colors.green.shade700
                        : const Color(0xFF6D4AB3),
                size: 29,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    device.isConnected ? 'Connected' : device.statusText,
                    style: TextStyle(
                      color:
                          device.isConnected
                              ? Colors.green.shade700
                              : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              height: 43,
              child: ElevatedButton(
                onPressed:
                    device.isConnected || isConnecting
                        ? null
                        : () => _connectToDevice(context, device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7152B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child:
                    isConnecting
                        ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                        : Text(device.isConnected ? 'Connected' : 'Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
