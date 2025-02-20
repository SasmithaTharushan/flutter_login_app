import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'user_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_code TEXT,
            display_name TEXT,
            email TEXT,
            employee_code TEXT,
            company_code TEXT
          )
        ''');
      },
    );
  }

  /// Inserts or updates user data
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches the stored user from the database
  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query('users');

    if (users.isNotEmpty) {
      return users.first; // Return the first stored user
    }
    return null; // No user found
  }

  /// Prints all users in the database (For Debugging)
  Future<void> printUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query('users');
    print("Stored Users in SQLite: $users");
  }

  /// Deletes all user data (Useful for logout)
  Future<void> deleteUserData() async {
    final db = await database;
    await db.delete('users');
    print("User data deleted from SQLite.");
  }

  /// Checks if a user exists by username or email
  Future<Map<String, dynamic>?> getUserByEmailOrUsername(
      String username, String email) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'user_code = ? OR email = ?',
      whereArgs: [username, email],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
