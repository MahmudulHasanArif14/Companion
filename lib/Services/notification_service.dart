import 'dart:convert';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:companion/Screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
  FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _friendRequestChannelId = 'default_channel';
  static const String _friendRequestChannelName = 'High Importance Notifications';

  /// Initializes all notification services
  Future<void> initialize(BuildContext context) async {
    try {
      await Firebase.initializeApp();
      await _setupPermissions();
      if (!context.mounted) return;
      await _initializeLocalNotifications(context);
      await _setupFirebaseListeners(context);
      await _handleInitialMessage(context);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  /// Requests notification permissions from the user
  Future<void> _setupPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: Platform.isIOS,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) print("User granted notification permission");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        if (kDebugMode) print("Provisional notification permission granted");
      } else {
        await Future.delayed(const Duration(seconds: 2), () {
          AppSettings.openAppSettings(type: AppSettingsType.notification);
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error requesting permissions: $e');
    }
  }

  /// Initializes local notifications
  Future<void> _initializeLocalNotifications(BuildContext context) async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('launcher_icon');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localPlugin.initialize(
        const InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        ),
        onDidReceiveNotificationResponse: (details) =>
            _handleNotificationTap(context),
      );
    } catch (e) {
      if (kDebugMode) print('Error initializing local notifications: $e');
    }
  }

  /// Sets up Firebase message listeners
  Future<void> _setupFirebaseListeners(BuildContext context) async {
    try {
      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) async {
        if (Platform.isIOS) {
          await _messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
        await _showNotification(message);
      });

      // Background/opened messages
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationMessage(context, message);
      });
    } catch (e) {
      if (kDebugMode) print('Error setting up Firebase listeners: $e');
    }
  }

  /// Handles initial notification when app is launched from terminated state
  Future<void> _handleInitialMessage(BuildContext context) async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message != null && context.mounted) {
        _handleNotificationMessage(context, message);
      }
    } catch (e) {
      if (kDebugMode) print('Error handling initial message: $e');
    }
  }

  /// Registers the device token with Supabase
  Future<void> registerDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      if (kDebugMode) print("Device Token: $token");

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Use upsert to ensure the token is always updated
      await _supabase.from('profiles').upsert({
        'id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _supabase.from('profiles').upsert({
          'id': userId,
          'fcm_token': newToken,
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      if (kDebugMode) print('Error registering device token: $e');
    }
  }
  /// Handles notification tap actions
  void _handleNotificationTap(BuildContext context) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } catch (e) {
      if (kDebugMode) print('Error handling notification tap: $e');
    }
  }

  /// Handles notification messages
  void _handleNotificationMessage(BuildContext context, RemoteMessage message) {
    try {
      // Handle different notification types
      if (message.data['type'] == 'friend_request') {
        // Navigate to friend requests screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Default behavior
        _handleNotificationTap(context);
      }
    } catch (e) {
      if (kDebugMode) print('Error handling notification message: $e');
    }
  }

  /// Displays a notification
  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        _friendRequestChannelId,
        _friendRequestChannelName,
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      );

      await _localPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Notification details
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          icon: 'launcher_icon',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Show notification
      await _localPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      if (kDebugMode) print('Error showing notification: $e');
    }
  }

  /// Sends a friend request notification
  Future<void> sendFriendRequestNotification({
    required String receiverId,
    required String senderName,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send_push_notification',
        body: {
          'user_id': receiverId,
          'title': 'New Friend Request',
          'body': '$senderName sent you a friend request',
          'type': 'friend_request',
        },
      );

      if (response.status != 200) {
        final errorBody = response;
        throw Exception('Failed to send notification: $errorBody');
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  /// Shows a manual notification (for in-app events)
  Future<void> showManualNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'manual_channel',
        'Manual Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localPlugin.show(
        title.hashCode,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) print('Error showing manual notification: $e');
    }
  }

  /// Sends a friend request accepted notification
  Future<void> sendFriendRequestAcceptedNotification({
    required String senderId,
    required String receiverName,
  }) async {
    try {
      // Get sender's FCM token
      final senderData = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('id', senderId)
          .single();

      final fcmToken = senderData['fcm_token'] as String?;
      if (fcmToken == null) return;

      // Send via Supabase function
      await _supabase.rpc('send_push_notification', params: {
        'user_id': senderId,
        'title': 'Friend Request Accepted',
        'body': '$receiverName accepted your friend request',
        'type': 'friend_request_accepted',
      });

      // Also show local notification
      await showManualNotification(
        title: 'Friend Request Accepted',
        body: '$receiverName is now your friend',
      );
    } catch (e) {
      if (kDebugMode) print('Error sending friend request accepted notification: $e');
    }
  }
}