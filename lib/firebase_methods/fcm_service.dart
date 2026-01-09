import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:convert';

import 'package:nainkart_user/main.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure notification channel for Android
    await _configureNotificationChannel();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      _playNotificationSound();
      _checkForIncomingCall(message.data);
    });

    // Handle background/terminated messages when tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(json.encode(message.data));
    });

    // Handle initial message when app is opened from a terminated state
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(json.encode(initialMessage.data));
    }
  }

  static Future<void> _configureNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Same as channelId in _showNotification
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('helium'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _playNotificationSound() async {
    try {
      // Play sound from assets
      await _audioPlayer.play(AssetSource('sounds/helium.mp3'));

      // Also play default notification sound
      await _audioPlayer.play(
          DeviceFileSource('/system/media/audio/notifications/Helium.mp3'));
    } catch (e) {
      // debugPrint('Error playing notification sound: $e');
      // Fallback to default notification sound
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Removed playSound as it is not defined for AndroidFlutterLocalNotificationsPlugin
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('helium'),
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      message.notification?.title ?? 'New Consultation',
      message.notification?.body ?? 'You have a new booking',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
          arguments: data, // Pass data if needed
        );
      }
    } catch (e) {
      // debugPrint('Error decoding notification payload: $e');
    }
  }

  static void _checkForIncomingCall(Map<String, dynamic> data) {
    if (navigatorKey.currentState != null) {
      _runIncomingCallApi();
    }
  }

  static Future<void> _runIncomingCallApi() async {
    try {
      // This will trigger the dashboard to check for incoming calls
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      // debugPrint('Error checking incoming call: $e');
    }
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}
