import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../config/app_images.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../bloc/accept_order_bloc/accept_order_bloc.dart';
import '../../bloc/accept_order_bloc/accept_order_event.dart';
import '../../bloc/accept_order_bloc/accept_order_state.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../model/available_orders.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../../utils/currency_formatter.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class AvailableOrderCard extends StatelessWidget {
  final Orders order;

  const AvailableOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AcceptOrderBloc(),
      child: _AvailableOrderCardContent(order: order),
    );
  }
}

class _AvailableOrderCardContent extends StatelessWidget {
  final Orders order;

  const _AvailableOrderCardContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with earnings and distance - More compact
            Container(
              padding: EdgeInsets.all(10.w), // Reduced from 12.w to 10.w
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expected earning - More compact
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text:
                            "${AppLocalizations.of(context)!.orderId} ${order.id}",
                        fontSize: 11, // Reduced from 12.sp to 11.sp
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 2.h), // Reduced from 2.h to 2.h

                      CustomText(
                        text: AppLocalizations.of(context)!.expectedEarning,
                        fontSize: sz(11), // Reduced from 12.sp to 11.sp
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 2.h), // Reduced from 2.h to 2.h
                      CustomText(
                        text: CurrencyFormatter.formatAmount(
                          context,
                          order.earnings?.total ?? '0',
                        ),
                        fontSize: sz(
                          18,
                          seprateTabletSize: 15,
                        ), // Reduced from 20.sp to 18.sp
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryColor,
                      ),
                    ],
                  ),
                  // Distance - More compact
                  if (order.deliveryRoute?.totalDistance != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomText(
                            text: AppLocalizations.of(context)!.drop,
                            fontSize: sz(10), // Reduced from 12.sp to 10.sp
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          SizedBox(height: 1.h), // Reduced from 2.h to 1.h
                          CustomText(
                            text:
                                '${order.deliveryRoute!.totalDistance!.toStringAsFixed(1)} ${AppLocalizations.of(context)!.km}',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Pickup section - More compact
            Padding(
              padding: EdgeInsets.all(10.w), // Reduced from 12.w to 10.w
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PICKUP FROM header with map button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14.sp, // Added location icon
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 4.w),
                          CustomText(
                            text: AppLocalizations.of(context)!.pickupFrom,
                            fontSize: sz(
                              10,
                              seprateTabletSize: 12,
                            ), // Reduced from 11.sp to 10.sp
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      if (order.deliveryRoute?.routeDetails != null &&
                          order.deliveryRoute!.routeDetails!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showRouteOnMap(context, order),
                          child: Container(
                            padding: EdgeInsets.all(
                              4.w,
                            ), // Reduced from 5.w to 4.w
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .oppColorChange
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(
                                6.r,
                              ), // Reduced from 5.r to 6.r
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .sameColorChange
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.map,
                              size: 12.sp, // Reduced from 14.sp to 12.sp
                              color:
                                  Theme.of(context).colorScheme.oppColorChange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h), // Reduced from 8.h to 6.h
                  // Store info row - More compact
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store logo - Smaller
                      Container(
                        width: 28.w, // Reduced from 32.w to 28.w
                        height: 28.h, // Reduced from 32.h to 28.h
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            6.r,
                          ), // Reduced from 6.r to 6.r
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 4.r,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomText(
                            text: _getStoreInitials(order, context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w), // Reduced from 10.w to 8.w
                      // Store details - More compact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store name
                            CustomText(
                              text:
                                  order
                                      .deliveryRoute
                                      ?.routeDetails
                                      ?.first
                                      .storeName ??
                                  AppLocalizations.of(context)!.store,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(height: 2.h), // Reduced from 2.h to 2.h
                            // Store address - Truncated for compactness
                            if (order.shippingAddress1 != null)
                              CustomText(
                                text:
                                    '${order.shippingAddress1}${order.shippingAddress2 != null ? ', ${order.shippingAddress2}' : ''}',
                                fontSize: sz(11), // Reduced from 12.sp to 11.sp
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 4.h), // Reduced from 6.h to 4.h
                            // Time estimate with icon
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 10.sp, // Reduced from 12.sp to 10.sp
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                SizedBox(width: 2.w), // Reduced from 3.w to 2.w
                                CustomText(
                                  text: AppLocalizations.of(context)!.minsAway(
                                    ((order.deliveryRoute?.totalDistance ?? 0) *
                                            2)
                                        .toString(),
                                  ),
                                  fontSize: sz(
                                    10,
                                  ), // Reduced from 11.sp to 10.sp
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Accept button section - Keep swiper button unchanged
            SizedBox(
              width: double.infinity,
              height: 45.h,
              child: BlocConsumer<AcceptOrderBloc, AcceptOrderState>(
                listener: (context, state) {
                  if (state.status == ApiStatus.success) {
                    // Navigate to map delivery page on success
                    _navigateToMapDeliveryPage(context, order);
                    // Refresh the available orders list when order is completed
                    context.read<AvailableOrdersBloc>().add(
                      AllAvailableOrdersList(forceRefresh: true),
                    );
                  } else if (state.status == ApiStatus.failed) {
                    // Show error message if needed (toast is already handled by repository/helper if applicable,
                    // but here we can add custom handling if required)
                  }
                },
                builder: (context, state) {
                  final isLoading = state.status == ApiStatus.loading;

                  return SwipeButton(
                    thumbPadding: EdgeInsets.all(4.w),
                    borderRadius: BorderRadius.circular(22.r),
                    inactiveThumbColor: Colors.white,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryColor,
                    inactiveTrackColor: AppColors.primaryColor.withValues(
                      alpha: 0.8,
                    ),
                    width: double.infinity,
                    height: 45.h,
                    thumb: Container(
                      width: 40.w,
                      height: 35.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17.r),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1.w,
                        ),
                      ),
                      child: Center(
                        child:
                            isLoading
                                ? LoadingWidget(size: 25.w)
                                : Image.asset(
                                  AppImages.arrowRight,
                                  width: 25.w,
                                  height: 25.h,
                                ),
                      ),
                    ),
                    onSwipe: () async {
                      if (!isLoading) {
                        // Dispatch AcceptOrder event to the bloc
                        context.read<AcceptOrderBloc>().add(
                          AcceptOrder(order.id!),
                        );
                      }
                    },
                    child: CustomText(
                      text:
                          isLoading
                              ? AppLocalizations.of(context)!.accepting
                              : AppLocalizations.of(context)!.acceptOrder,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStoreInitials(Orders order, BuildContext context) {
    final storeName =
        order.deliveryRoute?.routeDetails?.first.storeName ??
        AppLocalizations.of(context)!.store;
    if (storeName.isEmpty || storeName == AppLocalizations.of(context)!.store) {
      return 'S';
    }

    final words = storeName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  // Navigation method for map delivery page
  Future<void> _navigateToMapDeliveryPage(
    BuildContext context,
    Orders order,
  ) async {
    // Check for store pickup coordinates first, then fallback to delivery coordinates
    bool hasValidCoordinates = false;
    String? destinationLat;
    String? destinationLng;

    if (order.deliveryRoute?.routeDetails != null &&
        order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final storeLocation = order.deliveryRoute!.routeDetails!.first;
      hasValidCoordinates =
          storeLocation.latitude != null && storeLocation.longitude != null;
      if (hasValidCoordinates) {
        destinationLat = storeLocation.latitude.toString();
        destinationLng = storeLocation.longitude.toString();
      }
    }

    // If no store coordinates, try delivery coordinates
    if (!hasValidCoordinates) {
      hasValidCoordinates =
          order.shippingLatitude != null && order.shippingLongitude != null;
      if (hasValidCoordinates) {
        destinationLat = order.shippingLatitude.toString();
        destinationLng = order.shippingLongitude.toString();
      }
    }

    if (hasValidCoordinates &&
        destinationLat != null &&
        destinationLng != null) {
      try {
        // Navigate to map delivery page
        context.push(
          AppRoutes.mapDelivery,
          extra: {
            'order': order,
            'currentLat': destinationLat,
            'currentLng': destinationLng,
          },
        );
      } catch (e) {
        ToastManager.show(
          context: context,
          message: AppLocalizations.of(context)!.navigationError(e.toString()),
          type: ToastType.error,
        );
      }
    } else {
      ToastManager.show(
        context: context,
        message:
            AppLocalizations.of(context)!.storePickupCoordinatesNotAvailable,
        type: ToastType.error,
      );
    }
  }

  // Method to show route on map
  void _showRouteOnMap(BuildContext context, Orders order) {
    if (order.deliveryRoute?.routeDetails != null &&
        order.deliveryRoute!.routeDetails!.isNotEmpty) {
      try {
        // Navigate to pickup route map page
        context.push(
          AppRoutes.pickupRouteMap,
          extra: {
            'order': order,
            // Note: bloc parameter is optional, so we don't need to pass it
          },
        );
      } catch (e) {
        ToastManager.show(
          context: context,
          message: AppLocalizations.of(context)!.navigationError(e.toString()),
          type: ToastType.error,
        );
      }
    } else {
      ToastManager.show(
        context: context,
        message:
            AppLocalizations.of(context)!.routeDetailsNotAvailableForMapView,
        type: ToastType.error,
      );
    }
  }
}
