import 'package:sqflite/sqflite.dart';

class MessageTable {
  MessageTable._();

  static const String tableName = 'messages';

  static const String columnId = 'id';
  static const String columnMessageId = 'message_id';
  static const String columnPeerUserId = 'peer_user_id';
  static const String columnSenderUserId = 'sender_user_id';
  static const String columnReceiverUserId = 'receiver_user_id';
  static const String columnSenderName = 'sender_name';
  static const String columnContent = 'content';
  static const String columnMessageType = 'message_type';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnTimestamp = 'timestamp';
  static const String columnDeliveryStatus = 'delivery_status';
  static const String columnIsOutgoing = 'is_outgoing';
  static const String columnIsRead = 'is_read';

  static Future<void> createTable(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnMessageId TEXT NOT NULL UNIQUE,
        $columnPeerUserId TEXT NOT NULL,
        $columnSenderUserId TEXT NOT NULL,
        $columnReceiverUserId TEXT NOT NULL,
        $columnSenderName TEXT,
        $columnContent TEXT NOT NULL,
        $columnMessageType TEXT NOT NULL DEFAULT 'text',
        $columnLatitude REAL,
        $columnLongitude REAL,
        $columnTimestamp TEXT NOT NULL,
        $columnDeliveryStatus TEXT NOT NULL DEFAULT 'sent',
        $columnIsOutgoing INTEGER NOT NULL DEFAULT 0,
        $columnIsRead INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE INDEX index_messages_peer_timestamp
      ON $tableName ($columnPeerUserId, $columnTimestamp)
    ''');

    await database.execute('''
      CREATE INDEX index_messages_receiver
      ON $tableName ($columnReceiverUserId)
    ''');
  }
}
