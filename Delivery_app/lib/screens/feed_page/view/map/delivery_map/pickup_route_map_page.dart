import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/location_service.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/map_service.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import '../../../../../config/colors.dart';
import '../../../../../config/constant.dart';
import '../../../model/available_orders.dart';
import '../../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../../bloc/order_details_bloc/order_details_event.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import 'package:go_router/go_router.dart';
import '../../../../../router/app_routes.dart';
import '../../../../../utils/widgets/toast_message.dart';

class PickupRouteMapPage extends StatefulWidget {
  final Orders order;
  final OrderDetailsBloc? bloc;

  const PickupRouteMapPage({super.key, required this.order, this.bloc});

  @override
  State<PickupRouteMapPage> createState() => _PickupRouteMapPageState();
}

class _PickupRouteMapPageState extends State<PickupRouteMapPage>
    with TickerProviderStateMixin {
  late MapController _mapController;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;
  List<LatLng> _accurateRoutePoints = [];
  StreamSubscription<LocationData>? _locationSubscription;
  double _riderRotation = 0;
  LatLng? _animatedRiderLatLng;
  AnimationController? _animationController;
  DateTime? _lastRerouteTime;
  bool _isFetchingRoute = false;

  // Manual confirmation variables
  bool _hasReachedDestination = false;
  bool _hasConfirmedArrival = false;

  // Stage indicator: 0 = heading to destination, 1 = arrived
  int get _currentStage => _hasReachedDestination ? 1 : 0;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.bloc != null) {
      final currentState = widget.bloc!.state;
      if (currentState.status == ApiStatus.success &&
          currentState.order != null) {
        final hasAnyReachedDestination =
            currentState.order!.items?.any(
              (item) => item.reachedDestination == true,
            ) ??
            false;
        if (hasAnyReachedDestination) {
          _hasReachedDestination = true;
        }
      }
    }

    // Also check the order data directly if bloc is not available
    if (widget.order.items != null) {
      final hasAnyReachedDestination = widget.order.items!.any(
        (item) => item.reachedDestination == true,
      );
      if (hasAnyReachedDestination) {
        _hasReachedDestination = true;
      }
    }

    Future.delayed(const Duration(seconds: 6), () {
      if (_isLoadingLocation) {
        _setFallbackLocation();
      }
    });

    _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await LocationService.getCurrentLocation();

      if (locationData != null) {
        if (!mounted) return;
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapToAllPoints();
          _fetchAccurateRoute();
        });
      } else {
        _setFallbackLocation();
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _checkArrivalStatus() {
    // Check if arrival has already been confirmed based on order data
    if (widget.order.items != null) {
      final hasAnyReachedDestination = widget.order.items!.any(
        (item) => item.reachedDestination == true,
      );
      if (hasAnyReachedDestination && !_hasReachedDestination) {
        setState(() {
          _hasReachedDestination = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check arrival status whenever dependencies change
    _checkArrivalStatus();
  }

  void _setFallbackLocation() {
    setState(() {
      // Use shipping address coordinates as fallback location
      double fallbackLat = 23.2488453; // Default Bhuj coordinates
      double fallbackLng = 69.6696795;

      if (widget.order.deliveryRoute?.routeDetails != null &&
          widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
        final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
        final shippingAddress =
            widget.order.deliveryRoute!.routeDetails![lastIndex];

        if (shippingAddress.latitude != null &&
            shippingAddress.longitude != null) {
          fallbackLat = shippingAddress.latitude!;
          fallbackLng = shippingAddress.longitude!;
        } else {}
      }

      _currentLocation = LocationData.fromMap({
        'latitude': fallbackLat,
        'longitude': fallbackLng,
      });
      _isLoadingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      _fetchAccurateRoute();
    });
  }

  bool _isValidLatLng(LatLng point) {
    return !point.latitude.isNaN &&
        !point.latitude.isInfinite &&
        !point.longitude.isNaN &&
        !point.longitude.isInfinite;
  }

  void _fitMapToAllPoints() {
    if (_currentLocation == null) return;

    final routePoints = MapService.generateDeliveryRoutePoints(
      _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
    );

    final List<LatLng> allPoints = List.of(routePoints);

    if (allPoints.isEmpty) {
      final currentLatLng = _getCurrentLocationLatLng();
      if (_isValidLatLng(currentLatLng)) {
        allPoints.add(currentLatLng);
      }
      final destLatLng = _getDestinationLocation();
      if (_isValidLatLng(destLatLng)) {
        allPoints.add(destLatLng);
      }
    }

    // Filter out any invalid points
    final validPoints = allPoints.where((p) => _isValidLatLng(p)).toList();

    if (validPoints.length >= 2) {
      // Check if we have at least 2 distinct points to avoid zero-size bounds
      final distinctPoints = validPoints.fold<List<LatLng>>([], (list, p) {
        if (list.isEmpty ||
            list.every(
              (existing) =>
                  (existing.latitude - p.latitude).abs() > 0.000001 ||
                  (existing.longitude - p.longitude).abs() > 0.000001,
            )) {
          list.add(p);
        }
        return list;
      });

      if (distinctPoints.length >= 2) {
        final bounds = LatLngBounds.fromPoints(distinctPoints);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      } else if (distinctPoints.isNotEmpty) {
        // Only one distinct point, just move there
        _mapController.move(distinctPoints.first, 13.0);
      }
    } else if (validPoints.isNotEmpty) {
      _mapController.move(validPoints.first, 13.0);
    }
  }

  Future<void> _fetchAccurateRoute() async {
    if (_currentLocation == null || _isFetchingRoute) return;

    _isFetchingRoute = true;
    _lastRerouteTime = DateTime.now();

    final routePoints = MapService.generateDeliveryRoutePoints(
      _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
    );

    if (routePoints.length >= 2) {
      final accuratePoints = await MapService.fetchAccurateRoute(routePoints);
      if (mounted) {
        setState(() {
          _accurateRoutePoints = accuratePoints;
        });
      }
    }
    _isFetchingRoute = false;
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getLocationStream().listen((
      locationData,
    ) {
      if (!mounted) return;

      final oldLocation = _currentLocation;
      final newLatLng = LocationService.locationDataToLatLng(locationData);

      if (oldLocation != null && newLatLng != null) {
        final oldLatLng = LatLng(oldLocation.latitude!, oldLocation.longitude!);
        _animateRider(oldLatLng, newLatLng);
      } else if (newLatLng != null) {
        setState(() {
          _animatedRiderLatLng = newLatLng;
          _currentLocation = locationData;
        });
      }

      setState(() {
        _currentLocation = locationData;

        // If the stream found location before _getCurrentLocation finished drawing, unlock instantly!
        if (_isLoadingLocation) {
          _isLoadingLocation = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapToAllPoints();
            _fetchAccurateRoute();
          });
        }
      });

      _checkReroute(locationData);
    });
  }

  void _animateRider(LatLng from, LatLng to) {
    if (from == to || !_isValidLatLng(from) || !_isValidLatLng(to)) return;

    // Calculate rotation
    final double bearing = _calculateBearing(from, to);

    final latTween = Tween<double>(begin: from.latitude, end: to.latitude);
    final lngTween = Tween<double>(begin: from.longitude, end: to.longitude);

    _animationController!.reset();
    final Animation<double> localAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    );

    localAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _animatedRiderLatLng = LatLng(
            latTween.evaluate(localAnimation),
            lngTween.evaluate(localAnimation),
          );
          _riderRotation = bearing;
        });
      }
    });

    _animationController!.forward();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lon1 = from.longitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double lon2 = to.longitude * math.pi / 180;

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    return (radians * 180 / math.pi + 360) % 360;
  }

  void _checkReroute(LocationData currentLocation) {
    if (_isFetchingRoute) return;

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < const Duration(seconds: 15)) {
      return;
    }

    final currentLatLng = LatLng(
      currentLocation.latitude!,
      currentLocation.longitude!,
    );

    // Re-fetch if we don't have a route yet, or if the user is more than 40 meters off the route
    if (_accurateRoutePoints.isEmpty ||
        MapService.isPointOffRoute(
          currentLatLng,
          _accurateRoutePoints,
          thresholdMeters: 40.0,
        )) {
      _fetchAccurateRoute();
    }
  }

  List<LatLng> _generateRoute() {
    if (_currentLocation == null) return [];

    final List<LatLng> routePoints = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
    ];

    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      // Add destination location (usually the last detail in delivery route)
      final destLocation = widget.order.deliveryRoute!.routeDetails!.last;

      if (destLocation.latitude != null && destLocation.longitude != null) {
        final destPoint = LatLng(
          destLocation.latitude!,
          destLocation.longitude!,
        );

        if (_isValidLatLng(destPoint)) {
          // In stage 0, we show the route to the destination
          if (_currentStage == 0) {
            routePoints.add(destPoint);
          }
        }
      }
    } else {}

    return routePoints;
  }

  LatLng _getDestinationLocation() {
    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
      final destination = widget.order.deliveryRoute!.routeDetails![lastIndex];
      if (destination.latitude != null && destination.longitude != null) {
        return LatLng(destination.latitude!, destination.longitude!);
      }
    }

    final lat = double.tryParse(widget.order.shippingLatitude ?? '');
    final lng = double.tryParse(widget.order.shippingLongitude ?? '');
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    return const LatLng(23.2488453, 69.6696795);
  }

  // Calculate distance from current location to stores (excluding shipping address)
  double _calculateDistanceToStores() {
    if (_currentLocation == null) {
      return 0.0;
    }

    double totalDistanceToStores = 0.0;

    if (widget.order.deliveryRoute?.routeDetails != null) {
      final routeDetails = widget.order.deliveryRoute!.routeDetails!;

      // Exclude the last index (shipping address) - only include stores
      for (int i = 0; i < routeDetails.length - 1; i++) {
        final store = routeDetails[i];

        if (store.latitude != null && store.longitude != null) {
          final storePoint = LatLng(store.latitude!, store.longitude!);
          final currentPoint = _getCurrentLocationLatLng();

          if (_isValidLatLng(currentPoint) && _isValidLatLng(storePoint)) {
            totalDistanceToStores += MapService.calculateDistance(
              currentPoint,
              storePoint,
            );
          }
        }
      }
    }

    return totalDistanceToStores;
  }

  LatLng _getCurrentLocationLatLng() {
    if (_currentLocation != null &&
        _currentLocation!.latitude != null &&
        _currentLocation!.longitude != null &&
        !_currentLocation!.latitude!.isNaN &&
        !_currentLocation!.latitude!.isInfinite &&
        !_currentLocation!.longitude!.isNaN &&
        !_currentLocation!.longitude!.isInfinite) {
      return LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    }

    // Use shipping address coordinates as fallback
    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
      final shippingAddress =
          widget.order.deliveryRoute!.routeDetails![lastIndex];

      if (shippingAddress.latitude != null &&
          shippingAddress.longitude != null &&
          !shippingAddress.latitude!.isNaN &&
          !shippingAddress.latitude!.isInfinite &&
          !shippingAddress.longitude!.isNaN &&
          !shippingAddress.longitude!.isInfinite) {
        return LatLng(shippingAddress.latitude!, shippingAddress.longitude!);
      }
    }

    // Secondary fallback to shipping coordinates from order properties
    final orderLat = double.tryParse(widget.order.shippingLatitude ?? '');
    final orderLng = double.tryParse(widget.order.shippingLongitude ?? '');
    if (orderLat != null &&
        orderLng != null &&
        !orderLat.isNaN &&
        !orderLat.isInfinite &&
        !orderLng.isNaN &&
        !orderLng.isInfinite) {
      return LatLng(orderLat, orderLng);
    }

    // Final fallback to default Bhuj coordinates
    return const LatLng(23.2488453, 69.6696795);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _animationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _showArrivalConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8.w),
              CustomText(
                text: AppLocalizations.of(context)!.confirmArrival,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          content: CustomText(
            text: AppLocalizations.of(context)!.haveYouReachedAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: CustomText(text: AppLocalizations.of(context)!.cancel),
            ),
            CustomButton(
              text: AppLocalizations.of(context)!.yesImHere,
              onPressed: () {
                context.pop();
                setState(() {
                  _hasConfirmedArrival = true;
                  _hasReachedDestination =
                      true; // Set this to true to show "Arrival Confirmed"
                });

                // Mark ALL items as reached destination using the bloc from widget
                if (widget.order.items != null &&
                    widget.order.items!.isNotEmpty &&
                    widget.bloc != null) {
                  for (final item in widget.order.items!) {
                    if (item.id != null) {
                      widget.bloc!.add(
                        MarkItemReachedDestination(widget.order.id!, item.id!),
                      );
                    }
                  }
                } else {
                  //
                }

                // Show success message
                ToastManager.show(
                  context: context,
                  message: 'Arrival confirmed! You can now view order details.',
                  type: ToastType.success,
                );

                // Automatically navigate to order details page after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (!context.mounted) return;
                  if (mounted) {
                    context.pushNamed(
                      'orderDetails',
                      extra: {
                        'orderId': widget.order.id,
                        'from':
                            false, // Using false instead of string as expected by the route
                      },
                    );
                  }
                });
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    // Convert animated location back to LocationData format for the service
    LocationData? animatedLocation;
    if (_animatedRiderLatLng != null) {
      animatedLocation = LocationData.fromMap({
        'latitude': _animatedRiderLatLng!.latitude,
        'longitude': _animatedRiderLatLng!.longitude,
      });
    }

    return MapService.buildDeliveryMarkers(
      animatedLocation ?? _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
      rotation: _riderRotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.order.items != null) {
    //   final reachedDestinationItems =
    //       widget.order.items!
    //           .where((item) => item.reachedDestination == true)
    //           .length;
    //
    //   // Check if View Details button should be shown
    //   final shouldShowViewDetails =
    //       _hasReachedDestination || _hasConfirmedArrival;
    // }

    if (widget.order.deliveryRoute?.routeDetails != null) {
      for (
        int i = 0;
        i < widget.order.deliveryRoute!.routeDetails!.length;
        i++
      ) {
        // final store = widget.order.deliveryRoute!.routeDetails![i];
      }
    }

    return CustomScaffold(
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.deliveryRoute,

        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  (() {
                    final center =
                        _currentLocation != null
                            ? _getCurrentLocationLatLng()
                            : const LatLng(23.2530, 69.6693);
                    return _isValidLatLng(center)
                        ? center
                        : const LatLng(23.2530, 69.6693);
                  })(),
              initialZoom: 13.0,
              onMapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_currentLocation != null) _fitMapToAllPoints();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/'
                    'World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: packageName,
                maxZoom: 19,
                minZoom: 0.0,
              ),
              if (_currentLocation != null) ...[
                Column(
                  children: [
                    Text(
                      (_accurateRoutePoints.isEmpty
                              ? "Okay Got it"
                              : _accurateRoutePoints.first)
                          .toString(),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          _accurateRoutePoints.isNotEmpty
                              ? _accurateRoutePoints
                              : _generateRoute(),
                      strokeWidth: 3.sp,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ],
          ),
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: AppLocalizations.of(context)!.loadingMap,
                      fontSize: sz(16, seprateTabletSize: 12),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.straighten,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  CustomText(
                    text:
                        '${_calculateDistanceToStores().toStringAsFixed(1)} km',
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
                minHeight: 150.h,
              ),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color:
                    context.isDarkMode ? AppColors.cardDarkColor : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15.r,
                    offset: Offset(0, 5.h),
                    spreadRadius: 2.r,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                            ),
                            SizedBox(width: 7.w),
                            CustomText(
                              text: AppLocalizations.of(context)!.deliveryRoute,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.oppColorChange,
                            ),
                          ],
                        ),

                        if (!_hasReachedDestination || !_hasConfirmedArrival)
                          CustomText(
                            text:
                                '${_calculateDistanceToStores().toStringAsFixed(1)} km',
                            fontSize: sz(12, seprateTabletSize: 10),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        if (_hasReachedDestination || _hasConfirmedArrival)
                          SizedBox(
                            width: 110.w,
                            child: CustomButton(
                              text: AppLocalizations.of(context)!.viewDetails,
                              borderRadius: 12.r,
                              backgroundColor: AppColors.primaryColor,
                              textColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              onPressed: () {
                                context.push(
                                  AppRoutes.orderDetails,
                                  extra: {
                                    'orderId': widget.order.id!,
                                    'from': true,
                                    'sourceTab':
                                        1, // 1 = My Orders tab (since this is from accepted orders)
                                    'arrivalConfirmed':
                                        _hasReachedDestination ||
                                        _hasConfirmedArrival, // Pass arrival status
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Shipping Address Section
                  SizedBox(height: 12.h),

                  if (widget.order.shippingAddress1 != null)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              text: widget.order.shippingAddress1!,
                              fontSize: sz(12, seprateTabletSize: 11),
                              fontWeight: FontWeight.w500,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 8.h),

                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text:
                          _hasReachedDestination
                              ? AppLocalizations.of(context)!.arrivalConfirmed
                              : AppLocalizations.of(context)!.confirmArrival,
                      onPressed:
                          _hasReachedDestination
                              ? null
                              : _showArrivalConfirmationDialog,
                      icon: Icon(
                        _hasReachedDestination
                            ? Icons.check_circle
                            : Icons.location_on,
                        color:
                            _hasReachedDestination
                                ? Colors.green
                                : Colors.white,
                      ),
                      backgroundColor:
                          _hasReachedDestination
                              ? Colors.grey.shade200
                              : AppColors.primaryColor,
                      textColor:
                          _hasReachedDestination ? Colors.green : Colors.white,
                      borderRadius: 8.r,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      textStyle: TextStyle(
                        color:
                            _hasReachedDestination
                                ? Colors.green
                                : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  final currentLocation = _getCurrentLocationLatLng();
                  final currentLat = currentLocation.latitude.toString();
                  final currentLng = currentLocation.longitude.toString();

                  // String destinationLat = '0', destinationLng = '0';

                  // Use shipping address coordinates for navigation (final destination)
                  if (widget.order.shippingLatitude != null &&
                      widget.order.shippingLongitude != null) {
                    // destinationLat = widget.order.shippingLatitude!;
                    // destinationLng = widget.order.shippingLongitude!;
                  } else if (widget.order.deliveryRoute?.routeDetails != null &&
                      widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
                    // Fallback to last item in route_details (shipping address)
                    final lastIndex =
                        widget.order.deliveryRoute!.routeDetails!.length - 1;
                    final shippingAddress =
                        widget.order.deliveryRoute!.routeDetails![lastIndex];
                    if (shippingAddress.latitude != null &&
                        shippingAddress.longitude != null) {
                      // destinationLat = shippingAddress.latitude!.toString();
                      // destinationLng =
                      //     shippingAddress.longitude!.toString();
                    }
                  }

                  // For PickupRouteMapPage: Only navigate to shipping address (no store addresses)
                  String destinationAddress =
                      'Bhuj, Gujarat, India'; // Default fallback

                  // Use shipping address directly (this is a pickup route to seller)
                  if (widget.order.shippingAddress1 != null) {
                    destinationAddress = widget.order.shippingAddress1!;
                    if (widget.order.shippingAddress2 != null) {
                      destinationAddress +=
                          ', ${widget.order.shippingAddress2}';
                    }
                  } else if (widget.order.deliveryRoute?.routeDetails != null &&
                      widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
                    // Fallback to last item in route_details (shipping address)
                    final lastIndex =
                        widget.order.deliveryRoute!.routeDetails!.length - 1;
                    final shippingAddress =
                        widget.order.deliveryRoute!.routeDetails![lastIndex];
                    if (shippingAddress.address != null &&
                        shippingAddress.address!.isNotEmpty) {
                      destinationAddress = shippingAddress.address!;
                    }
                  }

                  // Build Google Maps URL: Current location to shipping address only
                  final googleMapsUrl =
                      'https://www.google.com/maps/dir/?api=1'
                      '&origin=${Uri.encodeComponent('$currentLat,$currentLng')}'
                      '&destination=${Uri.encodeComponent(destinationAddress)}'
                      '&travelmode=driving';

                  final url = Uri.parse(googleMapsUrl);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (!context.mounted) return;
                  ToastManager.show(
                    context: context,
                    message: 'Could not open navigation: $e',
                    type: ToastType.error,
                  );
                }
              },
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.navigation),
            ),
          ),
        ],
      ),
    );
  }
}
