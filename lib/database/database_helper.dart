import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:testmessage/model/api.dart';
import 'package:testmessage/model/sms.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sms_database.db');
    return await openDatabase(
      path,
      version: 2, // Incremented the version to 2
      onCreate: (db, version) {
        db.execute(
          '''
          CREATE TABLE sms(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT,
            message TEXT
          )
          ''',
        );
        db.execute(
          '''
          CREATE TABLE api(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute(
            '''
            CREATE TABLE api(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              url TEXT
            )
            ''',
          );
        }
      },
    );
  }

  Future<void> insertSms(SMS sms) async {
    final db = await database;
    await db.insert(
      'sms',
      sms.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SMS>> getSms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sms');
    return List.generate(maps.length, (i) {
      return SMS.fromMap(maps[i]);
    });
  }

  Future<void> insertApi(API api) async {
    final db = await database;
    await db.insert(
      'api',
      api.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<API>> getApis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('api');
    return List.generate(maps.length, (i) {
      return API.fromMap(maps[i]);
    });
  }

  Future<void> clearSmsTable() async {
    final db = await database;
    await db.delete('sms');
  }

  Future<void> clearApiTable() async {
    final db = await database;
    await db.delete('api');
  }
}
