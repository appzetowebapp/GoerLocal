import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/widgets/ui/order_notification_handler.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Skip if it's a silent notification (no notification object)
  if (message.notification == null && message.data.isEmpty) {
    log('Ignoring silent push notification (likely auth related)');
    return;
  }

  log('Handling background notification: ${message.messageId}');

  // Ongoing functionality: Flag for refresh in AppLifecycleObserverWidget
  try {
    await Hive.initFlutter();
    final type = message.data['type']?.toString().toLowerCase();
    final orderId = message.data['seller_order_id']?.toString() ?? message.data['order_id']?.toString();

    final isOrderNotification =
        type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);

    final box = await Hive.openBox('notificationRefreshBox');
    if (isOrderNotification) {
      await box.put('pendingOrderRefresh', true);
      log('[BG Handler] Order notification received — pendingOrderRefresh set to true');
    }
    // Always mark that notification count needs refresh
    await box.put('pendingNotificationCountRefresh', true);
  } catch (e) {
    log('❌ Error in background handler Hive storage: $e');
  }
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  RemoteMessage? _pendingMessage;
  bool _initialized = false;

  bool get hasPendingNotification => _pendingMessage != null;

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
      // Store it for SplashScreen to handle properly
      _pendingMessage = await _firebaseMessaging.getInitialMessage();
      if (_pendingMessage != null) {
        log('🚀 Terminated state message found: ${_pendingMessage!.messageId}');
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

  Future<void> showCustomNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  void handlePendingNotification(BuildContext context) {
    if (_pendingMessage != null) {
      log('🚀 Handling pending notification from SplashScreen');
      _handleNotificationTap(_pendingMessage!, fromTerminated: true);
      _pendingMessage = null;
      _refreshAllBlocs();
    }
  }

  Future<void> requestPermission() async {
    try {
      log('📱 Requesting notification permission...');

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
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Important notifications for orders and updates.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📨 Foreground message received: ${message.messageId}');

      final type = message.data['type']?.toString().toLowerCase();
      final orderId = message.data['seller_order_id']?.toString() ?? message.data['order_id']?.toString();

      _refreshAllBlocs();

      // Check if this is an order related notification for bottom sheet
      if (_isOrderRelatedType(type, orderId)) {
        final context = GlobalKeys.navigatorKey.currentContext;
        if (context != null) {
          // Flatten data for the bottom sheet handler to match existing pattern
          Map<String, dynamic> payload = Map.from(message.data);
          payload['title'] = message.notification?.title ?? payload['title'] ?? '';
          payload['body'] = message.notification?.body ?? payload['body'] ?? '';

          OrderNotificationHandler.showOrderAcceptanceBottomSheet(context, payload);
          return; // Skip showing local notification if bottom sheet is shown
        }
      }

      // Automatically navigate to home screen if subscription is successfully activated
      if (type == 'subscription_success' ||
          type == 'subscription_purchased' ||
          type == 'plan_activated' ||
          type == 'subscription' ||
          type == 'plan') {
        final context = GlobalKeys.navigatorKey.currentContext;
        if (context != null) {
          context.go(AppRoutes.home);
          return; // Skip showing local notification
        }
      }

      _showLocalNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📬 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
      _refreshAllBlocs();
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _retrieveAndSaveFCMToken() async {
    try {
      log('🔑 Retrieving tokens...');

      // APNs Token for iOS
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        int retryCount = 0;
        const maxRetries = 10;
        while (apnsToken == null && retryCount < maxRetries) {
          log('Waiting for APNs token... attempt ${retryCount + 1}');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retryCount++;
        }
        if (apnsToken != null) {
          await HiveStorage.setApnsToken(apnsToken);
          log('✅ APNs token saved');
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await HiveStorage.setFcmToken(fcmToken);
        log('✅ FCM Token saved: $fcmToken');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('🔄 FCM Token refreshed: $newToken');
        await HiveStorage.setFcmToken(newToken);
      });
    } catch (e) {
      log('❌ Error retrieving tokens: $e');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = Platform.isIOS
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';

      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      await dio.download(url, filePath);
      return filePath;
    } catch (e) {
      log('❌ Error downloading file: $e');
      return '';
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    String title = notification.title ?? 'Notification';
    String body = notification.body ?? '';
    String? imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    List<DarwinNotificationAttachment>? attachments;
    String? localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String fileName = 'notification_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = await _downloadAndSaveFile(imageUrl, fileName);
        if (filePath.isNotEmpty) {
          log('✅ Notification image downloaded to: $filePath');
          localImagePath = filePath;

          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          );

          attachments = [DarwinNotificationAttachment(filePath)];
        }
      } catch (e) {
        log('❌ Error processing notification image: $e');
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: localImagePath != null ? FilePathAndroidBitmap(localImagePath) : null,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      enableLights: true,
      styleInformation: bigPictureStyleInformation ?? BigTextStyleInformation(body),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      subtitle: '',
      threadIdentifier: 'foreground_threat',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
      attachments: attachments,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      notification?.hashCode ?? message.hashCode,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
        final type = payloadData['type']?.toString().toLowerCase();
        handleTypeRedirection(type, payloadData);
      } catch (e) {
        log('❌ Error parsing tap payload: $e');
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message, {bool fromTerminated = false}) {
    final type = message.data['type']?.toString().toLowerCase();
    handleTypeRedirection(type, message.data, fromTerminated: fromTerminated);
  }

  void handleTypeRedirection(String? type, Map<String, dynamic> metadata, {bool fromTerminated = false}) {
    log('🧭 Redirecting for type: $type');
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null) return;

    String? orderId = metadata['seller_order_id']?.toString() ?? metadata['order_id']?.toString();

    try {
      switch (type) {
        case 'system':
          if (metadata['action'] == 'seller_approved') {
            context.go(AppRoutes.login);
          }
          break;
        case 'wallet_transaction':
          context.push(AppRoutes.wallet);
          break;
        case 'refer_transaction':
          context.push(AppRoutes.transactionHistory);
          break;
        case 'withdrawal_request':
        case 'withdrawal_process':
          context.push(AppRoutes.withdrawHistory);
          break;
        case 'settlement_process':
        case 'settlement_create':
          context.push(AppRoutes.earnings);
          break;
        case 'order_ready_for_pickup':
        case 'delivery':
          // Redirecting to orders since 'feed' doesn't exist in this project
          context.go(AppRoutes.orders);
          break;
        case 'return_order_available':
        case 'return_order':
          context.go(AppRoutes.orders);
          break;
        case 'order_update':
          if (orderId != null && orderId.isNotEmpty) {
            if (fromTerminated) {
              _handleTerminatedOrderNavigation(context, orderId);
            } else {
              context.push('${AppRoutes.orderDetails}/$orderId');
            }
          }
          break;
        case 'subscription_success':
        case 'subscription_purchased':
        case 'plan_activated':
        case 'subscription':
        case 'plan':
          context.go(AppRoutes.home);
          break;
        default:
          if (_isOrderRelatedType(type, orderId)) {
            if (orderId != null && orderId.isNotEmpty) {
              if (fromTerminated) {
                _handleTerminatedOrderNavigation(context, orderId);
              } else {
                context.push('${AppRoutes.orderDetails}/$orderId');
              }
            } else {
              context.go(AppRoutes.orders);
            }
          } else {
            print("Hello");
            log('⚠️ Unknown notification type: $type, navigating home');
            context.push(AppRoutes.notifications);
          }
      }
    } catch (e) {
      log('❌ Redirection error: $e');
      context.go(AppRoutes.home);
    }
  }

  void _handleTerminatedOrderNavigation(BuildContext context, String orderId) {
    context.go(AppRoutes.home);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) {
        context.push('${AppRoutes.orderDetails}/$orderId');
      }
    });
  }

  bool _isOrderRelatedType(String? type, String? orderId) {
    return type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);
  }

  void _refreshAllBlocs() {
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    try {
      context.read<OrdersBloc>().add(RefreshOrders());
      context.read<NotificationListBloc>().add(FetchUnreadCount());

      final switcherState = context.read<StoreSwitcherCubit>().state;
      if (switcherState.selectedStore != null) {
        context.read<HomePageBloc>().add(FetchHomePageData(storeId: switcherState.selectedStore!.id));
      }
      log('✅ Blocs refreshed from NotificationManager');
    } catch (e) {
      log('❌ Error refreshing blocs: $e');
    }
  }
}
