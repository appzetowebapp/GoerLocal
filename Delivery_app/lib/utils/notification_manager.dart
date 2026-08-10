import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../config/global.dart';
import '../screens/dashboard/bloc/notification/notification_bloc.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Skip if it's a silent notification (no notification object)
  if (message.notification == null) {
    log('Ignoring silent push notification (likely auth related)');
    return;
  }

  log('Handling background notification: ${message.messageId}');
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      log('⚠️ NotificationManager already initialized');
      return;
    }

    try {
      log('🔔 Initializing NotificationManager...');

      // Request permission
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Handle terminated state (initial message)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log('🚀 App launched from notification (terminated): ${initialMessage.messageId}');
        // Small delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentContext != null) {
            BlocProvider.of<NotificationBloc>(navigatorKey.currentContext!).add(FetchNotifications());
          }
          _handleNotificationTap(initialMessage);
        });
      }

      // Get and save FCM token
      await _retrieveAndSaveFCMToken();

      _initialized = true;
      log('✅ NotificationManager initialization complete');
    } catch (e) {
      log('❌ NotificationManager initialization error: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    try {
      log('📱 Requesting notification permission...');

      // Match working project sequence

      NotificationSettings settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (Platform.isIOS) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      log('📱 Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting permission: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high importance channel for Android to ensure background popups work
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Important notifications for orders and updates.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Main message Heree $message");
      log('📨 Foreground message received : ${message.messageId}');
      log('📨 Foreground message received: ${message.senderId}');
      log('📨 Foreground message received: ${message.threadId}');

      log('Title: ${message.notification?.title}');
      log('Body: ${message.notification?.body}');
      log('Data: ${message.data}');
      log("Image Here: ${message.notification?.android?.imageUrl}");

      _showLocalNotification(message);
      
      // Check if it's an approval notification
      final title = message.notification?.title?.toLowerCase() ?? '';
      final body = message.notification?.body?.toLowerCase() ?? '';
      final type = message.data['type']?.toString().toLowerCase() ?? '';
      
      if (type.contains('approve') || title.contains('approve') || body.contains('approve')) {
        Global.isAccountApprovedNotifier.value = true;
      }
      
      if (navigatorKey.currentContext != null) {
        BlocProvider.of<NotificationBloc>(navigatorKey.currentContext!).add(FetchNotifications());
      }
    });
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📬 Notification tapped (backgrasdound): ${message.messageId}');

      _handleNotificationTap(message);
      if (navigatorKey.currentContext != null) {
        BlocProvider.of<NotificationBloc>(navigatorKey.currentContext!).add(FetchNotifications());
      }
    });

    // Handle background messages - now called in main.dart
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _retrieveAndSaveFCMToken() async {
    try {
      log('🔑 Retrieving FCM & APNs tokens...');
      String? fcmToken = await _firebaseMessaging.getToken();
      log('🔑 FCM Token retrieved: $fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await Global.setFCMToken(fcmToken); // 2/4/26
        log('✅ FCM Token saved to Hive');
      }
      //   }

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('🔄 FCM Token refreshed: $newToken');

        await Global.setFCMToken(newToken); // 2/4/26
      });
    } catch (e) {
      log('❌ Error retrieving tokens: $e');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    await Dio().download(url, filePath);
    return filePath;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    String? imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    List<DarwinNotificationAttachment>? attachments;

    String? localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String fileName = 'notification_img_${notification.hashCode}.jpg';
        final String filePath = await _downloadAndSaveFile(imageUrl, fileName);
        log('✅ Notification image downloaded to: $filePath');
        localImagePath = filePath;

        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: notification.title,
          summaryText: notification.body,
          hideExpandedLargeIcon: false,
        );

        attachments = [DarwinNotificationAttachment(filePath)];
      } catch (e) {
        log('❌ Error downloading notification image: $e');
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: localImagePath != null ? FilePathAndroidBitmap(localImagePath) : null,
      sound: const RawResourceAndroidNotificationSound('notification'),
      fullScreenIntent: true,
      enableVibration: true,
      enableLights: true,
      styleInformation: bigPictureStyleInformation,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      subtitle: '',
      threadIdentifier: 'foreground_threat',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.wav',
      attachments: attachments,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);

        // 2. Extract the type
        final type = payloadData['type']?.toString();

        // 3. Send it directly to your redirection logic
        if (type != null) {
          handleTypeRedirection(type, payloadData);
        }
      } catch (e) {}
    }

    // Handle notification tap
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('📬 Handling notification tap: ${message.data}');

    final type = message.data['type']?.toString();
    final metadata = message.data;
    if (type != null) {
      handleTypeRedirection(type, metadata);
    }
  }

  void handleTypeRedirection(String type, dynamic metadata, {bool fromNotificationScreen = false}) {
    log('🧭 Redirecting for type: $type');
    String? notificationId = metadata?['notification_id'];

    if (notificationId != null) {
      BlocProvider.of<NotificationBloc>(navigatorKey.currentContext!).add(MarkAsRead(notificationId));
    }
    try {
      switch (type) {
        case 'wallet_transaction':
          MyAppRoute.pushUnique(AppRoutes.allEarnings);
          break;
        case 'refer_transaction':
          MyAppRoute.pushUnique(AppRoutes.viewTransactions);
          break;
        case 'withdrawal_request':
        case 'withdrawal_process':
          MyAppRoute.pushUnique(AppRoutes.withdrawalHistory);
          break;
        case 'settlement_process':
        case 'settlement_create':
          MyAppRoute.pushUnique(AppRoutes.earnings);
          break;
        case 'order_ready_for_pickup':
        case 'delivery':
          // FeedPage available orders tab
          MyAppRoute.goUnique('${AppRoutes.feed}?tab=0');
          break;
        case 'return_order_available':
        case 'return_order':
          // FeedPage return orders tab
          MyAppRoute.goUnique('${AppRoutes.feed}?tab=2');
          break;
        case 'order_update':
          if (metadata != null && metadata['order_id'] != null) {
            final int orderId = int.parse(metadata['order_id'].toString());
            // Constructing a consistent location string for comparison
            MyAppRoute.pushUnique(AppRoutes.orderDetails, extra: {'orderId': orderId, 'from': true});
          }
          break;
        default:
          log('⚠️ Unknown notification type: $type');
          // Default to notifications list if type is unknown but tapped
          if (!fromNotificationScreen) {
            MyAppRoute.pushUnique(AppRoutes.notifications);
          }
      }
    } catch (e) {
      log('❌ Redirection error: $e');
    }
  }
}

// Background message handler (must be top-level function)
