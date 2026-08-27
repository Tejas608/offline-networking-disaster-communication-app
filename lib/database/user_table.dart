import 'package:sqflite/sqflite.dart';

class UserTable {
  UserTable._();

  static const String tableName = 'connected_users';

  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnName = 'name';
  static const String columnPhone = 'phone';
  static const String columnDeviceName = 'device_name';
  static const String columnDeviceAddress = 'device_address';
  static const String columnLastIpAddress = 'last_ip_address';
  static const String columnConnectionStatus = 'connection_status';
  static const String columnLastConnectedAt = 'last_connected_at';
  static const String columnLastMessage = 'last_message';
  static const String columnLastMessageAt = 'last_message_at';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static Future<void> createTable(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId TEXT NOT NULL UNIQUE,
        $columnName TEXT NOT NULL,
        $columnPhone TEXT,
        $columnDeviceName TEXT,
        $columnDeviceAddress TEXT,
        $columnLastIpAddress TEXT,
        $columnConnectionStatus INTEGER NOT NULL DEFAULT 0,
        $columnLastConnectedAt TEXT NOT NULL,
        $columnLastMessage TEXT,
        $columnLastMessageAt TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE INDEX index_connected_users_last_connected
      ON $tableName ($columnLastConnectedAt)
    ''');
  }
}
