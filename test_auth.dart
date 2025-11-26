import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/database/database_helper.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/user.dart';

void main() async {
  // Initialize Flutter binding for database access
  WidgetsFlutterBinding.ensureInitialized();
  print('Testing Authentication System...');

  try {
    // Initialize database
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Test 1: Check if admin user exists
    print('\n1. Checking admin user...');
    final adminUser = await dbHelper.getUserByUsername('admin');
    if (adminUser != null) {
      print('Admin user found: ${adminUser.username}');
      print('Admin password hash: "${adminUser.passwordHash}"');
      print('Admin role: ${adminUser.role}');

      // Test 2: Verify password
      print('\n2. Testing password verification...');
      bool isValid = AuthService.verifyPassword('admin123', adminUser.passwordHash);
      print('Password "admin123" verification: $isValid');

      bool isInvalid = AuthService.verifyPassword('wrongpassword', adminUser.passwordHash);
      print('Password "wrongpassword" verification: $isInvalid');

      // Test 3: Test authenticateAndGetUser
      print('\n3. Testing authenticateAndGetUser...');
      final authenticatedUser = await dbHelper.authenticateAndGetUser('admin', 'admin123');
      if (authenticatedUser != null) {
        print('✅ Authentication successful!');
        print('User: ${authenticatedUser.fullName} (${authenticatedUser.role})');
      } else {
        print('❌ Authentication failed!');
      }

      // Test 4: Test wrong password
      print('\n4. Testing wrong password...');
      final failedAuth = await dbHelper.authenticateAndGetUser('admin', 'wrongpassword');
      if (failedAuth == null) {
        print('✅ Wrong password correctly rejected!');
      } else {
        print('❌ Wrong password was accepted (BUG!)');
      }

    } else {
      print('❌ Admin user not found!');
    }

    // Check if admin user exists, if not create one
    if (adminUser == null) {
      print('\n5. Admin user not found, creating one...');
      final newAdmin = User(
        username: 'admin',
        email: 'admin@rentalps.com',
        passwordHash: 'admin123', // Plain text password
        fullName: 'Administrator',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      try {
        await dbHelper.insertUser(newAdmin);
        print('✅ Admin user created successfully!');
      } catch (e) {
        print('❌ Error creating admin user: $e');
      }
    }

    // Show all users
    print('\n6. All users in database:');
    final allUsers = await dbHelper.getAllUsers();
    for (final user in allUsers) {
      print('- ${user.username} (${user.email}) - Role: ${user.role.name} - Password: "${user.passwordHash}"');
    }

    // Test admin login after creating
    if (adminUser == null) {
      print('\n7. Testing admin login after creation...');
      final createdAdmin = await dbHelper.getUserByUsername('admin');
      if (createdAdmin != null) {
        final authenticatedAdmin = await dbHelper.authenticateAndGetUser('admin', 'admin123');
        if (authenticatedAdmin != null) {
          print('✅ Admin authentication successful!');
          print('Login credentials:');
          print('  Username: admin');
          print('  Password: admin123');
          print('  Role: ${authenticatedAdmin.role.displayName}');
        } else {
          print('❌ Admin authentication failed after creation!');
        }
      }
    }

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Close database
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.close();
    } catch (e) {
      print('Error closing database: $e');
    }
    exit(0);
  }
}