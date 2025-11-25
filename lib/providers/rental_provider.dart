import 'package:flutter/material.dart';
import 'dart:async';
import '../models/console_with_type.dart';
import '../models/session.dart';
import '../models/session_extension.dart';
import '../services/sqlite_service.dart';
import '../utils/performance_utils.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class RentalProvider with ChangeNotifier {
  final SQLiteService _sqliteService = SQLiteService();
  final AudioService _audioService = AudioService();
  final NotificationService _notificationService = NotificationService();
  List<ConsoleWithType> _consoles = [];
  List<Session> _activeSessions = [];
  Timer? _timer;
  final Set<int> _expiredSessionsPlayedMusic = <int>{}; // Track which sessions have played music

  List<ConsoleWithType> get consoles => _consoles;
  List<Session> get activeSessions => _activeSessions;

  RentalProvider() {
    _initializeData();
    _startTimer();
    _initializeNotifications();
  }

  Session? getActiveSessionForConsole(int consoleId) {
    try {
      return _activeSessions.firstWhere((session) => session.consoleId == consoleId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _initializeData() async {
    await loadConsoles();
    await loadActiveSessions();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      PerformanceUtils.throttle(const Duration(seconds: 2), () {
        _checkExpiredSessions();
        notifyListeners();
      });
    });
  }

  Future<void> loadConsoles() async {
    try {
      final consolesWithTypesData = await _sqliteService.getConsolesWithTypes();
      _consoles = consolesWithTypesData.map((data) => ConsoleWithType.fromMap(data)).toList();

      // Use throttled notification to prevent excessive UI updates
      PerformanceUtils.throttle(const Duration(milliseconds: 100), () {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading consoles: $e');
    }
  }

  Future<void> loadActiveSessions() async {
    try {
      _activeSessions = await _sqliteService.getActiveSessions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading active sessions: $e');
    }
  }

  Future<bool> startSession(int consoleId, int durationMinutes, {String? customerName}) async {
    try {
      // Check if console is already active
      final existingSession = await _sqliteService.getActiveSessionByConsoleId(consoleId);
      if (existingSession != null) {
        return false; // Console already in use
      }

      // Get console with type information
      final consolesWithTypesData = await _sqliteService.getConsolesWithTypes();
      final consoleWithTypeData = consolesWithTypesData
          .firstWhere((c) => c['id'] == consoleId, orElse: () => throw Exception('Console not found'));
      final consoleWithType = ConsoleWithType.fromMap(consoleWithTypeData);

      // Calculate cost
      final durationHours = durationMinutes / 60.0;
      final totalCost = durationHours * consoleWithType.hourlyRate;

      // Calculate end time based on duration
      final startTime = DateTime.now();
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      // Create new session with complete data including calculated end time
      final session = Session(
        consoleId: consoleId,
        customerName: customerName,
        startTime: startTime,
        endTime: endTime, // Set calculated end time immediately
        durationMinutes: durationMinutes,
        actualDurationMinutes: durationMinutes, // Set to planned duration initially
        totalCost: totalCost,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _sqliteService.insertSession(session);

      // Update console status
      final updatedConsole = consoleWithType.console.copyWith(isActive: true);
      await _sqliteService.updateConsole(updatedConsole);

      await loadConsoles();
      await loadActiveSessions();

      return true;
    } catch (e) {
      debugPrint('Error starting session: $e');
      return false;
    }
  }

  Future<double> calculateAdditionalCost(int sessionId, int additionalMinutes) async {
    try {
      final sessionIndex = _activeSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return 0.0;

      final session = _activeSessions[sessionIndex];

      // Get console with type information
      final consolesWithTypesData = await _sqliteService.getConsolesWithTypes();
      final consoleWithTypeData = consolesWithTypesData
          .firstWhere((c) => c['id'] == session.consoleId, orElse: () => throw Exception('Console not found'));
      final consoleWithType = ConsoleWithType.fromMap(consoleWithTypeData);

      // Calculate additional cost
      final additionalHours = additionalMinutes / 60.0;
      final additionalCost = additionalHours * consoleWithType.hourlyRate;

      return additionalCost;
    } catch (e) {
      debugPrint('Error calculating additional cost: $e');
      return 0.0;
    }
  }

  Future<bool> extendSession(int sessionId, int additionalMinutes) async {
    try {
      final sessionIndex = _activeSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return false;

      final session = _activeSessions[sessionIndex];

      // Get console with type information
      final consolesWithTypesData = await _sqliteService.getConsolesWithTypes();
      final consoleWithTypeData = consolesWithTypesData
          .firstWhere((c) => c['id'] == session.consoleId, orElse: () => throw Exception('Console not found'));
      final consoleWithType = ConsoleWithType.fromMap(consoleWithTypeData);

      // Calculate additional cost
      final additionalHours = additionalMinutes / 60.0;
      final additionalCost = additionalHours * consoleWithType.hourlyRate;

      // Get next extension number
      final extensionNumber = await _sqliteService.getNextExtensionNumber(sessionId);

      // Create session extension record
      final sessionExtension = SessionExtension(
        sessionId: sessionId,
        extensionNumber: extensionNumber,
        extensionTime: DateTime.now(),
        additionalMinutes: additionalMinutes,
        additionalCost: additionalCost,
        createdAt: DateTime.now(),
      );

      // Insert session extension record
      await _sqliteService.insertSessionExtension(sessionExtension);

      // Update main session with new totals and extension count
      final updatedSession = session.copyWith(
        durationMinutes: session.durationMinutes + additionalMinutes,
        totalCost: session.totalCost + additionalCost,
        extensionCount: session.extensionCount + 1,
        // Update end time to reflect the extension
        endTime: session.endTime?.add(Duration(minutes: additionalMinutes)) ??
                session.startTime.add(Duration(minutes: session.durationMinutes + additionalMinutes)),
      );

      await _sqliteService.updateSession(updatedSession);
      await loadActiveSessions();

      return true;
    } catch (e) {
      debugPrint('Error extending session: $e');
      return false;
    }
  }

  Future<bool> endSession(int sessionId) async {
    try {
      // Stop any playing music when session is manually ended
      await _audioService.stopSound();

      // Remove from expired sessions tracking
      _expiredSessionsPlayedMusic.remove(sessionId);

      final session = _activeSessions.firstWhere((s) => s.id == sessionId);

      // Keep the original duration from input, don't recalculate
      // This ensures the report shows the duration that was originally selected

      // Update session - only update active status
      // Duration and end time remain as originally calculated from input
      final updatedSession = session.copyWith(
        isActive: false,
      );

      await _sqliteService.updateSession(updatedSession);

      // Update console status
      final console = await _sqliteService.getConsole(session.consoleId);
      if (console != null) {
        final updatedConsole = console.copyWith(isActive: false);
        await _sqliteService.updateConsole(updatedConsole);
      }

      await loadConsoles();
      await loadActiveSessions();

      return true;
    } catch (e) {
      debugPrint('Error ending session: $e');
      return false;
    }
  }

  void _checkExpiredSessions() async {
    // Check for newly expired sessions and play music + show notification
    for (final session in _activeSessions) {
      if (session.isExpired && !_expiredSessionsPlayedMusic.contains(session.id!)) {
        // Play music for newly expired session
        await _audioService.playSelesaiSound();

        // Show notification for finished console
        final console = _consoles.firstWhere((c) => c.id == session.consoleId);
        await _notificationService.showConsoleFinishedNotification(
          consoleName: console.name,
          customerName: 'Sesi', // Generic term since customer name is not stored in session
        );

        _expiredSessionsPlayedMusic.add(session.id!);
      }
    }
  }

  // Method to get session extensions for reporting
  Future<List<SessionExtension>> getSessionExtensions(int sessionId) async {
    try {
      return await _sqliteService.getSessionExtensions(sessionId);
    } catch (e) {
      debugPrint('Error getting session extensions: $e');
      return [];
    }
  }

  // Method to get complete session data with extensions for reporting
  Future<Map<String, dynamic>> getCompleteSessionData(int sessionId) async {
    try {
      final session = _activeSessions.firstWhere((s) => s.id == sessionId);
      final extensions = await getSessionExtensions(sessionId);

      return {
        'session': session,
        'extensions': extensions,
        'total_extensions': extensions.length,
        'original_duration': session.originalDurationMinutes,
        'original_cost': session.originalCost,
        'total_extended_minutes': extensions.fold<int>(0, (sum, ext) => sum + ext.additionalMinutes),
        'total_extended_cost': extensions.fold<double>(0, (sum, ext) => sum + ext.additionalCost),
      };
    } catch (e) {
      debugPrint('Error getting complete session data: $e');
      return {};
    }
  }

  String getConsoleStatus(ConsoleWithType console) {
    final activeSession = getActiveSessionForConsole(console.id!);
    if (activeSession == null) {
      return 'READY';
    }

    final remaining = activeSession.remainingTime;
    if (remaining.inSeconds <= 0) {
      return 'Selesai';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color getConsoleStatusColor(ConsoleWithType console) {
    final activeSession = getActiveSessionForConsole(console.id!);
    if (activeSession == null) {
      return Colors.green;
    }

    final remaining = activeSession.remainingTime;
    if (remaining.inSeconds <= 0) {
      return Colors.red;
    } else if (remaining.inMinutes <= 5) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}