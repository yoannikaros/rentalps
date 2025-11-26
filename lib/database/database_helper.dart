import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/console.dart';
import '../models/session.dart';
import '../models/console_type.dart';
import '../models/session_extension.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rentalps.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create console_types table
    await db.execute('''
      CREATE TABLE console_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        hourly_rate REAL NOT NULL,
        color_code TEXT NOT NULL,
        created_at INTEGER
      )
    ''');

    // Create consoles table
    await db.execute('''
      CREATE TABLE consoles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        console_type_id INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER,
        FOREIGN KEY (console_type_id) REFERENCES console_types (id)
      )
    ''');

    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        console_id INTEGER NOT NULL,
        customer_name TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_minutes INTEGER NOT NULL,
        actual_duration_minutes INTEGER,
        total_cost REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER,
        original_duration_minutes INTEGER NOT NULL,
        original_cost REAL NOT NULL,
        extension_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (console_id) REFERENCES consoles (id)
      )
    ''');

    // Create session_extensions table
    await db.execute('''
      CREATE TABLE session_extensions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        extension_number INTEGER NOT NULL,
        extension_time INTEGER NOT NULL,
        additional_minutes INTEGER NOT NULL,
        additional_cost REAL NOT NULL,
        created_at INTEGER,
        FOREIGN KEY (session_id) REFERENCES sessions (id)
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'employee',
        created_at INTEGER NOT NULL,
        last_login_at INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert default console types and consoles
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Create users table for authentication
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          full_name TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'employee',
          created_at INTEGER NOT NULL,
          last_login_at INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Insert default admin user
      await _insertDefaultAdmin(db);
    }
  }

  Future<void> _insertDefaultAdmin(Database db) async {
    // Insert default admin user (password: admin123)
    final defaultAdmin = {
      'username': 'admin',
      'email': 'admin@rentalps.com',
      'password_hash': 'admin123', // Plain text password
      'full_name': 'Administrator',
      'role': 'admin',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_login_at': null,
      'is_active': 1,
    };

    try {
      await db.insert('users', defaultAdmin);
    } catch (e) {
      // Admin user might already exist, update the password to plain text
      try {
        await db.update(
          'users',
          {'password_hash': 'admin123'}, // Update to plain text password
          where: 'username = ?',
          whereArgs: ['admin'],
        );
        print('Updated admin password to plain text');
      } catch (updateError) {
        print('Failed to update admin password: $updateError');
      }
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default console types
    final defaultConsoleTypes = [
      {'name': 'PS2', 'hourly_rate': 2000.0, 'color_code': '#4CAF50', 'created_at': DateTime.now().millisecondsSinceEpoch},
      {'name': 'PS3', 'hourly_rate': 3000.0, 'color_code': '#2196F3', 'created_at': DateTime.now().millisecondsSinceEpoch},
      {'name': 'PS4', 'hourly_rate': 4000.0, 'color_code': '#FF9800', 'created_at': DateTime.now().millisecondsSinceEpoch},
      {'name': 'PS5', 'hourly_rate': 5000.0, 'color_code': '#9C27B0', 'created_at': DateTime.now().millisecondsSinceEpoch},
    ];

    for (var consoleType in defaultConsoleTypes) {
      await db.insert('console_types', consoleType);
    }

    // Insert default consoles
    final defaultConsoles = [
      {'name': 'PS2 - Console 1', 'console_type_id': 1, 'is_active': 0, 'created_at': DateTime.now().millisecondsSinceEpoch},
      {'name': 'PS2 - Console 2', 'console_type_id': 1, 'is_active': 0, 'created_at': DateTime.now().millisecondsSinceEpoch},
    ];

    for (var console in defaultConsoles) {
      await db.insert('consoles', console);
    }
  }

  // Console Type operations
  Future<int> insertConsoleType(ConsoleType consoleType) async {
    final db = await database;
    return await db.insert('console_types', consoleType.toMap());
  }

  Future<List<ConsoleType>> getAllConsoleTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('console_types');
    return List.generate(maps.length, (i) => ConsoleType.fromMap(maps[i]));
  }

  Future<ConsoleType?> getConsoleType(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'console_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ConsoleType.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateConsoleType(ConsoleType consoleType) async {
    final db = await database;
    return await db.update(
      'console_types',
      consoleType.toMap(),
      where: 'id = ?',
      whereArgs: [consoleType.id],
    );
  }

  Future<int> deleteConsoleType(int id) async {
    final db = await database;
    // First check if any consoles are using this type
    final consoles = await db.query(
      'consoles',
      where: 'console_type_id = ?',
      whereArgs: [id],
    );
    
    if (consoles.isNotEmpty) {
      throw Exception('Cannot delete console type: ${consoles.length} consoles are using this type');
    }
    
    return await db.delete(
      'console_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Console operations
  Future<int> insertConsole(Console console) async {
    final db = await database;
    return await db.insert('consoles', console.toMap());
  }

  Future<List<Console>> getAllConsoles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('consoles');
    return List.generate(maps.length, (i) => Console.fromMap(maps[i]));
  }

  // Get consoles with their type information
  Future<List<Map<String, dynamic>>> getConsolesWithTypes() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.console_type_id,
        c.is_active,
        c.created_at,
        ct.name as type_name,
        ct.hourly_rate,
        ct.color_code
      FROM consoles c
      JOIN console_types ct ON c.console_type_id = ct.id
      ORDER BY c.name
    ''');
  }

  Future<Console?> getConsole(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consoles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Console.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateConsole(Console console) async {
    final db = await database;
    return await db.update(
      'consoles',
      console.toMap(),
      where: 'id = ?',
      whereArgs: [console.id],
    );
  }

  Future<int> deleteConsole(int id) async {
    final db = await database;
    return await db.delete(
      'consoles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Session operations
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sessions');
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<Session?> getActiveSessionByConsoleId(int consoleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'console_id = ? AND is_active = 1',
      whereArgs: [consoleId],
    );
    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Session>> getActiveSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'is_active = 1',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getRecentCompletedSessions({int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        s.*,
        c.name as console_name,
        ct.name as console_type_name,
        ct.color_code
      FROM sessions s
      JOIN consoles c ON s.console_id = c.id
      JOIN console_types ct ON c.console_type_id = ct.id
      WHERE s.is_active = 0
        AND s.end_time IS NOT NULL
      ORDER BY s.end_time DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> endSession(int sessionId) async {
    final db = await database;
    return await db.update(
      'sessions',
      {
        'end_time': DateTime.now().millisecondsSinceEpoch,
        'is_active': 0,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Monthly report operations
  Future<List<Map<String, dynamic>>> getMonthlySessionData(int year, int month) async {
    final db = await database;
    
    // Calculate start and end timestamps for the month
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    
    return await db.rawQuery('''
      SELECT 
        s.*,
        c.name as console_name,
        ct.name as console_type_name,
        ct.hourly_rate,
        ct.color_code
      FROM sessions s
      JOIN consoles c ON s.console_id = c.id
      JOIN console_types ct ON c.console_type_id = ct.id
      WHERE s.is_active = 0 
        AND s.end_time IS NOT NULL
        AND s.start_time >= ? 
        AND s.start_time <= ?
      ORDER BY s.start_time DESC
    ''', [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch]);
  }

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await database;
    
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as session_count,
        SUM(COALESCE(actual_duration_minutes, duration_minutes)) as total_minutes,
        SUM(total_cost) as total_revenue
      FROM sessions s
      WHERE s.is_active = 0 
        AND s.end_time IS NOT NULL
        AND s.start_time >= ? 
        AND s.start_time <= ?
    ''', [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch]);

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'session_count': row['session_count'] ?? 0,
        'total_hours': ((row['total_minutes'] as int?) ?? 0) / 60.0,
        'total_revenue': (row['total_revenue'] as double?) ?? 0.0,
      };
    }
    
    return {
      'session_count': 0,
      'total_hours': 0.0,
      'total_revenue': 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getConsoleTypeStatsForMonth(int year, int month) async {
    final db = await database;
    
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    
    return await db.rawQuery('''
      SELECT 
        ct.name as console_type_name,
        ct.color_code,
        COUNT(*) as session_count,
        SUM(COALESCE(s.actual_duration_minutes, s.duration_minutes)) as total_minutes,
        SUM(s.total_cost) as total_revenue
      FROM sessions s
      JOIN consoles c ON s.console_id = c.id
      JOIN console_types ct ON c.console_type_id = ct.id
      WHERE s.is_active = 0 
        AND s.end_time IS NOT NULL
        AND s.start_time >= ? 
        AND s.start_time <= ?
      GROUP BY ct.id, ct.name, ct.color_code
      ORDER BY total_revenue DESC
    ''', [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch]);
  }

  Future<List<Map<String, dynamic>>> getAllMonthsWithData() async {
    final db = await database;
    
    return await db.rawQuery('''
      SELECT DISTINCT
        strftime('%Y', datetime(start_time/1000, 'unixepoch')) as year,
        strftime('%m', datetime(start_time/1000, 'unixepoch')) as month
      FROM sessions
      WHERE is_active = 0 AND end_time IS NOT NULL
      ORDER BY year DESC, month DESC
    ''');
  }

  // Session Extension operations
  Future<int> insertSessionExtension(SessionExtension extension) async {
    final db = await database;
    return await db.insert('session_extensions', extension.toMap());
  }

  Future<List<SessionExtension>> getSessionExtensions(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session_extensions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'extension_number',
    );
    return List.generate(maps.length, (i) => SessionExtension.fromMap(maps[i]));
  }

  Future<int> getNextExtensionNumber(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session_extensions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'extension_number DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return 1;
    }

    final lastExtension = SessionExtension.fromMap(maps.first);
    return lastExtension.extensionNumber + 1;
  }

  // Advanced session operations for reporting
  Future<List<Map<String, dynamic>>> getMonthlyReportData() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        s.*,
        c.name as console_name,
        ct.name as console_type_name,
        ct.hourly_rate,
        ct.color_code
      FROM sessions s
      JOIN consoles c ON s.console_id = c.id
      JOIN console_types ct ON c.console_type_id = ct.id
      WHERE s.is_active = 0
        AND s.end_time IS NOT NULL
      ORDER BY s.end_time DESC
    ''');
  }

  Future<Map<String, dynamic>> getSessionReportData(int sessionId) async {
    final db = await database;

    // Get session data
    final sessionMaps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (sessionMaps.isEmpty) {
      return {};
    }

    final sessionData = sessionMaps.first;

    // Get console and console type data
    final consoleMaps = await db.query(
      'consoles',
      where: 'id = ?',
      whereArgs: [sessionData['console_id']],
    );

    if (consoleMaps.isEmpty) {
      return sessionData;
    }

    final consoleData = consoleMaps.first;
    final consoleTypeMaps = await db.query(
      'console_types',
      where: 'id = ?',
      whereArgs: [consoleData['console_type_id']],
    );

    final result = {
      ...sessionData,
      'console_name': consoleData['name'],
    };

    if (consoleTypeMaps.isNotEmpty) {
      final consoleTypeData = consoleTypeMaps.first;
      result['console_type_name'] = consoleTypeData['name'];
      result['hourly_rate'] = consoleTypeData['hourly_rate'];
      result['color_code'] = consoleTypeData['color_code'];
    }

    return result;
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND is_active = 1',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateUserLastLogin(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'last_login_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deactivateUser(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> authenticateUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND is_active = 1',
      whereArgs: [username, username],
    );

    if (maps.isEmpty) {
      return false;
    }

    final user = User.fromMap(maps.first);
    return AuthService.verifyPassword(password, user.passwordHash);
  }

  Future<User?> authenticateAndGetUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND is_active = 1',
      whereArgs: [username, username],
    );

    if (maps.isEmpty) {
      return null;
    }

    final user = User.fromMap(maps.first);

    if (AuthService.verifyPassword(password, user.passwordHash)) {
      // Update last login time
      await updateUserLastLogin(user.id!);
      return user;
    }

    return null;
  }

  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  Future<bool> isEmailExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}