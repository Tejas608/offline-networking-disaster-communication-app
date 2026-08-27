import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'message_table.dart';
import 'user_table.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'offline_disaster_connect.db';

  static const int _databaseVersion = 1;

  Database? _database;

  // ============================================================
  // OPEN DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final String databaseDirectory = await getDatabasesPath();

    final String databasePath = path.join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    await UserTable.createTable(database);
    await MessageTable.createTable(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // Future database changes can be added here.
  }

  // ============================================================
  // CONNECTED USER OPERATIONS
  // ============================================================

  Future<int> saveConnectedUser({
    required String userId,
    required String name,
    String? phone,
    String? deviceName,
    String? deviceAddress,
    String? lastIpAddress,
    bool isOnline = true,
    DateTime? connectedAt,
  }) async {
    final Database db = await database;

    final DateTime currentDate = connectedAt ?? DateTime.now();

    final String currentTime = currentDate.toUtc().toIso8601String();

    final List<Map<String, Object?>> existingUsers = await db.query(
      UserTable.tableName,
      columns: [UserTable.columnId],
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (existingUsers.isEmpty) {
      return db.insert(UserTable.tableName, {
        UserTable.columnUserId: userId,
        UserTable.columnName: name,
        UserTable.columnPhone: phone,
        UserTable.columnDeviceName: deviceName,
        UserTable.columnDeviceAddress: deviceAddress,
        UserTable.columnLastIpAddress: lastIpAddress,
        UserTable.columnConnectionStatus: isOnline ? 1 : 0,
        UserTable.columnLastConnectedAt: currentTime,
        UserTable.columnCreatedAt: currentTime,
        UserTable.columnUpdatedAt: currentTime,
      });
    }

    final Map<String, Object?> updateData = {
      UserTable.columnName: name,
      UserTable.columnConnectionStatus: isOnline ? 1 : 0,
      UserTable.columnLastConnectedAt: currentTime,
      UserTable.columnUpdatedAt: currentTime,
    };

    if (phone != null && phone.isNotEmpty) {
      updateData[UserTable.columnPhone] = phone;
    }

    if (deviceName != null && deviceName.isNotEmpty) {
      updateData[UserTable.columnDeviceName] = deviceName;
    }

    if (deviceAddress != null && deviceAddress.isNotEmpty) {
      updateData[UserTable.columnDeviceAddress] = deviceAddress;
    }

    if (lastIpAddress != null && lastIpAddress.isNotEmpty) {
      updateData[UserTable.columnLastIpAddress] = lastIpAddress;
    }

    return db.update(
      UserTable.tableName,
      updateData,
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, Object?>>> getConnectedUsers() async {
    final Database db = await database;

    return db.query(
      UserTable.tableName,
      orderBy: '''
        ${UserTable.columnLastMessageAt} DESC,
        ${UserTable.columnLastConnectedAt} DESC
      ''',
    );
  }

  Future<Map<String, Object?>?> getConnectedUserById(String userId) async {
    final Database db = await database;

    final List<Map<String, Object?>> result = await db.query(
      UserTable.tableName,
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateUserConnectionStatus({
    required String userId,
    required bool isOnline,
    String? ipAddress,
  }) async {
    final Database db = await database;

    final Map<String, Object?> values = {
      UserTable.columnConnectionStatus: isOnline ? 1 : 0,
      UserTable.columnUpdatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    if (isOnline) {
      values[UserTable.columnLastConnectedAt] =
          DateTime.now().toUtc().toIso8601String();
    }

    if (ipAddress != null && ipAddress.isNotEmpty) {
      values[UserTable.columnLastIpAddress] = ipAddress;
    }

    return db.update(
      UserTable.tableName,
      values,
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserLastMessage({
    required String userId,
    required String message,
    required DateTime timestamp,
  }) async {
    final Database db = await database;

    return db.update(
      UserTable.tableName,
      {
        UserTable.columnLastMessage: message,
        UserTable.columnLastMessageAt: timestamp.toUtc().toIso8601String(),
        UserTable.columnUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteConnectedUser(String userId) async {
    final Database db = await database;

    return db.delete(
      UserTable.tableName,
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // MESSAGE OPERATIONS
  // ============================================================

  String createMessageId(String senderUserId) {
    final int time = DateTime.now().microsecondsSinceEpoch;

    return '${senderUserId}_$time';
  }

  Future<int> insertMessage({
    required String messageId,
    required String peerUserId,
    required String senderUserId,
    required String receiverUserId,
    required String content,
    required bool isOutgoing,
    String? senderName,
    String messageType = 'text',
    double? latitude,
    double? longitude,
    String deliveryStatus = 'sent',
    bool isRead = false,
    DateTime? timestamp,
  }) async {
    final Database db = await database;

    final DateTime messageTime = timestamp ?? DateTime.now();

    final int insertedId = await db.insert(MessageTable.tableName, {
      MessageTable.columnMessageId: messageId,
      MessageTable.columnPeerUserId: peerUserId,
      MessageTable.columnSenderUserId: senderUserId,
      MessageTable.columnReceiverUserId: receiverUserId,
      MessageTable.columnSenderName: senderName,
      MessageTable.columnContent: content,
      MessageTable.columnMessageType: messageType,
      MessageTable.columnLatitude: latitude,
      MessageTable.columnLongitude: longitude,
      MessageTable.columnTimestamp: messageTime.toUtc().toIso8601String(),
      MessageTable.columnDeliveryStatus: deliveryStatus,
      MessageTable.columnIsOutgoing: isOutgoing ? 1 : 0,
      MessageTable.columnIsRead: isRead ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (insertedId > 0) {
      await updateUserLastMessage(
        userId: peerUserId,
        message: _createMessagePreview(
          messageType: messageType,
          content: content,
        ),
        timestamp: messageTime,
      );
    }

    return insertedId;
  }

  String _createMessagePreview({
    required String messageType,
    required String content,
  }) {
    switch (messageType) {
      case 'location':
        return 'Location shared';

      case 'sos':
        return 'SOS alert';

      case 'image':
        return 'Image';

      case 'voice':
        return 'Voice message';

      default:
        return content;
    }
  }

  Future<List<Map<String, Object?>>> getMessagesForUser(
    String peerUserId,
  ) async {
    final Database db = await database;

    return db.query(
      MessageTable.tableName,
      where: '${MessageTable.columnPeerUserId} = ?',
      whereArgs: [peerUserId],
      orderBy: '${MessageTable.columnTimestamp} ASC',
    );
  }

  Future<Map<String, Object?>?> getLastMessageForUser(String peerUserId) async {
    final Database db = await database;

    final List<Map<String, Object?>> result = await db.query(
      MessageTable.tableName,
      where: '${MessageTable.columnPeerUserId} = ?',
      whereArgs: [peerUserId],
      orderBy: '${MessageTable.columnTimestamp} DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    final Database db = await database;

    return db.update(
      MessageTable.tableName,
      {MessageTable.columnDeliveryStatus: status},
      where: '${MessageTable.columnMessageId} = ?',
      whereArgs: [messageId],
    );
  }

  Future<int> markConversationAsRead(String peerUserId) async {
    final Database db = await database;

    return db.update(
      MessageTable.tableName,
      {MessageTable.columnIsRead: 1},
      where: '''
        ${MessageTable.columnPeerUserId} = ?
        AND ${MessageTable.columnIsOutgoing} = ?
      ''',
      whereArgs: [peerUserId, 0],
    );
  }

  Future<int> getUnreadMessageCount(String peerUserId) async {
    final Database db = await database;

    final List<Map<String, Object?>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS unread_count
      FROM ${MessageTable.tableName}
      WHERE ${MessageTable.columnPeerUserId} = ?
      AND ${MessageTable.columnIsOutgoing} = 0
      AND ${MessageTable.columnIsRead} = 0
      ''',
      [peerUserId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteConversation(String peerUserId) async {
    final Database db = await database;

    final int deletedMessages = await db.delete(
      MessageTable.tableName,
      where: '${MessageTable.columnPeerUserId} = ?',
      whereArgs: [peerUserId],
    );

    await db.update(
      UserTable.tableName,
      {
        UserTable.columnLastMessage: null,
        UserTable.columnLastMessageAt: null,
        UserTable.columnUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${UserTable.columnUserId} = ?',
      whereArgs: [peerUserId],
    );

    return deletedMessages;
  }

  // ============================================================
  // CLEAR DATABASE DATA
  // ============================================================

  Future<void> clearAllMessages() async {
    final Database db = await database;

    await db.delete(MessageTable.tableName);

    await db.update(UserTable.tableName, {
      UserTable.columnLastMessage: null,
      UserTable.columnLastMessageAt: null,
      UserTable.columnUpdatedAt: DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> clearAllLocalData() async {
    final Database db = await database;

    await db.transaction((Transaction transaction) async {
      await transaction.delete(MessageTable.tableName);

      await transaction.delete(UserTable.tableName);
    });
  }

  // ============================================================
  // DATABASE INFORMATION
  // ============================================================

  Future<String> getDatabaseFilePath() async {
    final String databaseDirectory = await getDatabasesPath();

    return path.join(databaseDirectory, _databaseName);
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }

    _database = null;
  }
}
