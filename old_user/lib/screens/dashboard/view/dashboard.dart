import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/notification_service.dart';
import 'package:hyper_local/utils/widgets/animated_notched_nav_bar.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../services/location/location_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/cart_service.dart';
import '../../../utils/widgets/custom_toast.dart';

class Dashboard extends StatefulWidget {
  final int index;
  final StatefulNavigationShell navigationShell;
  const Dashboard({
    super.key,
    required this.index,
    required this.navigationShell
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool showBottomNavBar = true;
  late int _uiIndex;
  DateTime? _lastBackPressed;
  final controller = PageController();


  @override
  void initState() {
    super.initState();
    _uiIndex = _calculateUiIndex();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification response received: ${response.payload}');
        if (response.payload != null) {
          try {
            log('User navigating from foreground notification tap');
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            NotificationService.handleNotificationNavigation(data);
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Debug: Print stored location
    final storedLocation = LocationService.getStoredLocation();
    if (storedLocation != null) {
      log('Stored Location: ${storedLocation.fullAddress}');
      log('Area: ${storedLocation.area}');
      log('City: ${storedLocation.city}');
      log('State: ${storedLocation.state}');
    } else {
      log('No location stored in Hive');
    }
  }

  /// Maps Shell Branch Index to UI Index (0-4)
  int _calculateUiIndex() {
    int branchIndex = widget.navigationShell.currentIndex;
    switch (branchIndex) {
      case 0: return 2; // Home -> UI 2 (Center)
      case 1: return 0; // Categories -> UI 0
      case 2: return 1; // Stores -> UI 1
      case 3: return 4; // Account -> UI 4
      case 4: return 3; // Orders -> UI 3
      default: return 2;
    }
  }

  /// Maps UI Index (0-4) back to Shell Branch Index
  void _goBranch(int uiIndex) {
    int branchIndex;
    switch (uiIndex) {
      case 0: branchIndex = 1; break; // Categories
      case 1: branchIndex = 2; break; // Stores
      case 2: branchIndex = 0; break; // Home (Center)
      case 3: branchIndex = 4; break; // Orders
      case 4: branchIndex = 3; break; // Account
      default: branchIndex = 0;
    }

    widget.navigationShell.goBranch(branchIndex);
    _uiIndex = uiIndex;
    setState(() {});
    context.read<CartBloc>().add(LoadCart());
  }

  Future<void> _handleBack(BuildContext context) async {
    if (widget.navigationShell.currentIndex != 0) {
      _goBranch(2); // Go back to Home (UI index 2)
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)?.pressAgainToExitTheApp ?? 'Press again to exit the app',
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    _uiIndex = _calculateUiIndex();
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if(state.errorMessage != null) {
            ToastManager.show(
              context: context,
              message: state.errorMessage ?? 'Failed to add item to cart',
              type: ToastType.error,
            );
          }
        }
        CartService.triggerCartAnimationOnFirstAdd(context, state);
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          await _handleBack(context);
        },
        child: Scaffold(
          extendBody: true, // Crucial for notched bars
          body: widget.navigationShell,
          bottomNavigationBar: AnimatedNotchedNavBar(
            currentIndex: _uiIndex,
            onTap: _goBranch,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

