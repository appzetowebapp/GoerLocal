import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/model/settings_model/settings_model.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_event.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_state.dart';
import 'package:hyper_local/screens/home_page/bloc/previously_bought/previously_bought_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/previously_bought/previously_bought_event.dart';
import 'package:hyper_local/screens/home_page/bloc/home_delivery/home_delivery_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/home_delivery/home_delivery_event.dart';
import 'package:hyper_local/screens/home_page/bloc/home_delivery/home_delivery_state.dart';
import 'package:hyper_local/screens/home_page/view/widgets/previously_bought_section.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_event.dart';
import 'package:hyper_local/screens/home_page/widgets/brands_widget.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../config/notification_service.dart';
import '../../../deep_link.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../bloc/banner/banner_bloc.dart';
import '../bloc/banner/banner_state.dart';
import '../bloc/brands/brands_bloc.dart';
import '../model/category_model.dart';
import '../model/featured_section_product_model.dart';
import '../widgets/animated_text_field.dart';
import '../widgets/banner_slider.dart';
import '../bloc/category/category_state.dart';
import '../widgets/location_bottom_sheet.dart';
import '../widgets/product_feature_section_widget.dart';
import '../widgets/sub_category_feature_section_widget.dart';
import '../../../utils/widgets/empty_states_page.dart';
import '../bloc/sub_category/sub_category_state.dart';
import '../../notification_page/bloc/notification_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final AppLinksDeepLink _appLinksDeepLink = AppLinksDeepLink.instance;
  late TabController _tabController;
  final ScrollController nestedScrollController = ScrollController();
  late String backgroundImagePath = '';
  String? backgroundColor;
  bool _isImageEmpty = false;
  Color? textColor;
  List<CategoryData> _categories = [];
  bool _isTabControllerInitialized = false;
  bool _isFlexibleSpaceHidden = false;
  bool _isRecreatingTabController = false;
  Color? _originalTextColor;
  Color? _collapsedTextColor;
  String? _lastLocationIdentifier;
  final Map<int, bool> _isLoadingMoreForTab = {};
  int localCategoryLength = 0;
  String _tabBarViewKey = 'initial';
  int _previousCategoryLength = 0;
  bool _isRedirecting = false;
  double _appBarOpacity = 1.0;
  bool _showScrollToTop = false;
  double _lastScrollPixels = 0.0;
  static const double _scrollThreshold = 100.0;
  double _latestScrollPixels = 0.0;
  bool isRetry = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        // App was launched via a notification
        NotificationService.handleNotificationNavigation(message.data);
      }
    });
    _appLinksDeepLink.initDeepLinks(context);
    _isImageEmpty = backgroundImagePath.isEmpty;
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_onTabChanged); // NEW: Add listener initially
    _isTabControllerInitialized = true; // NEW: Set flag for initial controller
    nestedScrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (AppLinksDeepLink.instance.hasPendingLink) {
          log('HomePage: Deep link pending, skipping initial API calls');
          return;
        }
        _applyHomeGeneralSettingsToAppBar();
        context.read<UserProfileBloc>().add(FetchUserProfile());
        // NEW: Trigger initial API calls and category fetch if not already handled by location
        final box = Hive.box<dynamic>('userLocationBox');
        final storedLocation = box.get('user_location');
        if (storedLocation != null) {
          // Location exists, refresh will handle in build
        } else {
          // No location, but still fetch categories if needed (or show no location page)
          context.read<CategoryBloc>().add(FetchCategory(context: context));
          apiCalls(''); // Fetch "All" tab data
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initialiseColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index == 0) {
        _applyHomeGeneralSettingsToAppBar();
      }
      if (!_isImageEmpty && backgroundImagePath.isNotEmpty) {
        // Precache into memory using the same provider
        final provider = CachedNetworkImageProvider(backgroundImagePath);
        precacheImage(provider, context);
      }
    });
  }

  void initialiseColors() {
    _originalTextColor = Colors.white;
    _collapsedTextColor = Colors.white;
    textColor = _originalTextColor;
  }

  void updateAppBarBackground(
      {String? image, String? bgColor, Color? fontColor}) {
    setState(() {
      backgroundImagePath = image ?? '';
      backgroundColor = bgColor;
      _isImageEmpty = backgroundImagePath.isEmpty;
      _originalTextColor = fontColor ?? Colors.white;
      if (_isFlexibleSpaceHidden) {
        textColor = _collapsedTextColor;
      } else {
        textColor = _originalTextColor;
      }
    });
  }

  Color? _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    try {
      if (hexColor.startsWith('0x') || hexColor.startsWith('0X')) {
        return Color(int.parse(hexColor));
      }
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse('0x$cleanHex'));
    } catch (e) {
      return null;
    }
  }

  void _onTabChanged() {
    if (!_canUseTabController || _isRedirecting) return;

    final int index = _tabController.index;
    final int totalTabs = _categories.length + 1;

    if (index >= totalTabs) {
      _ensureValidTabIndex();
      return;
    }

    context
        .read<FeatureSectionProductBloc>()
        .add(ClearFeatureSectionProducts());

    if (index == 0) {
      apiCalls('');
      _applyHomeGeneralSettingsToAppBar();
    } else if (index > 0 && index - 1 < _categories.length) {
      final category = _categories[index - 1];
      apiCalls(category.slug ?? '');
      updateAppBarBackground(
        image: category.banner,
        bgColor: category.backgroundColor,
        fontColor: hexStringToColor(category.fontColor),
      );
    }

    scrollToTop(animated: true);
  }

  void _ensureValidTabIndex() {
    log('Ensure Valid Tab Index ${(!mounted || !_canUseTabController || _isRedirecting)}');
    if (!mounted || !_canUseTabController || _isRedirecting) return;

    final int totalTabs = _categories.length + 1;
    final int currentIndex = _tabController.index;
    if (currentIndex >= totalTabs || currentIndex < 0) {
      _isRedirecting = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_canUseTabController) {
          _isRedirecting = false;
          return;
        }

        // 1. First, switch to "All" tab
        _tabController.animateTo(0);

        // 2. Apply "All" tab settings IMMEDIATELY
        _applyHomeGeneralSettingsToAppBar();

        // 3. Clear feature section products to prevent showing old data
        context
            .read<FeatureSectionProductBloc>()
            .add(ClearFeatureSectionProducts());

        // 4. Make API calls with empty slug (for "All" tab)
        apiCalls('');

        // 5. Force TabBarView rebuild to reset scroll
        setState(() {
          _tabBarViewKey = 'reset_${DateTime.now().millisecondsSinceEpoch}';
        });

        // 6. Scroll NestedScrollView to top
        if (nestedScrollController.hasClients) {
          nestedScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Reset flag after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isRedirecting = false;
          }
        });
      });
    }
  }

  bool get _canUseTabController =>
      _isTabControllerInitialized && !_isRecreatingTabController && mounted;

  void _initializeTabController(int categoriesLength) {
    if (_tabController.length != categoriesLength + 1 &&
        !_isRecreatingTabController) {
      _isRecreatingTabController = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isRecreatingTabController = false;
          return;
        }

        try {
          // Existing: Remove listener and dispose
          _tabController.removeListener(_onTabChanged);
          _tabController.dispose();

          _tabController = TabController(
            length: categoriesLength + 1,
            vsync: this,
          );

          _tabController.addListener(_onTabChanged); // Ensure listener is added
          _isTabControllerInitialized = true;
          _isRecreatingTabController = false;

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          _isRecreatingTabController = false;
          log('Error recreating TabController: $e');
        }
      });
    }
  }

  void apiCalls(String slug) async {
    // Don't use controller if it's being recreated
    if (!_canUseTabController) {
      return;
    }

    if (_tabController.index == 0) {
      context
          .read<FeatureSectionProductBloc>()
          .add(FetchFeatureSectionProducts(slug: ''));
      context
          .read<SubCategoryBloc>()
          .add(FetchSubCategory(slug: '', isForAllCategory: true));
      context.read<BrandsBloc>().add(FetchBrands(categorySlug: ''));
      context.read<BannerBloc>().add(FetchBanner(categorySlug: ''));
      context.read<GetUserCartBloc>().add(FetchUserCart());
      context.read<GetAddressListBloc>().add(FetchUserAddressList());
      context.read<NotificationBloc>().add(FetchNotifications());
      context.read<PreviouslyBoughtBloc>().add(FetchPreviouslyBoughtProducts());
    } else {
      context
          .read<SubCategoryBloc>()
          .add(FetchSubCategory(slug: slug, isForAllCategory: false));
      context.read<BannerBloc>().add(FetchBanner(categorySlug: slug));
      context.read<BrandsBloc>().add(FetchBrands(categorySlug: slug));
      context
          .read<FeatureSectionProductBloc>()
          .add(FetchFeatureSectionProducts(slug: slug));
      context.read<GetUserCartBloc>().add(FetchUserCart());
      context.read<GetAddressListBloc>().add(FetchUserAddressList());
      context.read<NotificationBloc>().add(FetchNotifications());
    }
    await Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        context.read<SettingsBloc>().add(FetchSettingsData(context: context));
      }
    });
  }

  void _refreshDataForCurrentTab() {
    if (_tabController.index == 0) {
      apiCalls('');
    } else if (_categories.isNotEmpty &&
        (_tabController.index - 1) < _categories.length) {
      final selectedCategory = _categories[_tabController.index - 1];
      apiCalls(selectedCategory.slug ?? '');
    } else {
      apiCalls('');
    }
  }

  void _refreshApiOnLocationChange() {
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    if (!AppHelpers.systemVendorTypeIsSingle) {
      context
          .read<NearByStoreBloc>()
          .add(FetchNearByStores(perPage: 15, searchQuery: ''));
    }
  }

  void _scrollListener() {
    double expandedHeight = 160.0.h;
    const double toolbarHeight = kToolbarHeight;
    final double flexibleSpaceHeight = expandedHeight - toolbarHeight;
    final double currentOffset = nestedScrollController.offset;
    final bool isHidden = currentOffset >= (flexibleSpaceHeight - 10);
    _appBarOpacity = (1 - (currentOffset / expandedHeight)).clamp(0.0, 1.0);

    if (_isFlexibleSpaceHidden != isHidden) {
      setState(() {
        _isFlexibleSpaceHidden = isHidden;
        if (_isFlexibleSpaceHidden) {
          textColor = _collapsedTextColor ??
              (Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightFontColor
                  : AppTheme.darkFontColor);
        } else {
          textColor = _originalTextColor ??
              (Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightFontColor
                  : AppTheme.darkFontColor);
        }
      });
    }
  }

  @override
  void dispose() {
    nestedScrollController.removeListener(_scrollListener);
    nestedScrollController.dispose();
    if (_isTabControllerInitialized) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    super.dispose();
  }

  Widget _buildFlexibleSpaceBackground() {
    if (!_isImageEmpty && backgroundImagePath.isNotEmpty) {
      return CustomImageContainer(
        imagePath: backgroundImagePath,
        fit: BoxFit.cover,
      );
    } else {
      return _buildGradientBackground();
    }
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(
                255, 232, 228, 254), // Deep Navy (matching CustomScaffold)
            Color.fromARGB(255, 234, 233, 251), // Deep Purple
            Color.fromARGB(255, 251, 251, 255), // Rich Violet
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(dynamic category, bool isSelected) {
    String? imageUrl;
    if (category.icon != null && category.icon!.isNotEmpty) {
      imageUrl = isSelected && category.activeIcon != null
          ? category.activeIcon
          : category.icon;
    } else if (category.image != null && category.image!.isNotEmpty) {
      imageUrl = category.image;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CustomImageContainer(
        imagePath: imageUrl,
        fit: BoxFit.contain,
      );
    } else {
      return const Icon(
        Icons.category_outlined,
        size: 28,
      );
    }
  }

  bool _isValidHomeGeneralSettings(HomeGeneralSettings settings) {
    return settings.title.trim().isNotEmpty ||
        settings.icon.trim().isNotEmpty ||
        settings.activeIcon.trim().isNotEmpty;
  }

  void _applyHomeGeneralSettingsToAppBar() {
    final settings = SettingsData.instance.homeGeneralSettings;
    if (settings == null || !_isValidHomeGeneralSettings(settings)) {
      _collapsedTextColor = Theme.of(context).brightness == Brightness.light
          ? AppTheme.lightFontColor
          : AppTheme.darkFontColor;
      updateAppBarBackground(
        image: '',
        bgColor: null,
        fontColor: Theme.of(context).brightness == Brightness.light
            ? AppTheme.lightFontColor
            : AppTheme.darkFontColor,
      );
      return;
    }

    final String image =
        settings.backgroundImage.isNotEmpty ? settings.backgroundImage : '';
    final String? bgColor =
        settings.backgroundColor.isNotEmpty ? settings.backgroundColor : null;
    final Color? fontColor = settings.fontColor.isNotEmpty
        ? _getColorFromHex(settings.fontColor)
        : null;
    // if (fontColor != null) {
    //   _collapsedTextColor = fontColor;
    // }

    updateAppBarBackground(
      image: image,
      bgColor: bgColor,
      fontColor: fontColor,
    );
  }

  Widget _buildAllTabStatic() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final bool isSelected = _tabController.index == 0;
        return Tab(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  HeroiconsOutline.squares2x2,
                  size: 28,
                  color: isSelected ? Colors.purple : const Color(0xFF131124),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.all,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.black : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 25,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllTabDynamic(HomeGeneralSettings settings) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final bool isSelected = _tabController.index == 0;
        final String iconUrl = isSelected
            ? (settings.activeIcon.isNotEmpty
                ? settings.activeIcon
                : settings.icon)
            : settings.icon;
        Widget iconWidget;
        if (iconUrl.isNotEmpty) {
          iconWidget = CachedNetworkImage(
            imageUrl: iconUrl,
            fit: BoxFit.contain,
          );
        } else {
          iconWidget = Icon(
            HeroiconsOutline.squares2x2,
            size: 28,
            color: isSelected ? Colors.purple : const Color(0xFF131124),
          );
        }

        return Tab(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 65,
                height: 65,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: iconWidget,
              ),
              const SizedBox(height: 8),
              Text(
                settings.title.isNotEmpty
                    ? settings.title
                    : AppLocalizations.of(context)!.all,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.black : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 25,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAddress() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<dynamic>('userLocationBox').listenable(),
      builder: (context, Box<dynamic> box, _) {
        final storedLocation = box.get('user_location');
        final locationIdentifier = storedLocation == null
            ? null
            : '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';

        if (_lastLocationIdentifier != locationIdentifier) {
          _lastLocationIdentifier = locationIdentifier;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshApiOnLocationChange();
            _refreshDataForCurrentTab();
            
            if (storedLocation != null) {
              context.read<HomeDeliveryBloc>().add(
                FetchHomeDeliveryData(
                  latitude: storedLocation.latitude,
                  longitude: storedLocation.longitude,
                  token: Global.token,
                  addressLabel: storedLocation.addressType?.isNotEmpty == true 
                      ? storedLocation.addressType! 
                      : (storedLocation.area?.isNotEmpty == true ? storedLocation.area! : 'Home'),
                )
              );
            }
          });
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useRootNavigator: true,
                        builder: (context) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 50),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(child: LocationBottomSheet()),
                          ],
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(TablerIcons.map_pin_filled,
                                size: 22, color: const Color(0xFF131124)),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                storedLocation?.area.isNotEmpty == true
                                    ? storedLocation!.area
                                    : 'Select Location',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF131124),
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 2),
                            const Icon(TablerIcons.chevron_down,
                                size: 20, color: Color(0xFF131124)),
                          ],
                        ),
                        SizedBox(height: 2),
                        SizedBox(
                          width: 200.w,
                          child: Text(
                            storedLocation?.fullAddress.isNotEmpty == true
                                ? '${storedLocation!.fullAddress} >'
                                : '',
                            style: const TextStyle(
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // New Delivery Section
                        BlocBuilder<HomeDeliveryBloc, HomeDeliveryState>(
                          builder: (context, state) {
                            String etaText = '-- minutes';
                            String distanceText = 'Calculating...';

                            if (state is HomeDeliveryLoaded) {
                              etaText = '${state.estimatedMinutes} minutes';
                              final km = state.distanceKm;
                              final kmLabel = km < 1 ? '${(km * 1000).round()} m away' : '${km.round()} km away';
                              distanceText = '${state.addressLabel} - $kmLabel';
                            } else if (state is HomeDeliveryNotAvailable) {
                              etaText = 'N/A';
                              distanceText = 'Delivery not available here';
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        etaText,
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF131124),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.flash_on, size: 14, color: Colors.purple),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Delivery',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        distanceText,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                    BlocBuilder<UserProfileBloc, UserProfileState>(
                      builder: (context, state) {
                        String balance = '0';
                        if (state is UserProfileLoaded) {
                          balance =
                              state.userData.data?.walletBalance?.toString() ??
                                  '0';
                        }
                        return GestureDetector(
                          onTap: () => context.push(AppRoutes.wallet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            // decoration: BoxDecoration(
                            //   color: Colors.white,
                            //   borderRadius: BorderRadius.circular(15),
                            //   boxShadow: [
                            //     BoxShadow(
                            //       color: Colors.black.withValues(alpha: 0.05),
                            //       blurRadius: 10,
                            //       offset: const Offset(0, 4),
                            //     ),
                            //   ],
                            // ),
                            // child: Column(
                            //   children: [
                            //     Image.asset(
                            //       'assets/images/wallet/wallet.png',
                            //       height: 30,
                            //     ),
                            //     const SizedBox(height: 2),
                            //     Text( 
                            //       '₹$balance',
                            //       style: const TextStyle(
                            //         color: Color(0xFF131124),
                            //         fontSize: 10,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.notifications),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/wallet/notification.png',
                          height: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ],
        );
      },
    );
  }

  Widget productFeaturedSectionEmptyState() {
    return SizedBox(
      height: isTablet(context) ? 240.h : 350.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: ShimmerWidget.rectangular(
              isBorder: true,
              height: 18,
              width: 200,
              borderRadius: 15,
            ),
          ),
          SizedBox(
            height: 210.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 20),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    children: [
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 105,
                        width: 100,
                        borderRadius: 15,
                      ),
                      const SizedBox(height: 10.0),
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 15,
                        width: 100,
                        borderRadius: 15,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<GetUserCartBloc, GetUserCartState>(
      listener: (BuildContext context, GetUserCartState state) {},
      child: CustomScaffold(
        showViewCart: true,
        backgroundColor: Colors.transparent,
        onConnectivityRestored: (context) async {
          context.read<CartBloc>().add(SyncLocalCart(context: context));
          _refreshDataForCurrentTab(); // Simplified: Use existing refresh
        },
        body: Stack(
          children: [
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (BuildContext context, CategoryState state) {
                final homeGeneralSettings =
                    SettingsData.instance.homeGeneralSettings;
                List<Widget> tabBarTabs = [
                  if (homeGeneralSettings != null &&
                      _isValidHomeGeneralSettings(homeGeneralSettings))
                    _buildAllTabDynamic(homeGeneralSettings)
                  else
                    _buildAllTabStatic(),
                ];
                List<Widget> tabBarViewChildren = [
                  CustomRefreshIndicator(
                    onRefresh: () async {
                      apiCalls('');
                      _applyHomeGeneralSettingsToAppBar();
                      context
                          .read<CategoryBloc>()
                          .add(FetchCategory(context: context));
                    },
                    child: BlocBuilder<BannerBloc, BannerState>(
                      builder: (context, bannerState) {
                        return BlocBuilder<SubCategoryBloc, SubCategoryState>(
                          builder: (context, subCategoryState) {
                            return BlocBuilder<FeatureSectionProductBloc,
                                FeatureSectionProductState>(
                              builder: (context, featureSectionState) {
                                return BlocBuilder<BrandsBloc, BrandsState>(
                                  builder: (context, brandsState) {
                                    final hasFailed = (bannerState
                                            is BannerFailed &&
                                        subCategoryState is SubCategoryFailed &&
                                        featureSectionState
                                            is FeatureSectionProductFailed &&
                                        brandsState is BrandsFailed);

                                    if (hasFailed) {
                                      return NoDeliveryLocationPage(
                                        onRetry: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useRootNavigator: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 30),
                                                  child: Center(
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                              blurRadius: 8,
                                                              offset:
                                                                  Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                    child:
                                                        LocationBottomSheet()),
                                              ],
                                            ),
                                          );

                                          /*setState(() {
                                            isRetry = true;
                                          });
                                          if (_tabController.index > 0) {
                                            final selectedCategory = _categories[_tabController
                                                .index - 1];
                                            apiCalls(selectedCategory.slug ?? '');
                                          } else {
                                            apiCalls('');
                                          }
                                          context.read<CategoryBloc>().add(
                                              FetchCategory(context: context));*/
                                        },
                                      );
                                    }

                                    return CustomScrollView(
                                      clipBehavior: Clip.antiAlias,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<BannerBloc,
                                              BannerState>(
                                            builder: (BuildContext context,
                                                BannerState state) {
                                              if (state is BannerLoaded) {
                                                return AutoPlayCarouselSlider(
                                                    banners:
                                                        state.topBannerData);
                                              } else if (state
                                                  is BannerLoading) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      20.0),
                                                  child:
                                                      ShimmerWidget.rectangular(
                                                          isBorder: true,
                                                          height: 220),
                                                );
                                              }
                                              return SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: PreviouslyBoughtSection(),
                                        ),
                                        SliverToBoxAdapter(
                                            child:
                                                SubCategoryFeatureSectionWidget()),
                                        SliverToBoxAdapter(
                                          child: BrandsSection(
                                            brandsSectionTitle:
                                                AppLocalizations.of(context)
                                                        ?.topBrands ??
                                                    'Top Brands',
                                            categorySlug: '',
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<
                                              FeatureSectionProductBloc,
                                              FeatureSectionProductState>(
                                            builder: (context, state) {
                                              if (state
                                                  is FeatureSectionProductLoaded) {
                                                final validSections = state
                                                    .featureSectionProductData
                                                    .where((s) =>
                                                        s.products.isNotEmpty)
                                                    .toList();

                                                final List<Widget>
                                                    sectionWidgets = [];

                                                log(' Feature Section All Tab $validSections');
                                                if (validSections.isNotEmpty) {
                                                  // Add first featured section
                                                  sectionWidgets.add(
                                                      _buildFeatureSection(
                                                          validSections.first));

                                                  // Add the middle banner AFTER the first section
                                                  sectionWidgets.add(
                                                      middleBannersWidget());

                                                  // Add remaining sections
                                                  if (validSections.length >
                                                      1) {
                                                    sectionWidgets.addAll(
                                                      validSections.skip(1).map(
                                                          (s) =>
                                                              _buildFeatureSection(
                                                                  s)),
                                                    );
                                                  }
                                                } else {
                                                  // No real sections → still show the banner (in the featured area)
                                                  sectionWidgets.add(
                                                      middleBannersWidget());
                                                  // Optional: add placeholder / message
                                                  // sectionWidgets.add(const Text("No featured products right now"));
                                                }

                                                return ListView(
                                                  padding:
                                                      EdgeInsets.only(top: 5.h),
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: [
                                                    ...sectionWidgets,
                                                    if (!state.hasReachedMax)
                                                      const Padding(
                                                        padding: EdgeInsets.all(
                                                            16.0),
                                                        child: Center(
                                                            child:
                                                                CustomCircularProgressIndicator()),
                                                      ),
                                                  ],
                                                );
                                              }

                                              if (state
                                                  is FeatureSectionProductLoading) {
                                                return productFeaturedSectionEmptyState();
                                              }

                                              // Error / fallback → still try to show banner
                                              return Column(
                                                children: [
                                                  middleBannersWidget(),
                                                  const SizedBox(height: 32),
                                                  // const Text("Couldn't load featured items", style: ...),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: 100.h,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ];

                if (state is CategoryLoaded) {
                  if (isRetry) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            isRetry = false;
                          });
                        }
                      });
                    });
                  }
                  final newCategories = state.categoryData;
                  final int totalTabs = newCategories.length + 1;
                  final bool categoriesChanged =
                      _previousCategoryLength != newCategories.length;
                  final int oldLength = _previousCategoryLength;
                  _previousCategoryLength = newCategories.length;

                  _categories = newCategories;

                  if (_tabController.length != totalTabs) {
                    _initializeTabController(newCategories.length);

                    if (oldLength == 0) {
                      apiCalls('');
                    }
                  }

                  // Critical: Handle invalid tab index when category is removed
                  if (_tabController.index >= totalTabs) {
                    _ensureValidTabIndex();
                  } else if (categoriesChanged &&
                      _tabController.index > 0 &&
                      !_isRedirecting) {
                    // Verify current category still exists by slug
                    final currentIndex = _tabController.index - 1;
                    if (currentIndex >= 0 &&
                        currentIndex <
                            oldLength - (oldLength - newCategories.length)) {
                      // Check if we need to redirect
                      if (currentIndex >= newCategories.length) {
                        _ensureValidTabIndex();
                      } else {
                        Future.delayed(Duration(milliseconds: 600), () {
                          apiCalls('');
                          _applyHomeGeneralSettingsToAppBar();
                        });
                      }
                    }
                  }

                  tabBarTabs.addAll(_categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    return AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        bool isSelected = _tabController.index == index + 1;
                        return Tab(
                          height: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 65,
                                height: 65,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildTabIcon(category, isSelected),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.title ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 3,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList());

                  // Build TabBarView children for categories
                  tabBarViewChildren
                      .addAll(_categories.asMap().entries.map((entry) {
                    final category = entry.value;

                    return CustomRefreshIndicator(
                      onRefresh: () async {
                        apiCalls(category.slug ?? '');
                        updateAppBarBackground(
                          image: category.banner,
                          bgColor: category.backgroundColor,
                          fontColor: hexStringToColor(category.fontColor),
                        );
                        context
                            .read<CategoryBloc>()
                            .add(FetchCategory(context: context));
                      },
                      child: BlocBuilder<BannerBloc, BannerState>(
                        builder: (context, bannerState) {
                          return BlocBuilder<SubCategoryBloc, SubCategoryState>(
                            builder: (context, subCategoryState) {
                              return BlocBuilder<FeatureSectionProductBloc,
                                  FeatureSectionProductState>(
                                builder: (context, featureSectionState) {
                                  return BlocBuilder<BrandsBloc, BrandsState>(
                                    builder: (context, brandsState) {
                                      final hasFailed = bannerState
                                              is BannerFailed &&
                                          subCategoryState
                                              is SubCategoryFailed &&
                                          featureSectionState
                                              is FeatureSectionProductFailed &&
                                          brandsState is BrandsFailed;

                                      if (hasFailed) {
                                        return NoDeliveryLocationPage(
                                          onRetry: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              useRootNavigator: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (context) => Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 30),
                                                    child: Center(
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                blurRadius: 8,
                                                                offset: Offset(
                                                                    0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: const Icon(
                                                            Icons.close,
                                                            size: 20,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                      child:
                                                          LocationBottomSheet()),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }

                                      return CustomScrollView(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        slivers: [
                                          SliverToBoxAdapter(
                                            child: BlocBuilder<BannerBloc,
                                                BannerState>(
                                              builder: (BuildContext context,
                                                  BannerState state) {
                                                if (state is BannerLoaded) {
                                                  return AutoPlayCarouselSlider(
                                                      banners:
                                                          state.topBannerData);
                                                } else if (state
                                                    is BannerLoading) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20.0),
                                                    child: ShimmerWidget
                                                        .rectangular(
                                                            isBorder: true,
                                                            height: 220),
                                                  );
                                                }
                                                return SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          const SliverToBoxAdapter(
                                            child: PreviouslyBoughtSection(),
                                          ),
                                          SliverToBoxAdapter(
                                              child:
                                                  SubCategoryFeatureSectionWidget()),
                                          SliverToBoxAdapter(
                                              child: BrandsSection(
                                            brandsSectionTitle:
                                                AppLocalizations.of(context)
                                                        ?.topBrands ??
                                                    'Top Brands',
                                            categorySlug: category.slug ?? '',
                                          )),
                                          SliverToBoxAdapter(
                                            child: BlocBuilder<
                                                FeatureSectionProductBloc,
                                                FeatureSectionProductState>(
                                              builder: (context, state) {
                                                if (state
                                                    is FeatureSectionProductLoaded) {
                                                  final validSections = state
                                                      .featureSectionProductData
                                                      .where((s) =>
                                                          s.products.isNotEmpty)
                                                      .toList();

                                                  final List<Widget>
                                                      sectionWidgets = [];

                                                  log(' Feature Section All Tab $validSections');
                                                  if (validSections
                                                      .isNotEmpty) {
                                                    // Add first featured section
                                                    sectionWidgets.add(
                                                        _buildFeatureSection(
                                                            validSections
                                                                .first));

                                                    // Add the middle banner AFTER the first section
                                                    sectionWidgets.add(
                                                        middleBannersWidget());

                                                    // Add remaining sections
                                                    if (validSections.length >
                                                        1) {
                                                      sectionWidgets.addAll(
                                                        validSections
                                                            .skip(1)
                                                            .map((s) =>
                                                                _buildFeatureSection(
                                                                    s)),
                                                      );
                                                    }
                                                  } else {
                                                    // No real sections → still show the banner (in the featured area)
                                                    sectionWidgets.add(
                                                        middleBannersWidget());
                                                    // Optional: add placeholder / message
                                                    // sectionWidgets.add(const Text("No featured products right now"));
                                                  }

                                                  return ListView(
                                                    padding: EdgeInsets.only(
                                                        top: 5.h),
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    children: [
                                                      ...sectionWidgets,
                                                      if (!state.hasReachedMax)
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  16.0),
                                                          child: Center(
                                                              child:
                                                                  CustomCircularProgressIndicator()),
                                                        ),
                                                    ],
                                                  );
                                                }

                                                if (state
                                                    is FeatureSectionProductLoading) {
                                                  return productFeaturedSectionEmptyState();
                                                }

                                                // Error / fallback → still try to show banner
                                                return Column(
                                                  children: [
                                                    middleBannersWidget(),
                                                    const SizedBox(height: 32),
                                                    // const Text("Couldn't load featured items", style: ...),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          const SliverToBoxAdapter(
                                            child: PreviouslyBoughtSection(),
                                          ),
                                          SliverToBoxAdapter(
                                            child: SizedBox(
                                              height: 100.h,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  }).toList());
                }

                if (state is CategoryFailed && isRetry) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          isRetry = false;
                        });
                      }
                    });
                  });
                }

                return NestedScrollView(
                  controller: nestedScrollController,
                  physics: _canUseTabController
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [ 
                      SliverAppBar(
                        expandedHeight: _canUseTabController ? 195.0 : 120,
                        floating: false, 
                        pinned: true,
                        elevation: 0, 
                        backgroundColor: _isFlexibleSpaceHidden
                            ?Color.fromARGB(255, 215, 214, 255)
                            :Color.fromARGB(255, 215, 214, 255),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        surfaceTintColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        toolbarHeight: 120,
                        title: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _buildTopAddress(),
                        ),
                        titleSpacing: 16,
                        centerTitle: false,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildFlexibleSpaceBackground(),
                        ),
                        actions: null,
                        bottom: _canUseTabController
                            ? PreferredSize(
                                preferredSize: const Size.fromHeight(70),
                                child: Column(
                                  children: [
                                    CustomAnimatedTextField(),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              )
                            : PreferredSize(
                                preferredSize: const Size.fromHeight(30),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  child: CustomAnimatedTextField(),
                                ),
                              ),
                      ),
                      if (_canUseTabController)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              indicator: const BoxDecoration(),
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.black54,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              tabs: tabBarTabs,
                              dividerColor: Colors.transparent,
                            ),
                          ),
                        ),
                      if (isRetry) SliverToBoxAdapter()
                    ];
                  },
                  body: _canUseTabController
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            _handleScrollNotification(notification);
                            if (notification is ScrollUpdateNotification) {
                              final metrics = notification.metrics;
                              if (metrics.pixels >=
                                  metrics.maxScrollExtent * 0.85) {
                                _loadMoreForCurrentTab(_tabController.index);
                              }
                            }
                            return false;
                          },
                          child: TabBarView(
                            key: ValueKey(_tabBarViewKey),
                            physics: NeverScrollableScrollPhysics(),
                            controller: _tabController,
                            children: tabBarViewChildren,
                          ),
                        )
                      : !isRetry
                          ? NoDeliveryLocationPage(
                              onRetry: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useRootNavigator: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 30),
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () =>
                                                Navigator.of(context).pop(),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ), 
                                      Expanded(child: LocationBottomSheet()),
                                    ],
                                  ),
                                );
                              },
                            )
                          : SizedBox.shrink(),
                );
              },
            ),
            if (isRetry) 
              Positioned.fill(
                top: 120,
                child: const Center(
                  child: CustomCircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget middleBannersWidget() {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (BuildContext context, BannerState state) {
        if (state is BannerLoaded) {
          return AutoPlayCarouselSlider(banners: state.middleBannerData);
        } else if (state is BannerLoading) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ShimmerWidget.rectangular(isBorder: true, height: 220),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildFeatureSection(FeaturedSectionData section) {
    return ProductFeatureSectionWidget(
      featureSectionData: section,
      featureSectionTitle: '',
      backgroundImage: section.mobileBackgroundImage ?? '',
      backgroundImageTablet: section.tabletBackgroundImage ?? '',
      featureSectionSlug: section.slug ?? '',
      featureSectionStyle: section.style!,
      backgroundColor: section.backgroundColor,
      backgroundType: section.backgroundType,
    );
  }

  void _loadMoreForCurrentTab(int tabIndex) {
    if (_isLoadingMoreForTab[tabIndex] == true) return;

    final featureSectionState = context.read<FeatureSectionProductBloc>().state;
    if (featureSectionState is FeatureSectionProductLoaded &&
        !featureSectionState.hasReachedMax) {
      final slug = tabIndex == 0
          ? ''
          : (tabIndex - 1 < _categories.length)
              ? _categories[tabIndex - 1].slug ?? ''
              : '';

      _isLoadingMoreForTab[tabIndex] = true;
      context
          .read<FeatureSectionProductBloc>()
          .add(FetchMoreFeatureSectionProducts(slug: slug));

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _isLoadingMoreForTab[tabIndex] = false;
        }
      });
    }
  }

  EdgeInsets _getPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    return EdgeInsets.symmetric(horizontal: horizontalPadding);
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 6;
    if (screenWidth >= 800) return 5;
    if (screenWidth >= 600) return 4;
    if (screenWidth >= 400) return 4;
    return 3;
  }

  double _getSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.04;
  }

  Widget subCategoryLoading() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: _getPadding(context).copyWith(
              top: 12.0,
              bottom: 12.0,
            ),
            child: ShimmerWidget.rectangular(
              isBorder: true,
              height: 18,
              width: 200,
              borderRadius: 15,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: _getPadding(context),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: _getSpacing(context),
              mainAxisSpacing: _getSpacing(context),
              childAspectRatio: 0.65,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return const ResponsiveSubCategoryCardShimmer();
            },
          ),
        ],
      ),
    );
  }

  void scrollToTop({bool animated = true}) {
    if (!nestedScrollController.hasClients) return;

    if (animated) {
      nestedScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      nestedScrollController.jumpTo(0.0);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    _latestScrollPixels = notification.metrics.pixels;

    final bool isScrollingUp = _latestScrollPixels < _lastScrollPixels;
    final bool shouldShowButton =
        isScrollingUp && _latestScrollPixels > _scrollThreshold;
    if (shouldShowButton != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShowButton;
      });
    }

    _lastScrollPixels = _latestScrollPixels;
    return false;
  }

  Future<void> testNotification() async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        subtitle: 'test channel',
        threadIdentifier: 'test_channel',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav');

    NotificationDetails platform =
        NotificationDetails(android: android, iOS: iosDetails);

    await FlutterLocalNotificationsPlugin().show(
      999,
      'Test Title',
      'This should play your custom sound',
      platform,
    );
  }
}
