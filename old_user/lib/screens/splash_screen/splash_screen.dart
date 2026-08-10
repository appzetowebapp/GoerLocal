import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../bloc/user_details_bloc/user_details_bloc.dart';
import '../../bloc/user_details_bloc/user_details_state.dart';
import '../../config/global.dart';
import '../../config/helper.dart';
import '../../config/notification_service.dart';
import '../../config/settings_data_instance.dart';
import '../../config/theme.dart';
import '../../services/location/location_service.dart';
import '../home_page/bloc/banner/banner_bloc.dart';
import '../home_page/bloc/banner/banner_event.dart';
import '../home_page/bloc/category/category_bloc.dart';
import '../home_page/bloc/category/category_event.dart';
import '../home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import '../home_page/bloc/feature_section_product/feature_section_product_event.dart';
import '../home_page/bloc/sub_category/sub_category_bloc.dart';
import '../home_page/bloc/sub_category/sub_category_event.dart';
import '../../deep_link.dart';


import 'package:hyper_local/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _hasInitialized = false;
  bool _hasNavigated = false;
  bool _lastKnownConnectivity = false;

  late AnimationController _shineController;
  late AnimationController _exitController;
  late AnimationController _pulseController;

  late Animation<double> _exitZoomAnimation;
  late Animation<double> _exitOpacityAnimation;

  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    getFcm();

    // 1. Shine Effect (Flash)
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 2. Background Aura Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 3. Exit Scale Up (Zoom)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _exitZoomAnimation = Tween<double>(begin: 1.0, end: 15.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInExpo),
    );

    _exitOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Dispatch initial settings fetch immediately
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
  }

  @override
  void dispose() {
    _shineController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<String?> getFcm() async {
    String? fcmToken = await getFCMToken();
    return fcmToken.toString();
  }

  // Helper method to show the location access dialog
  Future<bool?> _showLocationAccessDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.locationAccessNeeded),
        content: Text(
          AppLocalizations.of(dialogContext)!.locationAccessDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext)!.later),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if(dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(AppLocalizations.of(dialogContext)!.openSettings),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if(dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(AppLocalizations.of(dialogContext)!.appPermissions),
          ),
        ],
      ),
    );
  }

  // Modified to use SettingsData.instance directly
  Future<void> _checkAndSetLocation() async {
    // Check if we can skip all location logic based on current stored state
    // Skip this check if we are in Demo Mode, as Demo Mode forces a default location.
    if (!AppHelpers.isDemo && LocationService.hasStoredLocation()) {
      // Location already set and we are NOT in demo mode, so we are done.
      return;
    }

    String? lat, lng;

    // --- 1. Try getting location from SettingsData singleton (Web Settings) ---
    // Note: You specified SettingsData.instance.web instead of .system
    final webSettings = SettingsData.instance.web;
    if (webSettings != null) {
      lat = webSettings.defaultLatitude;
      lng = webSettings.defaultLongitude;
    }

    // Check if we got a valid location from settings
    if (lat != null && lng != null && lat.isNotEmpty && lng.isNotEmpty) {
      // Use the new function to store location with geocoding
      await LocationService.storeLocationFromCoordinates(
        latitude: lat,
        longitude: lng,
      );
      return;
    }

    // --- 2. Fallback to Demo Location (if isDemo is true) ---
    if (AppHelpers.isDemo) {
      lat = AppHelpers.defaultLat;
      lng = AppHelpers.defaultLng;

      if (lat.isNotEmpty && lng.isNotEmpty) {
        // Since we skipped the initial hasStoredLocation check for isDemo == true,
        // this location will be stored regardless of what was previously in Hive.
        await LocationService.storeLocationFromCoordinates(
          latitude: lat,
          longitude: lng,
        );
        return;
      }
      // If AppConstant.isDemo is true but defaultLat/Lng are empty, we fall through to step 3.
    }

    // --- 3. Get Current Location (Default behavior for non-demo mode or if all fallbacks failed) ---
    // This step runs only if:
    // a) AppConstant.isDemo is false AND no location is stored.
    // b) AppConstant.isDemo is true but neither settings nor AppConstant provided valid coordinates.
    if (!LocationService.hasStoredLocation()) {
      final bool? granted = await _showLocationAccessDialog();

      if (granted == true) {
        final currentLoc = await LocationService.requestAndStoreLocationWithRetry();
        if (currentLoc == null) {
          // Handle case where location services are off or permission is denied after prompt
        }
      } else {
        // User pressed 'Later'
      }
    }
  }

  Future<void> navigate() async {
    log('SplashScreen: Navigating... hasNavigated: $_hasNavigated, connectivity: $_lastKnownConnectivity');
    _dispatchInitialDataFetches();
    if (_hasNavigated) {
      return;
    }
    _hasNavigated = true;
    
    // Wait for the minimal splash time (at least 3 seconds total)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (!_lastKnownConnectivity) {
      log('SplashScreen: Navigation aborted - no connectivity');
      _hasNavigated = false;
      return;
    }

    // Start exit animation
    setState(() => _isFinishing = true);
    await _exitController.forward();

    if (!mounted) return;

    // If first launch -> show intro slider
    if (Global.isFirstTime) {
      GoRouter.of(context).go(AppRoutes.introSlider);
      return;
    }

    // If a deep link is being handled, let it take control of navigation
    if (AppLinksDeepLink.instance.hasPendingLink) {
      log('Deep link pending, skipping splash screen navigation');
      return;
    }

    GoRouter.of(context).go(AppRoutes.home);
  }

  void _handleConnectivityChanged(bool isConnected) {
    _lastKnownConnectivity = isConnected;

    if (!isConnected) {
      _hasNavigated = false;
      // You might want to show an offline UI here
      return;
    }

    // Hide offline UI here

    if (!_hasInitialized) {
      _hasInitialized = true;
      navigate();
      return;
    }

    if (!_hasNavigated) {
      navigate();
    }
  }

  void _dispatchInitialDataFetches() {
    // Settings data is already being fetched in initState.
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    // context.read<CartBloc>().add(LoadCart());
    // context.read<GetUserCartBloc>().add(FetchUserCart());
    context.read<BannerBloc>().add(FetchBanner(categorySlug: ""));
    context.read<BrandsBloc>().add(const FetchBrands(categorySlug: ""));
    context.read<SubCategoryBloc>().add(FetchSubCategory(slug: "", isForAllCategory: true));
    context
        .read<FeatureSectionProductBloc>()
        .add(FetchFeatureSectionProducts(slug: ""));
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      // Listen for the settings data to be loaded
      listener: (context, state) async {
        if(state is MaintenanceModeEnabled){
          GoRouter.of(context).go(
            AppRoutes.maintenancePage,
            extra: {
              'message':state.maintenanceModeMessage
            }
          );
          return;
        }
        if (state is SettingsLoaded) {
          log('SplashScreen: Settings loaded successfully');
          if(SettingsData.instance.system?.webMaintenanceMode ?? false) {
            GoRouter.of(context).go(AppRoutes.maintenancePage,);
            return;
          }
          // 1. Check/Set location using SettingsData.instance
          await _checkAndSetLocation();

          // 2. Now that settings and initial location logic is done, proceed with navigation logic
          if (_lastKnownConnectivity) {
            log('SplashScreen: Connectivity is true, triggering navigation');
            _handleConnectivityChanged(true);
          }
        }

        if (state is SettingsFailure) {
          log('SplashScreen: Settings failed to load: ${state.error}');
          // Proceed with fallbacks even if settings fail
          await _checkAndSetLocation();
          if (_lastKnownConnectivity) {
             _handleConnectivityChanged(true);
          }
        }
      },
      child: BlocListener<UserDataBloc, UserDataState>(
        listener: (BuildContext context, UserDataState state) {
          // Your existing UserDataBloc listener logic if needed
        },
        child: CustomScaffold(
          showViewCart: false,
          notifyConnectivityStatusOnInit: true,
          onConnectivityChanged: (isConnected, _) {
            log('SplashScreen: onConnectivityChanged: $isConnected');
            _lastKnownConnectivity = isConnected;
            // Only proceed with navigation if settings have already been loaded or failed,
            // or if the settings bloc listener hasn't run yet (it will handle navigation then).
            final settingsState = context.read<SettingsBloc>().state;
            if (settingsState is SettingsLoaded || settingsState is SettingsFailure) {
              Future.delayed(const Duration(seconds: 1)); // Small delay for UI/Splash
              _handleConnectivityChanged(isConnected);
            }
          },
          body: AnimatedBuilder(
              animation: Listenable.merge(
                  [_shineController, _exitController, _pulseController]),
              builder: (context, child) {
                return Stack(
                  children: [
                    // Background & Doodle
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor, 
                        image: DecorationImage(
                          image: AssetImage('assets/images/doodle.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Pulse Aura
                    Center(
                      child: Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.2),
                        child: Container(
                          width: 350.w,
                          height: 350.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.07),
                                  blurRadius: 100.r,
                                  spreadRadius: 50.r)
                            ],
                          ),
                        ),
                      ),
                    ),

                    // App Logo with Shine & Zoom
                    Center(
                      child: Opacity(
                        opacity:
                            _isFinishing ? _exitOpacityAnimation.value : 1.0,
                        child: Transform.scale(
                          scale: _isFinishing ? _exitZoomAnimation.value : 1.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: const [
                                    Colors.white,
                                    Colors.white,
                                    Colors.white38,
                                    Colors.white,
                                    Colors.white
                                  ],
                                  stops: [
                                    0.0,
                                    (_shineController.value * 1.5) - 0.4,
                                    (_shineController.value * 1.5) - 0.2,
                                    _shineController.value * 1.5,
                                    1.0
                                  ],
                                ).createShader(bounds),
                                child: CustomImageContainer(
                                  imagePath: getAppLogoUrl(context),
                                  height: 270.h,
                                  width: 270.w,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // const SizedBox(height: 20),
                              // const Text('PREMIUM DELIVERY',
                              //     style: TextStyle(
                              //         color: Colors.white,
                              //         letterSpacing: 5,
                              //         fontSize: 10,
                              //         fontWeight: FontWeight.bold)
                              //         ), 
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}