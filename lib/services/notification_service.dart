import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing NotificationService: $e');
      }
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${notificationResponse.payload}');
    }
  }

  Future<void> showConsoleFinishedNotification({
    required String consoleName,
    required String customerName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'console_finished',
        'Console Finished',
        channelDescription: 'Notifications when console sessions are finished',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Konsol Selesai',
        '$consoleName - $customerName telah selesai',
        platformChannelSpecifics,
        payload: 'console_finished:$consoleName',
      );

      if (kDebugMode) {
        debugPrint('Console finished notification sent for $consoleName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing console finished notification: $e');
      }
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting notification permissions: $e');
      }
    }
  }

  void dispose() {
    // Clean up resources if needed
    if (kDebugMode) {
      debugPrint('NotificationService disposed');
    }
  }
}