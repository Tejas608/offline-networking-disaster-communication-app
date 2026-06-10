import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device_model.dart';

import '../repositories/discovery_repository.dart';

import '../core/utils/network_utils.dart';

class BluetoothProvider extends ChangeNotifier {
  /// NEARBY USERS
  List<DeviceModel> nearbyDevices = [];

  /// SCANNING STATUS
  bool isScanning = false;

  /// BLUETOOTH SCAN SUBSCRIPTION
  StreamSubscription<List<ScanResult>>? scanSubscription;

  /// DISCOVERY REPOSITORY
  final DiscoveryRepository discoveryRepository = DiscoveryRepository();

  /// YOUR USERNAME
  final String localUserName = 'Tejas';

  /// START SCAN
  Future<void> startScan() async {
    try {
      /// CLEAR OLD DEVICES
      nearbyDevices.clear();

      isScanning = true;

      notifyListeners();

      /// GET LOCAL DEVICE IP
      final localIp = await NetworkUtils.getLocalIpAddress();

      /// START BROADCASTING
      await discoveryRepository.startBroadcast(
        username: 'OFFLINE_NET_$localUserName',

        ipAddress: localIp,
      );

      /// START LISTENING
      await discoveryRepository.startListening((data) {
        final device = DeviceModel(
          id: data['ip'] ?? '',

          name: data['username'] ?? 'Unknown User',

          rssi: data['rssi'] ?? -50,

          ipAddress: data['ip'] ?? '',

          /// WIFI DIRECT ADDRESS
          deviceAddress: data['deviceAddress'] ?? '',
        );

        /// AVOID DUPLICATES
        final exists = nearbyDevices.any(
          (d) => d.ipAddress == device.ipAddress,
        );

        if (!exists) {
          nearbyDevices.add(device);

          notifyListeners();
        }
      });

      /// START BLUETOOTH SCAN
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      /// LISTEN TO BLUETOOTH RESULTS
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final deviceName = result.device.platformName;

          if (deviceName.startsWith('OFFLINE_NET_')) {
            debugPrint('Bluetooth Found: $deviceName');

            final exists = nearbyDevices.any(
              (d) => d.id == result.device.remoteId.str,
            );

            if (!exists) {
              nearbyDevices.add(
                DeviceModel(
                  id: result.device.remoteId.str,

                  name: deviceName,

                  rssi: result.rssi,

                  ipAddress: 'Unknown',

                  deviceAddress: result.device.remoteId.str,
                ),
              );

              notifyListeners();
            }
          }
        }
      });

      /// WAIT FOR SCAN COMPLETE
      await Future.delayed(const Duration(seconds: 10));

      isScanning = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Bluetooth Scan Error: $e');
    }
  }

  /// STOP SCAN
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();

      await scanSubscription?.cancel();

      discoveryRepository.dispose();

      isScanning = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Stop Scan Error: $e');
    }
  }
}
