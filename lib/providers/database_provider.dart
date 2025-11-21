import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_data.dart';
import '../models/command.dart';

class DatabaseProvider with ChangeNotifier {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'mqtt_iot.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create sensor_data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sensor_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        sensor_type TEXT NOT NULL,
        value REAL NOT NULL,
        raw_payload TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create index on sensor_data
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sensor_time ON sensor_data(timestamp DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sensor_type ON sensor_data(sensor_type)
    ''');

    // Create commands table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sent_at INTEGER
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // Insert sensor data
  Future<void> insertSensorData(SensorData sensorData) async {
    final db = await database;
    await db.insert(
      'sensor_data',
      sensorData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  // Get all sensor data
  Future<List<SensorData>> getAllSensorData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sensor_data', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return SensorData(
        id: maps[i]['id'],
        topic: maps[i]['topic'],
        sensorType: maps[i]['sensor_type'],
        value: maps[i]['value'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }

  // Get sensor data by type (suhu or humidity)
  Future<List<SensorData>> getSensorDataByType(String sensorType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sensor_data',
      where: 'sensor_type = ?',
      whereArgs: [sensorType],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return SensorData(
        id: maps[i]['id'],
        topic: maps[i]['topic'],
        sensorType: maps[i]['sensor_type'],
        value: maps[i]['value'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }

  // Insert command
  Future<void> insertCommand(Command command) async {
    final db = await database;
    await db.insert(
      'commands',
      command.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  // Get all commands
  Future<List<Command>> getAllCommands() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('commands', orderBy: 'created_at DESC');

    return List.generate(maps.length, (i) {
      return Command(
        id: maps[i]['id'],
        topic: maps[i]['topic'],
        payload: maps[i]['payload'],
        status: maps[i]['status'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
      );
    });
  }

  // Save setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  // Get setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}