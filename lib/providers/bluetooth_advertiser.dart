import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BluetoothAdvertiser extends ChangeNotifier {
  /// BLE PERIPHERAL INSTANCE
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  /// ADVERTISING STATUS
  bool isAdvertising = false;

  /// USER DEVICE NAME
  String deviceName = '';

  /// START ADVERTISING
  Future<void> startAdvertising({required String username}) async {
    try {
      /// CREATE UNIQUE APP IDENTITY
      deviceName = 'OFFLINE_NET_$username';

      /// BLE ADVERTISEMENT DATA
      final advertiseData = AdvertiseData(
        includeDeviceName: true,

        serviceUuid: '12345678-1234-5678-1234-56789abcdef0',
      );

      /// BLE ADVERTISE SETTINGS
      final advertiseSettings = AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,

        timeout: 0,

        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,

        connectable: true,
      );

      /// START BLE ADVERTISING
      await blePeripheral.start(
        advertiseData: advertiseData,

        advertiseSettings: advertiseSettings,
      );

      isAdvertising = true;

      notifyListeners();

      debugPrint('Advertising Started: $deviceName');
    } catch (e) {
      debugPrint('Advertising Error: $e');
    }
  }

  /// STOP ADVERTISING
  Future<void> stopAdvertising() async {
    try {
      await blePeripheral.stop();

      isAdvertising = false;

      notifyListeners();

      debugPrint('Advertising Stopped');
    } catch (e) {
      debugPrint('Stop Advertising Error: $e');
    }
  }
}
