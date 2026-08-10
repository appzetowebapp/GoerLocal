import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../model/available_orders.dart';
import '../../../../utils/currency_formatter.dart';
import '../../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../../bloc/items_collected_bloc/items_collected_state.dart';
import '../../../../l10n/app_localizations.dart';

class ItemCard extends StatelessWidget {
  final Items item;
  final String? orderStatus;
  final bool from;
  final bool isCollected;
  final bool isDelivered;
  final bool isLoading;
  final bool isOtpVerified;
  final VoidCallback? onCollect;
  final VoidCallback? onDelivered;
  final VoidCallback? onTap;
  final VoidCallback? onReachedDestination;

  const ItemCard({
    super.key,
    required this.item,
    required this.orderStatus,
    required this.from,
    required this.isCollected,
    required this.isDelivered,
    required this.isLoading,
    this.isOtpVerified = false,
    this.onCollect,
    this.onDelivered,
    this.onTap,
    this.onReachedDestination,
  });

  @override
  Widget build(BuildContext context) {
    // Check if item requires OTP
    final bool requiresOtp = item.product?.requiresOtp == 1;
    // Check if OTP dialog should open when delivered button is clicked
    final bool shouldOpenOtpDialog =
        orderStatus?.toLowerCase() == 'out_for_delivery' &&
        item.status?.toLowerCase() == 'collected' &&
        requiresOtp &&
        item.otpVerified == 0 &&
        !isOtpVerified;

    return BlocBuilder<ItemsCollectedBloc, ItemsCollectedState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: CustomCard(
            padding: EdgeInsets.all((isTablet() ? 12 : 16).w),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomImageContainer(
                      width: (isTablet() ? 44 : 50).w,
                      height: (isTablet() ? 44 : 50).h,
                      imagePath: item.product?.image ?? '',
                      backgroundColor: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8.r),
                      errorWidget: Center(
                        child: Icon(
                          Icons.shopping_bag,
                          color: Colors.blue,
                          size: sz(20, seprateTabletSize: 16).sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text:
                                      item.title ??
                                      AppLocalizations.of(context)!.unknownItem,
                                  fontSize: sz(16, seprateTabletSize: 12),
                                  fontWeight: FontWeight.w600,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text:
                              '${AppLocalizations.of(context)!.quantity}: ${item.quantity ?? 1}',
                          fontSize: sz(14, seprateTabletSize: 10),
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: CurrencyFormatter.formatAmount(
                            context,
                            item.price ?? '0',
                          ),
                          fontSize: sz(16, seprateTabletSize: 11),
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryColor,
                        ),
                      ],
                    ),

                    // Loading state
                    if (isLoading)
                      SizedBox(
                        width: (isTablet() ? 20 : 24).w,
                        height: (isTablet() ? 20 : 24).h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      )
                    // Collection mode logic
                    else if (isDelivered) ...[
                      // Show tick mark and "Delivered" text when item is delivered
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: sz(24, seprateTabletSize: 18).sp,
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.delivered,
                            fontSize: sz(12, seprateTabletSize: 9),
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (isCollected &&
                        !isDelivered &&
                        item.reachedDestination == false) ...[
                      // Show tick mark and "Collected" text when item is collected but not delivered
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: sz(24, seprateTabletSize: 18).sp,
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.collected,
                            fontSize: sz(12, seprateTabletSize: 9),
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (isDelivered &&
                        item.reachedDestination == true) ...[
                      // Show tick mark and "Delivered" text when item is delivered and has reached destination
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: sz(24, seprateTabletSize: 18).sp,
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.delivered,
                            fontSize: sz(12, seprateTabletSize: 9),
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ] else if (item.reachedDestination == true &&
                        isCollected &&
                        !isDelivered) ...[
                      // Show "Deliver" button when item has reached destination (highest priority)
                      CustomButton(
                        width: (isTablet() ? 40 : 100).w,
                        height: (isTablet() ? 36 : 40).h,
                        text: AppLocalizations.of(context)!.deliver,
                        onPressed: () {
                          // If OTP dialog should open, call onTap (which opens OTP dialog), otherwise call onDelivered
                          if (shouldOpenOtpDialog) {
                            onTap?.call();
                          } else {
                            onDelivered?.call();
                          }
                        },
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        borderRadius: 8.r,
                        padding: EdgeInsets.symmetric(
                          horizontal: (isTablet() ? 12 : 16).w,
                          vertical: (isTablet() ? 6 : 8).h,
                        ),
                        textStyle: TextStyle(
                          fontSize: sz(12, seprateTabletSize: 9).sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (orderStatus?.toLowerCase() ==
                            'out_for_delivery' &&
                        item.status?.toLowerCase() == 'collected' &&
                        !isOtpVerified) ...[
                      // Show "Deliver" button when order status is "out_for_delivery" and item status is "collected"
                      CustomButton(
                        width: (isTablet() ? 40 : 100).w,
                        height: (isTablet() ? 36 : 40).h,
                        text: AppLocalizations.of(context)!.deliver,
                        onPressed: () {
                          // If OTP dialog should open, call onTap (which opens OTP dialog), otherwise call onDelivered
                          if (shouldOpenOtpDialog) {
                            onTap?.call();
                          } else {
                            onDelivered?.call();
                          }
                        },
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        borderRadius: 8.r,
                        padding: EdgeInsets.symmetric(
                          horizontal: (isTablet() ? 12 : 16).w,
                          vertical: (isTablet() ? 6 : 8).h,
                        ),
                        textStyle: TextStyle(
                          fontSize: sz(12, seprateTabletSize: 9).sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (isCollected) ...[
                      // Show tick mark and "Collected" text when item is collected (for collection mode or assigned orders)
                      // BUT if order status is "out_for_delivery", show "Deliver" button instead
                      if (orderStatus?.toLowerCase() == 'out_for_delivery' ||
                          item.reachedDestination == true) ...[
                        // Show "Deliver" button when reached destination and item is collected
                        CustomButton(
                          width: (isTablet() ? 40 : 100).w,
                          height: (isTablet() ? 36 : 40).h,
                          text: AppLocalizations.of(context)!.deliver,
                          onPressed: () {
                            // If OTP dialog should open, call onTap (which opens OTP dialog), otherwise call onDelivered
                            if (shouldOpenOtpDialog) {
                              onTap?.call();
                            } else {
                              onDelivered?.call();
                            }
                          },
                          backgroundColor: AppColors.primaryColor,
                          textColor: Colors.white,
                          borderRadius: 8.r,
                          padding: EdgeInsets.symmetric(
                            horizontal: (isTablet() ? 12 : 16).w,
                            vertical: (isTablet() ? 6 : 8).h,
                          ),
                          textStyle: TextStyle(
                            fontSize: sz(12, seprateTabletSize: 9).sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        // Show "Collected" tickmark when item is collected but has not reached destination and not out for delivery
                        Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: sz(24, seprateTabletSize: 18).sp,
                            ),
                            SizedBox(height: 4.h),
                            CustomText(
                              text: AppLocalizations.of(context)!.collected,
                              fontSize: sz(12, seprateTabletSize: 9),
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      // Show "Collect" button when item is not collected
                      // Check if order status is "assigned" to show collect button
                      if (orderStatus?.toLowerCase() == 'assigned') ...[
                        if (isCollected) ...[
                          // Show tick mark and "Collected" text when item is collected
                          // BUT if order status is "out_for_delivery", show "Deliver" button instead
                          if (orderStatus?.toLowerCase() ==
                                  'out_for_delivery' ||
                              item.reachedDestination == true) ...[
                            // Show "Deliver" button when reached destination and item is collected
                            CustomButton(
                              width: (isTablet() ? 40 : 100).w,
                              height: (isTablet() ? 36 : 40).h,
                              text: AppLocalizations.of(context)!.deliver,
                              onPressed: () {
                                // If OTP dialog should open, call onTap (which opens OTP dialog), otherwise call onDelivered
                                if (shouldOpenOtpDialog) {
                                  onTap?.call();
                                } else {
                                  onDelivered?.call();
                                }
                              },
                              backgroundColor: AppColors.primaryColor,
                              textColor: Colors.white,
                              borderRadius: 8.r,
                              padding: EdgeInsets.symmetric(
                                horizontal: (isTablet() ? 12 : 16).w,
                                vertical: (isTablet() ? 6 : 8).h,
                              ),
                              textStyle: TextStyle(
                                fontSize: sz(12, seprateTabletSize: 9).sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            // Show tick mark and "Collected" text for other cases
                            Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: sz(24, seprateTabletSize: 18).sp,
                                ),
                                SizedBox(height: 4.h),
                                CustomText(
                                  text: 'Collected',
                                  fontSize: sz(12, seprateTabletSize: 9),
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          // Show "Collect" button when item is not collected
                          CustomButton(
                            width: (isTablet() ? 40 : 100).w,
                            height: (isTablet() ? 36 : 40).h,
                            text: AppLocalizations.of(context)!.collect,
                            onPressed:
                                (item.status?.toLowerCase() == 'preparing' ||
                                        item.status?.toLowerCase() == 'ready' ||
                                        orderStatus?.toLowerCase() ==
                                            'assigned')
                                    ? () {
                                      if (orderStatus?.toLowerCase() ==
                                          'assigned') {
                                        onCollect?.call();
                                      } else if (from) {
                                        onDelivered?.call();
                                      } else {
                                        onCollect?.call();
                                      }
                                    }
                                    : null,
                            backgroundColor:
                                (item.status?.toLowerCase() == 'preparing' ||
                                        item.status?.toLowerCase() == 'ready' ||
                                        orderStatus?.toLowerCase() ==
                                            'assigned')
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                            textColor: Colors.white,
                            borderRadius: 8.r,
                            padding: EdgeInsets.symmetric(
                              horizontal: (isTablet() ? 12 : 16).w,
                              vertical: (isTablet() ? 6 : 8).h,
                            ),
                            textStyle: TextStyle(
                              fontSize: sz(12, seprateTabletSize: 9).sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
