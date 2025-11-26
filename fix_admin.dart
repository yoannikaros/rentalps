import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  print('🔧 Fixing default admin account...');

  try {
    // Get database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'rentalps.db');

    print('📍 Database path: $path');

    // Open database
    final db = await openDatabase(path);

    // Check if admin user exists
    final List<Map> users = await db.query('users');
    print('📋 Found ${users.length} users in database');

    for (var user in users) {
      print('  - ${user['username']} (${user['email']}) - Password: "${user['password_hash']}"');
    }

    // Check for admin user
    final adminUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );

    if (adminUsers.isNotEmpty) {
      final adminUser = adminUsers.first;
      print('👤 Found admin user: ${adminUser['username']}');
      print('🔑 Current password: "${adminUser['password_hash']}"');

      // Update admin password to plain text
      await db.update(
        'users',
        {'password_hash': 'admin123'}, // Plain text password
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      print('✅ Updated admin password to: "admin123" (plain text)');

      // Verify the update
      final updatedAdmin = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (updatedAdmin.isNotEmpty) {
        print('✅ Verification successful - new password: "${updatedAdmin.first['password_hash']}"');
      } else {
        print('❌ Verification failed');
      }
    } else {
      print('❌ No admin user found');

      // Create admin user
      final newAdmin = {
        'username': 'admin',
        'email': 'admin@rentalps.com',
        'password_hash': 'admin123', // Plain text
        'full_name': 'Administrator',
        'role': 'admin',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'last_login_at': null,
        'is_active': 1,
      };

      await db.insert('users', newAdmin);
      print('✅ Created new admin user with password: "admin123"');
    }

    // Test authentication
    print('\n🧪 Testing authentication...');
    final testUsers = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND is_active = 1',
      whereArgs: ['admin', 'admin'],
    );

    if (testUsers.isNotEmpty) {
      final testUser = testUsers.first;
      final storedPassword = testUser['password_hash'];
      final testPassword = 'admin123';

      print('🔑 Stored password: "$storedPassword"');
      print('🔑 Test password: "$testPassword"');
      print('✅ Password match: ${storedPassword == testPassword}');

      if (storedPassword == testPassword) {
        print('🎉 Admin account is ready!');
        print('📝 Login credentials:');
        print('   Username: admin');
        print('   Password: admin123');
      } else {
        print('❌ Password mismatch!');
      }
    } else {
      print('❌ Admin user not found for testing');
    }

    await db.close();
    print('✅ Database updated successfully');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }

  exit(0);
}