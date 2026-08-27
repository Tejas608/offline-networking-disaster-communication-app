import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/wifi_direct_service.dart';
import '../database/database_helper.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final List<MessageModel> _messages = [];

  final List<UserModel> _connectedUsers = [];

  StreamSubscription<Map<String, dynamic>>? _packetSubscription;

  StreamSubscription<bool>? _connectionSubscription;

  Timer? _wifiDirectTimer;

  Future<void>? _initializationFuture;

  UserModel? _currentPeer;

  String _localUserId = '';
  String _localName = '';
  String _localPhone = '';

  bool _isSocketConnected = false;
  bool _isLoadingMessages = false;
  bool _isConnectingSocket = false;
  bool _checkingWifiDirect = false;

  String? _errorMessage;

  String? _pendingDeviceName;
  String? _pendingDeviceAddress;
  String? _pendingIpAddress;

  Completer<UserModel>? _profileCompleter;

  List<MessageModel> get messages => List.unmodifiable(_messages);

  List<UserModel> get connectedUsers => List.unmodifiable(_connectedUsers);

  UserModel? get currentPeer => _currentPeer;

  bool get isConnected => _isSocketConnected;

  bool get isLoadingMessages => _isLoadingMessages;

  bool get isConnectingSocket => _isConnectingSocket;

  String? get errorMessage => _errorMessage;

  String get localUserId => _localUserId;

  String get localName => _localName;

  ChatProvider() {
    _packetSubscription = _chatRepository.packetStream.listen((
      Map<String, dynamic> packet,
    ) {
      unawaited(_handlePacket(packet));
    });

    _connectionSubscription = _chatRepository.connectionStream.listen((
      bool connected,
    ) {
      _handleConnectionChanged(connected);
    });

    unawaited(initialize());
  }

  Future<void> initialize() {
    return _initializationFuture ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    await refreshLocalProfile();

    await _chatRepository.startServer();

    await loadConnectedUsers();

    _startWifiDirectMonitor();
  }

  Future<void> refreshLocalProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _localName = prefs.getString('name')?.trim() ?? '';

    _localPhone = prefs.getString('phone')?.trim() ?? '';

    String? localUserId = prefs.getString('localUserId');

    if (localUserId == null || localUserId.isEmpty) {
      localUserId = 'user_${DateTime.now().microsecondsSinceEpoch}';

      await prefs.setString('localUserId', localUserId);
    }

    _localUserId = localUserId;

    notifyListeners();
  }

  void _startWifiDirectMonitor() {
    _wifiDirectTimer?.cancel();

    _wifiDirectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_checkWifiDirectConnection());
    });

    unawaited(_checkWifiDirectConnection());
  }

  Future<void> _checkWifiDirectConnection() async {
    if (_checkingWifiDirect || _isSocketConnected || _isConnectingSocket) {
      return;
    }

    _checkingWifiDirect = true;

    try {
      final Map<String, dynamic>? info =
          await WifiDirectService.getConnectionInfo();

      if (info == null || info['groupFormed'] != true) {
        return;
      }

      await activateWifiDirectConnection(info);
    } finally {
      _checkingWifiDirect = false;
    }
  }

  Future<bool> activateWifiDirectConnection(
    Map<String, dynamic> connectionInfo, {
    String? fallbackDeviceName,
    String? deviceAddress,
  }) async {
    await initialize();

    _pendingDeviceName = fallbackDeviceName ?? _pendingDeviceName;

    _pendingDeviceAddress = deviceAddress ?? _pendingDeviceAddress;

    final bool isGroupOwner = connectionInfo['isGroupOwner'] == true;

    final String groupOwnerIp =
        connectionInfo['groupOwnerAddress']?.toString().trim() ?? '';

    _pendingIpAddress = groupOwnerIp;

    if (isGroupOwner) {
      final bool serverStarted = await _chatRepository.startServer();

      if (!serverStarted) {
        _errorMessage = 'Unable to start the TCP server.';

        notifyListeners();
        return false;
      }

      if (_chatRepository.isConnected) {
        await _sendProfilePacket();
      }

      return true;
    }

    if (groupOwnerIp.isEmpty) {
      _errorMessage = 'Group owner IP address is missing.';

      notifyListeners();
      return false;
    }

    if (_chatRepository.isConnected) {
      await _sendProfilePacket();
      return true;
    }

    if (_isConnectingSocket) {
      return false;
    }

    _isConnectingSocket = true;
    _errorMessage = null;

    notifyListeners();

    final bool connected = await _chatRepository.connectToServer(groupOwnerIp);

    _isConnectingSocket = false;

    if (!connected) {
      _errorMessage =
          'Wi-Fi Direct connected, but '
          'the TCP chat connection failed.';

      notifyListeners();
      return false;
    }

    await _sendProfilePacket();

    notifyListeners();
    return true;
  }

  Future<UserModel?> completeWifiDirectConnection({
    required Map<String, dynamic> connectionInfo,
    required String fallbackDeviceName,
    String? deviceAddress,
  }) async {
    await initialize();

    _pendingDeviceName = fallbackDeviceName;

    _pendingDeviceAddress = deviceAddress;

    _errorMessage = null;

    _profileCompleter = Completer<UserModel>();

    final bool activated = await activateWifiDirectConnection(
      connectionInfo,
      fallbackDeviceName: fallbackDeviceName,
      deviceAddress: deviceAddress,
    );

    if (!activated) {
      return null;
    }

    if (_currentPeer != null && _isSocketConnected) {
      return _currentPeer;
    }

    try {
      return await _profileCompleter!.future.timeout(
        const Duration(seconds: 40),
      );
    } on TimeoutException {
      _errorMessage =
          'The Wi-Fi connection was formed, '
          'but the other app did not complete '
          'the TCP profile exchange.';

      notifyListeners();
      return null;
    }
  }

  void _handleConnectionChanged(bool connected) {
    _isSocketConnected = connected;

    if (connected) {
      _errorMessage = null;

      unawaited(_sendProfilePacket());
    } else {
      final UserModel? peer = _currentPeer;

      if (peer != null) {
        unawaited(
          _databaseHelper.updateUserConnectionStatus(
            userId: peer.deviceId,
            isOnline: false,
          ),
        );
      }

      _currentPeer = _currentPeer?.copyWith(isOnline: false);

      unawaited(loadConnectedUsers());
    }

    notifyListeners();
  }

  Future<void> _sendProfilePacket() async {
    if (!_chatRepository.isConnected) {
      return;
    }

    if (_localUserId.isEmpty) {
      await refreshLocalProfile();
    }

    await _chatRepository.sendPacket({
      'type': 'profile',
      'userId': _localUserId,
      'name': _localName.isEmpty ? 'Offline User' : _localName,
      'phone': _localPhone,
    });
  }

  Future<void> _handlePacket(Map<String, dynamic> packet) async {
    final String type = packet['type']?.toString() ?? '';

    switch (type) {
      case 'profile':
        await _handleProfilePacket(packet);
        break;

      case 'message':
        await _handleMessagePacket(packet);
        break;

      default:
        debugPrint(
          'Unknown TCP packet type: '
          '$type',
        );
    }
  }

  Future<void> _handleProfilePacket(Map<String, dynamic> packet) async {
    final String remoteUserId = packet['userId']?.toString().trim() ?? '';

    if (remoteUserId.isEmpty || remoteUserId == _localUserId) {
      return;
    }

    final String remoteName = packet['name']?.toString().trim() ?? '';

    final String remotePhone = packet['phone']?.toString().trim() ?? '';

    final String resolvedName =
        remoteName.isNotEmpty
            ? remoteName
            : remotePhone.isNotEmpty
            ? remotePhone
            : (_pendingDeviceName ?? 'Nearby User');

    final UserModel connectedUser = UserModel(
      deviceId: remoteUserId,
      name: resolvedName,
      phone: remotePhone,
      deviceName: _pendingDeviceName,
      deviceAddress: _pendingDeviceAddress,
      ipAddress: _chatRepository.remoteIpAddress ?? _pendingIpAddress,
      isOnline: true,
      lastConnectedAt: DateTime.now(),
    );

    _currentPeer = connectedUser;

    await _databaseHelper.saveConnectedUser(
      userId: connectedUser.deviceId,
      name: connectedUser.name,
      phone: connectedUser.phone,
      deviceName: connectedUser.deviceName,
      deviceAddress: connectedUser.deviceAddress,
      lastIpAddress: connectedUser.ipAddress,
      isOnline: true,
    );

    await loadConnectedUsers();

    if (_profileCompleter != null && !_profileCompleter!.isCompleted) {
      _profileCompleter!.complete(connectedUser);
    }

    notifyListeners();
  }

  Future<void> _handleMessagePacket(Map<String, dynamic> packet) async {
    final MessageModel message = MessageModel.fromNetworkMap(
      packet,
      localUserId: _localUserId,
    );

    if (message.messageId.isEmpty || message.senderUserId.isEmpty) {
      return;
    }

    UserModel? sender = _findConnectedUser(message.senderUserId);

    if (sender == null) {
      sender = UserModel(
        deviceId: message.senderUserId,
        name: message.senderName,
        phone: '',
        isOnline: true,
        lastConnectedAt: DateTime.now(),
      );

      await _databaseHelper.saveConnectedUser(
        userId: sender.deviceId,
        name: sender.name,
        isOnline: true,
      );
    }

    await _databaseHelper.insertMessage(
      messageId: message.messageId,
      peerUserId: message.peerUserId,
      senderUserId: message.senderUserId,
      receiverUserId: message.receiverUserId,
      senderName: message.senderName,
      content: message.text,
      isOutgoing: false,
      messageType: message.messageType,
      latitude: message.latitude,
      longitude: message.longitude,
      deliveryStatus: 'delivered',
      timestamp: message.time,
    );

    if (_currentPeer?.deviceId == message.peerUserId) {
      _messages.add(message);
    }

    await loadConnectedUsers();

    notifyListeners();
  }

  Future<void> loadConnectedUsers() async {
    final List<Map<String, Object?>> rows =
        await _databaseHelper.getConnectedUsers();

    _connectedUsers
      ..clear()
      ..addAll(
        rows.map((row) {
          final UserModel user = UserModel.fromDatabaseMap(row);

          final bool online =
              _isSocketConnected && _currentPeer?.deviceId == user.deviceId;

          return user.copyWith(isOnline: online);
        }),
      );

    notifyListeners();
  }

  Future<void> openConversation(UserModel user) async {
    _currentPeer = user.copyWith(
      isOnline: _isSocketConnected && _currentPeer?.deviceId == user.deviceId,
    );

    _isLoadingMessages = true;
    _messages.clear();

    notifyListeners();

    final List<Map<String, Object?>> rows = await _databaseHelper
        .getMessagesForUser(user.deviceId);

    _messages
      ..clear()
      ..addAll(rows.map(MessageModel.fromDatabaseMap));

    await _databaseHelper.markConversationAsRead(user.deviceId);

    _isLoadingMessages = false;

    notifyListeners();
  }

  Future<bool> sendMessage(String text) async {
    final String cleanedText = text.trim();

    if (cleanedText.isEmpty) {
      return false;
    }

    final UserModel? peer = _currentPeer;

    if (peer == null) {
      _errorMessage = 'No chat user is selected.';

      notifyListeners();
      return false;
    }

    if (!_isSocketConnected || !_chatRepository.isConnected) {
      _errorMessage =
          'This user is currently offline. '
          'Reconnect from Find Nearby Users.';

      notifyListeners();
      return false;
    }

    final String messageId = _databaseHelper.createMessageId(_localUserId);

    MessageModel message = MessageModel(
      messageId: messageId,
      peerUserId: peer.deviceId,
      senderUserId: _localUserId,
      receiverUserId: peer.deviceId,
      senderName: _localName.isEmpty ? 'Me' : _localName,
      text: cleanedText,
      messageType: 'text',
      time: DateTime.now(),
      deliveryStatus: 'sending',
      isOutgoing: true,
      isRead: true,
    );

    _messages.add(message);

    await _databaseHelper.insertMessage(
      messageId: message.messageId,
      peerUserId: message.peerUserId,
      senderUserId: message.senderUserId,
      receiverUserId: message.receiverUserId,
      senderName: message.senderName,
      content: message.text,
      isOutgoing: true,
      messageType: message.messageType,
      deliveryStatus: 'sending',
      isRead: true,
      timestamp: message.time,
    );

    notifyListeners();

    final bool sent = await _chatRepository.sendPacket(message.toNetworkMap());

    final String status = sent ? 'sent' : 'failed';

    await _databaseHelper.updateMessageStatus(
      messageId: message.messageId,
      status: status,
    );

    final int messageIndex = _messages.indexWhere(
      (item) => item.messageId == message.messageId,
    );

    if (messageIndex >= 0) {
      message = message.copyWith(deliveryStatus: status);

      _messages[messageIndex] = message;
    }

    if (!sent) {
      _errorMessage = 'Message could not be sent.';
    }

    await loadConnectedUsers();

    notifyListeners();

    return sent;
  }

  UserModel? _findConnectedUser(String userId) {
    for (final UserModel user in _connectedUsers) {
      if (user.deviceId == userId) {
        return user;
      }
    }

    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> disconnectCurrentPeer() async {
    await _chatRepository.disconnectSocket();
  }

  @override
  void dispose() {
    _wifiDirectTimer?.cancel();

    _packetSubscription?.cancel();
    _connectionSubscription?.cancel();

    unawaited(_chatRepository.dispose());

    super.dispose();
  }
}
