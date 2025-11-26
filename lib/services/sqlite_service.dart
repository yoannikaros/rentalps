import 'dart:async';
import 'package:flutter/material.dart';
import '../models/console.dart';
import '../models/session.dart';
import '../models/session_extension.dart';
import '../models/console_type.dart';
import '../database/database_helper.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  SQLiteService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Initialize default data if needed
  Future<void> initializeDefaultData() async {
    try {
      // The DatabaseHelper already handles default data insertion in _onCreate
      // We can optionally check if data exists and add more if needed
      final consoleTypes = await getAllConsoleTypes();
      if (consoleTypes.isEmpty) {
        // This should not happen as DatabaseHelper handles this, but just in case
        debugPrint('Warning: No console types found, but DatabaseHelper should have created them');
      }
    } catch (e) {
      debugPrint('Error initializing default data: $e');
    }
  }

  // Console Type operations
  Future<int> insertConsoleType(ConsoleType consoleType) async {
    try {
      return await _databaseHelper.insertConsoleType(consoleType);
    } catch (e) {
      throw Exception('Error inserting console type: $e');
    }
  }

  Future<List<ConsoleType>> getAllConsoleTypes() async {
    try {
      return await _databaseHelper.getAllConsoleTypes();
    } catch (e) {
      throw Exception('Error getting console types: $e');
    }
  }

  Future<ConsoleType?> getConsoleType(int id) async {
    try {
      return await _databaseHelper.getConsoleType(id);
    } catch (e) {
      throw Exception('Error getting console type: $e');
    }
  }

  Future<void> updateConsoleType(ConsoleType consoleType) async {
    try {
      await _databaseHelper.updateConsoleType(consoleType);
    } catch (e) {
      throw Exception('Error updating console type: $e');
    }
  }

  Future<void> deleteConsoleType(int id) async {
    try {
      await _databaseHelper.deleteConsoleType(id);
    } catch (e) {
      throw Exception('Error deleting console type: $e');
    }
  }

  // Console operations
  Future<int> insertConsole(Console console) async {
    try {
      return await _databaseHelper.insertConsole(console);
    } catch (e) {
      throw Exception('Error inserting console: $e');
    }
  }

  Future<List<Console>> getAllConsoles() async {
    try {
      return await _databaseHelper.getAllConsoles();
    } catch (e) {
      throw Exception('Error getting consoles: $e');
    }
  }

  // Get consoles with their type information
  Future<List<Map<String, dynamic>>> getConsolesWithTypes() async {
    try {
      return await _databaseHelper.getConsolesWithTypes();
    } catch (e) {
      throw Exception('Error getting consoles with types: $e');
    }
  }

  Future<Console?> getConsole(int id) async {
    try {
      return await _databaseHelper.getConsole(id);
    } catch (e) {
      throw Exception('Error getting console: $e');
    }
  }

  Future<void> updateConsole(Console console) async {
    try {
      await _databaseHelper.updateConsole(console);
    } catch (e) {
      throw Exception('Error updating console: $e');
    }
  }

  Future<void> deleteConsole(int id) async {
    try {
      await _databaseHelper.deleteConsole(id);
    } catch (e) {
      throw Exception('Error deleting console: $e');
    }
  }

  // Session operations
  Future<int> insertSession(Session session) async {
    try {
      return await _databaseHelper.insertSession(session);
    } catch (e) {
      throw Exception('Error inserting session: $e');
    }
  }

  Future<List<Session>> getAllSessions() async {
    try {
      return await _databaseHelper.getAllSessions();
    } catch (e) {
      throw Exception('Error getting sessions: $e');
    }
  }

  Future<Session?> getActiveSessionByConsoleId(int consoleId) async {
    try {
      return await _databaseHelper.getActiveSessionByConsoleId(consoleId);
    } catch (e) {
      throw Exception('Error getting active session: $e');
    }
  }

  Future<List<Session>> getActiveSessions() async {
    try {
      return await _databaseHelper.getActiveSessions();
    } catch (e) {
      throw Exception('Error getting active sessions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentCompletedSessions({int limit = 5}) async {
    try {
      return await _databaseHelper.getRecentCompletedSessions(limit: limit);
    } catch (e) {
      throw Exception('Error getting recent completed sessions: $e');
    }
  }

  Future<void> updateSession(Session session) async {
    try {
      await _databaseHelper.updateSession(session);
    } catch (e) {
      throw Exception('Error updating session: $e');
    }
  }

  Future<void> endSession(int sessionId) async {
    try {
      await _databaseHelper.endSession(sessionId);
    } catch (e) {
      throw Exception('Error ending session: $e');
    }
  }

  // Session Extension operations
  Future<int> insertSessionExtension(SessionExtension extension) async {
    try {
      return await _databaseHelper.insertSessionExtension(extension);
    } catch (e) {
      throw Exception('Error inserting session extension: $e');
    }
  }

  Future<List<SessionExtension>> getSessionExtensions(int sessionId) async {
    try {
      return await _databaseHelper.getSessionExtensions(sessionId);
    } catch (e) {
      throw Exception('Error getting session extensions: $e');
    }
  }

  Future<int> getNextExtensionNumber(int sessionId) async {
    try {
      return await _databaseHelper.getNextExtensionNumber(sessionId);
    } catch (e) {
      throw Exception('Error getting next extension number: $e');
    }
  }

  // Monthly report operations
  Future<List<Map<String, dynamic>>> getMonthlySessionData(int year, int month) async {
    try {
      return await _databaseHelper.getMonthlySessionData(year, month);
    } catch (e) {
      throw Exception('Error getting monthly session data: $e');
    }
  }

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    try {
      return await _databaseHelper.getMonthlyStats(year, month);
    } catch (e) {
      throw Exception('Error getting monthly stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConsoleTypeStatsForMonth(int year, int month) async {
    try {
      return await _databaseHelper.getConsoleTypeStatsForMonth(year, month);
    } catch (e) {
      throw Exception('Error getting console type stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllMonthsWithData() async {
    try {
      return await _databaseHelper.getAllMonthsWithData();
    } catch (e) {
      throw Exception('Error getting months with data: $e');
    }
  }

  // Get monthly report data with console and console type information (OPTIMIZED)
  Future<List<Map<String, dynamic>>> getMonthlyReportData() async {
    try {
      // Get all session data with joins
      final sessionDataList = await _databaseHelper.getMonthlyReportData();

      if (sessionDataList.isEmpty) {
        return [];
      }

      // Get all session extensions for all sessions at once
      final List<SessionExtension> allExtensions = [];
      for (var sessionData in sessionDataList) {
        final sessionId = sessionData['id'] as int;
        final extensions = await _databaseHelper.getSessionExtensions(sessionId);
        allExtensions.addAll(extensions);
      }

      // Group extensions by session_id for easier lookup
      final Map<int, List<SessionExtension>> extensionsMap = {};
      for (var extension in allExtensions) {
        if (!extensionsMap.containsKey(extension.sessionId)) {
          extensionsMap[extension.sessionId] = [];
        }
        extensionsMap[extension.sessionId]!.add(extension);
      }

      // Build result with session data and extensions
      final List<Map<String, dynamic>> result = [];

      for (var sessionData in sessionDataList) {
        final sessionId = sessionData['id'] as int;
        final extensions = extensionsMap[sessionId] ?? <SessionExtension>[];

        // Create Session object from the data
        final session = Session.fromMap(sessionData);

        result.add({
          'session': session,
          'consoleName': sessionData['console_name'],
          'consoleTypeName': sessionData['console_type_name'],
          'hourlyRate': sessionData['hourly_rate'],
          'colorCode': sessionData['color_code'],
          'extensions': extensions,
          'extensionCount': extensions.length,
          'totalExtendedMinutes': extensions.fold<int>(0, (total, ext) => total + ext.additionalMinutes),
          'totalExtendedCost': extensions.fold<double>(0, (total, ext) => total + ext.additionalCost),
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error getting monthly report data: $e');
    }
  }
}