import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_image_container.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../settings/bloc/profile_bloc/profile_bloc.dart';
import '../../../settings/bloc/profile_bloc/profile_state.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';

import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';

class HomeHeaderSection extends StatefulWidget {
  final Function() handleToggle;

  const HomeHeaderSection({super.key, required this.handleToggle});

  @override
  State<HomeHeaderSection> createState() => _HomeHeaderSectionState();
}

class _HomeHeaderSectionState extends State<HomeHeaderSection> {
  void _showDeliveryZoneErrorDialog(BuildContext context, String errorMessage) {
    final statusBloc = context.read<DeliveryBoyStatusBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8.w),
              CustomText(text: AppLocalizations.of(dialogContext)!.locationIssue),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: errorMessage),
              SizedBox(height: 16.h),
              CustomText(
                text: AppLocalizations.of(dialogContext)!.toResolveThisIssue,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text:
                    AppLocalizations.of(
                      dialogContext,
                    )!.moveToCoveredDeliveryArea,
              ),
              CustomText(
                text:
                    AppLocalizations.of(
                      dialogContext,
                    )!.checkDeliveryZoneInProfile,
              ),
              CustomText(
                text:
                    AppLocalizations.of(
                      dialogContext,
                    )!.ensureGpsEnabledAccurate,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: CustomText(text: AppLocalizations.of(dialogContext)!.ok),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to delivery zone page
                context.push('/delivery-zone');
              },
              child: CustomText(
                text: AppLocalizations.of(dialogContext)!.viewDeliveryZone,
              ),
            ),
            CustomButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Retry getting location
                statusBloc.add(const ToggleStatus(true));
              },
              text: AppLocalizations.of(dialogContext)!.retry,
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // context.read<NotificationBloc>().add(FetchNotifications());
    // context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      listener: (context, state) {
        if (state.status == ApiStatus.success) {
          if (state.message.isNotEmpty && state.isVerified) {
            ToastManager.show(context: context, message: state.message, type: ToastType.success);
          }
        } else if (state.status == ApiStatus.failed) {
          // Show toast for general errors
          ToastManager.show(context: context, message: state.message, type: ToastType.error);

          // Show detailed dialog for delivery zone errors
          if (state.message.contains('delivery zone')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDeliveryZoneErrorDialog(context, state.message);
            });
          }
        }
      },
      child: BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
        builder: (context, state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedToggleSwitch<bool>.dual(
                indicatorSize: isTablet() ? const Size(40, 40) : const Size(28, 28),
                current: state.isOnline,
                loading: state.status == ApiStatus.loading,
                first: false,
                second: true,
                spacing: (isTablet() ? 60 : 85).w,
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 300), // Reduced from 600ms for faster response
                borderWidth: 6.w,
                height: (isTablet() ? 40 : 38).h,
                styleBuilder:
                    (value) => ToggleStyle(
                      backgroundColor: value ? AppColors.primaryColor : AppColors.errorColor,
                      borderColor: Colors.transparent,
                      indicatorColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                loadingIconBuilder:
                    (context, global) => CupertinoActivityIndicator(
                      color: Color.lerp(AppColors.errorColor, AppColors.primaryColor, global.position),
                    ),
                onChanged: (b) {
                  widget.handleToggle();
                },
                iconBuilder:
                    (value) =>
                        value
                            ? Icon(
                              Icons.lightbulb_outline_rounded,
                              color: AppColors.primaryColor,
                              size: (isTablet() ? 12 : 24).sp,
                            )
                            : Icon(
                              Icons.power_settings_new_rounded,
                              color: AppColors.errorColor,
                              size: (isTablet() ? 12 : 24).sp,
                            ),
                textBuilder:
                    (value) =>
                        value
                            ? CustomText(
                              text: AppLocalizations.of(context)!.active,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              textAlign: TextAlign.center,
                            )
                            : CustomText(
                              text: AppLocalizations.of(context)!.inactive,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              textAlign: TextAlign.center,
                            ),
              ),

              Expanded(
                child: Row(
                  spacing: isTablet() ? 15 : 5,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, notificationState) {
                        int unreadCount = 0;

                        if (notificationState.fetchStatus == ApiStatus.success) {
                          unreadCount = notificationState.unreadCount;
                        }
                        return GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.notifications);
                          },
                          child: Badge.count(
                            count: unreadCount,
                            isLabelVisible: unreadCount > 0, // hide badge when 0
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),

                            offset: const Offset(-1, -5), // fine-tune position

                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                              ),
                              padding: isTablet() ? const EdgeInsets.all(11) : const EdgeInsets.all(8),

                              child: Icon(
                                Icons.notifications,
                                size: (isTablet() ? 12 : 20).sp,
                                color: AppColors.primaryColor,
                              ),
                            ),

                            // IconButton(
                            //   padding: isTablet() ? const EdgeInsets.all(11) : null,
                            //   color: AppColors.primaryColor,
                            //   style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1)),
                            //   icon: Icon(Ionicons.notifications, size: (isTablet() ? 12 : 20).sp),
                            //   onPressed: () {},
                            // ),
                          ),
                        );
                      },
                    ),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, profileState) {
                        String profileImageUrl = "assets/png/profile.jpg";

                        if (profileState.fetchStatus == ApiStatus.success &&
                            profileState.profile?.user?.profileImage != null &&
                            profileState.profile!.user!.profileImage!.isNotEmpty) {
                          profileImageUrl = profileState.profile!.user!.profileImage!;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (!state.isVerified) {
                              ToastManager.show(
                                context: context,
                                message: state.message ?? "Your account has not been verified yet.",
                                type: ToastType.error,
                              );
                              return;
                            }
                            context.push(AppRoutes.profile);
                          },
                          child: Opacity(
                            opacity: state.isVerified ? 1.0 : 0.5,
                            child: CustomAvatar(
                              radius: (isTablet() ? 16 : 18).r,
                              backgroundColor: AppColors.primaryColor,
                              imageUrl: profileImageUrl.startsWith('http') ? profileImageUrl : null,
                              fallbackIcon: Icon(Icons.person, size: (isTablet() ? 12 : 20).sp, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
