import 'package:flutter/foundation.dart';

import '../core/services/wifi_direct_service.dart';
import '../models/device_model.dart';

class NearbyUsersProvider extends ChangeNotifier {
  final List<DeviceModel> _nearbyUsers = [];

  bool _isScanning = false;
  String? _connectingDeviceId;
  String? _errorMessage;
  String? _statusMessage;

  Map<String, dynamic>? _connectionInfo;

  List<DeviceModel> get nearbyUsers {
    return List<DeviceModel>.unmodifiable(_nearbyUsers);
  }

  bool get isScanning => _isScanning;

  String? get connectingDeviceId {
    return _connectingDeviceId;
  }

  String? get errorMessage => _errorMessage;

  String? get statusMessage => _statusMessage;

  Map<String, dynamic>? get connectionInfo {
    return _connectionInfo == null
        ? null
        : Map<String, dynamic>.unmodifiable(_connectionInfo!);
  }

  bool isConnectingTo(String deviceId) {
    return _connectingDeviceId == deviceId;
  }

  DeviceModel? getDeviceById(String deviceId) {
    for (final DeviceModel device in _nearbyUsers) {
      if (device.id == deviceId) {
        return device;
      }
    }

    return null;
  }

  /// Scans real Wi-Fi Direct peers.
  Future<void> scanNearbyUsers() async {
    if (_isScanning) {
      return;
    }

    _isScanning = true;
    _errorMessage = null;
    _statusMessage = 'Searching for nearby Wi-Fi Direct devices...';

    notifyListeners();

    try {
      final List<Map<String, dynamic>> peerData =
          await WifiDirectService.discoverPeers();

      final Map<String, DeviceModel> uniqueDevices = {};

      for (final Map<String, dynamic> data in peerData) {
        final DeviceModel device = DeviceModel.fromWifiDirectMap(data);

        if (!device.hasValidDeviceAddress) {
          continue;
        }

        uniqueDevices[device.id] = device;
      }

      _nearbyUsers
        ..clear()
        ..addAll(uniqueDevices.values);

      _nearbyUsers.sort((DeviceModel first, DeviceModel second) {
        return first.displayName.toLowerCase().compareTo(
          second.displayName.toLowerCase(),
        );
      });

      if (_nearbyUsers.isEmpty) {
        _statusMessage = 'No nearby Wi-Fi Direct devices found.';
      } else {
        _statusMessage =
            '${_nearbyUsers.length} nearby '
            '${_nearbyUsers.length == 1 ? 'device' : 'devices'} found.';
      }
    } catch (error, stackTrace) {
      debugPrint('Nearby user scanning failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      _nearbyUsers.clear();

      _errorMessage =
          'Unable to scan nearby devices. '
          'Make sure Wi-Fi and nearby-device '
          'permissions are enabled.';

      _statusMessage = null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Sends a Wi-Fi Direct connection request and waits
  /// until Android finishes forming the Wi-Fi Direct group.
  Future<bool> connectToDevice(DeviceModel device) async {
    if (_connectingDeviceId != null) {
      return false;
    }

    if (!device.hasValidDeviceAddress) {
      _errorMessage =
          'This device does not have a valid '
          'Wi-Fi Direct address.';

      notifyListeners();
      return false;
    }

    _connectingDeviceId = device.id;
    _errorMessage = null;
    _statusMessage =
        'Sending connection request to '
        '${device.displayName}...';

    notifyListeners();

    try {
      final String requestResult = await WifiDirectService.connectToPeer(
        device.deviceAddress!,
      );

      debugPrint(
        'Wi-Fi Direct request result: '
        '$requestResult',
      );

      _statusMessage =
          'Waiting for ${device.displayName} '
          'to accept the connection...';

      notifyListeners();

      final Map<String, dynamic>? info =
          await WifiDirectService.waitForConnection(
            timeout: const Duration(seconds: 40),
            checkInterval: const Duration(seconds: 1),
          );

      if (info == null) {
        _errorMessage =
            'Connection timed out. The other '
            'phone may not have accepted the request.';

        _statusMessage = null;
        return false;
      }

      final bool groupFormed = info['groupFormed'] == true;

      final String groupOwnerAddress =
          info['groupOwnerAddress']?.toString().trim() ?? '';

      if (!groupFormed) {
        _errorMessage = 'Wi-Fi Direct group was not formed.';

        _statusMessage = null;
        return false;
      }

      _connectionInfo = Map<String, dynamic>.from(info);

      _updateDevice(
        device.id,
        device.copyWith(
          isConnected: true,
          statusText: 'Connected',
          ipAddress: groupOwnerAddress.isNotEmpty ? groupOwnerAddress : null,
        ),
      );

      _statusMessage = 'Connected to ${device.displayName}.';

      return true;
    } catch (error, stackTrace) {
      debugPrint('Wi-Fi Direct connection failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage =
          'Unable to connect to '
          '${device.displayName}.';

      _statusMessage = null;

      return false;
    } finally {
      _connectingDeviceId = null;
      notifyListeners();
    }
  }

  /// Reads the latest connection information.
  Future<Map<String, dynamic>?> refreshConnectionInfo() async {
    try {
      final Map<String, dynamic>? info =
          await WifiDirectService.getConnectionInfo();

      _connectionInfo = info;

      if (info != null && info['groupFormed'] == true) {
        _statusMessage = 'Wi-Fi Direct connection is active.';
      }

      notifyListeners();

      return info;
    } catch (error) {
      _errorMessage =
          'Could not read Wi-Fi Direct '
          'connection information.';

      notifyListeners();

      return null;
    }
  }

  /// Disconnects the current Wi-Fi Direct group.
  Future<bool> disconnect() async {
    _errorMessage = null;
    _statusMessage = 'Disconnecting Wi-Fi Direct group...';

    notifyListeners();

    final bool removed = await WifiDirectService.removeGroup();

    if (removed) {
      _connectionInfo = null;

      for (int index = 0; index < _nearbyUsers.length; index++) {
        _nearbyUsers[index] = _nearbyUsers[index].copyWith(
          isConnected: false,
          statusText: 'Available',
        );
      }

      _statusMessage = 'Disconnected.';
    } else {
      _errorMessage =
          'Unable to disconnect the '
          'Wi-Fi Direct group.';

      _statusMessage = null;
    }

    notifyListeners();

    return removed;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearNearbyUsers() {
    _nearbyUsers.clear();
    _errorMessage = null;
    _statusMessage = null;

    notifyListeners();
  }

  void _updateDevice(String deviceId, DeviceModel updatedDevice) {
    final int index = _nearbyUsers.indexWhere(
      (DeviceModel device) => device.id == deviceId,
    );

    if (index == -1) {
      _nearbyUsers.add(updatedDevice);
    } else {
      _nearbyUsers[index] = updatedDevice;
    }
  }
}
