// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/location_tracker.dart';
import 'package:hyper_local/config/theme/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../config/colors.dart';
import '../../../config/theme/theme_bloc/theme_event.dart';
import '../../../utils/widgets/custom_image_container.dart';
import '../../system_settings/bloc/system_settings_state.dart';
import '../bloc/profile_bloc/profile_bloc.dart';
import '../bloc/profile_bloc/profile_event.dart';
import '../bloc/profile_bloc/profile_state.dart';
import 'package:hyper_local/config/localization_bloc/localization_bloc.dart';
import 'package:hyper_local/config/localization_bloc/localization_event.dart';
import 'package:hyper_local/config/localization_bloc/localization_state.dart';
import '../../../utils/widgets/toast_message.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    // Load profile data
    try {
      context.read<ProfileBloc>().add(const LoadProfile());
    } catch (e) {
      //
    }
  }

  Future<void> _initializeStatus() async {
    final status = await Global.getDeliveryBoyStatus() ?? false;
    setState(() {
      _isActive = status;
    });
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      radius: 35.r,
      child: Icon(Icons.person, size: 35.r, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
          listener: (context, state) {
            if (state.status == ApiStatus.success) {
              setState(() {
                _isActive = state.isOnline;
              });
            }
          },
        ),

        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) async {
            if (state.deleteApiStatus == ApiStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
            }

            if (state.deleteApiStatus == ApiStatus.success) {
              Navigator.of(context, rootNavigator: true).pop();
              ToastManager.show(
                context: context,
                message: state.message.isNotEmpty ? state.message : "Account Deleted Successfully",
                type: ToastType.success,
              );
              LocationTracker().stopTracking();
              await Global.setDeliveryBoyStatus(false);
              await Global.clearDeliveryBoyStatus();
              await Global.clearUserToken();
              await Global.clearIdToken();
              GoRouter.of(context).go(AppRoutes.login);
            } else if (state.deleteApiStatus == ApiStatus.failed) {
              Navigator.of(context, rootNavigator: true).pop();
              ToastManager.show(
                context: context,
                message: state.message.isNotEmpty ? state.message : "Delete failed",
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: CustomScaffold(
        appBar: CustomAppBarWithoutNavbar(
          onBackPressed: () {
            context.go(AppRoutes.feed);
          },
          title: AppLocalizations.of(context)!.settings,
          additionalActions: const [],
        ),
        body:
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      if (state.fetchStatus == ApiStatus.success && state.profile != null) {
                        final profile = state.profile!;
                        final String profileName =
                            profile.deliveryBoy?.fullName ??
                            profile.user?.name ??
                            AppLocalizations.of(context)!.deliveryPartner;
                        final String profileEmail = profile.user?.email ?? '';
                        final String? profileImageUrl = profile.user?.profileImage;

                        return CustomCard(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Row(
                            children: [
                              CustomAvatar(imageUrl: profileImageUrl ?? "", radius: 35.r),

                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: profileName,
                                      fontSize: sz(16, seprateTabletSize: 12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    if (profileEmail.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      CustomText(
                                        text: profileEmail,
                                        fontSize: sz(12, seprateTabletSize: 9),
                                        color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ],
                                    SizedBox(height: 8.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color:
                                            _isActive
                                                ? Colors.green.withValues(alpha: 0.15)
                                                : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20.r),
                                        border: Border.all(
                                          color: (_isActive ? Colors.green : Colors.grey).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6.w,
                                            height: 6.w,
                                            decoration: BoxDecoration(
                                              color: _isActive ? Colors.green : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          CustomText(
                                            fontSize: sz(10, seprateTabletSize: 6),
                                            text:
                                                _isActive
                                                    ? AppLocalizations.of(context)!.active
                                                    : AppLocalizations.of(context)!.inactive,
                                            fontWeight: FontWeight.w600,
                                            color: _isActive ? Colors.green[700] : Colors.grey[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey, size: (isTablet() ? 12 : 20).sp),
                            ],
                          ),
                        );
                      } else if (state.fetchStatus == ApiStatus.loading) {
                        return CustomCard(
                          child: Row(
                            children: [
                              CircleAvatar(radius: 35.r, backgroundColor: Colors.grey[200]),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 120.w, height: 16.h, color: Colors.grey[200]),
                                  SizedBox(height: 8.h),
                                  Container(width: 80.w, height: 12.h, color: Colors.grey[200]),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Account Settings Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.accountSettings,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.person,
                        title: AppLocalizations.of(context)!.myOrders,
                        subtitle: 'View and manage your delivery orders',
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.myOrders),
                        showDivider: false,
                      ),
                      _buildSettingsOption(
                        icon: Icons.money,
                        title: AppLocalizations.of(context)!.cashCollected,
                        subtitle: AppLocalizations.of(context)!.manageProfileInformation,
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.allCashCollection),
                        showDivider: false,
                      ),
                      _buildSettingsOption(
                        icon: Icons.wallet,
                        title: AppLocalizations.of(context)!.withdrawalHistory,
                        subtitle: AppLocalizations.of(context)!.manageProfileInformation,
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.withdrawalHistory),
                        showDivider: false,
                      ),
                      _buildSettingsOption(
                        icon: Icons.star,
                        title: AppLocalizations.of(context)!.feedback,
                        subtitle: AppLocalizations.of(context)!.manageProfileInformation,
                        isDarkTheme: isDarkTheme,
                        onTap: () => context.push(AppRoutes.ratings),
                        showDivider: false,
                      ),
                      BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
                        builder: (context, state) {
                          final bool isVisible = state.settings?.referStatus ?? false;
                          return _buildSettingsOption(
                            isVisible: isVisible,
                            icon: TablerIcons.moneybag,
                            title: AppLocalizations.of(context)!.referAndEarn,
                            subtitle: AppLocalizations.of(context)!.referAndEarn,
                            isDarkTheme: isDarkTheme,
                            onTap: () => context.push(AppRoutes.referAndEarn),
                            showDivider: false,
                          );
                        },
                      ),
                    ],
                  ),

                  // App Settings Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.appSettings,
                    children: [
                      // _buildSettingsOption(
                      //   icon: Icons.notifications,
                      //   title: AppLocalizations.of(context)!.notifications,
                      //   subtitle:
                      //       AppLocalizations.of(
                      //         context,
                      //       )!.manageNotificationPreferences,
                      //   isDarkTheme: isDarkTheme,
                      //   onTap: () => context.push(AppRoutes.notifications),
                      // ),
                      _buildSettingsOption(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        subtitle: AppLocalizations.of(context)!.changeAppLanguage,
                        isDarkTheme: isDarkTheme,
                        onTap: () => _showLanguageSelectionDialog(context, isDarkTheme),
                      ),
                      _buildSettingsOptionWithSwitch(
                        icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                        title: AppLocalizations.of(context)!.darkTheme,
                        subtitle:
                            isDarkTheme
                                ? AppLocalizations.of(context)!.darkMode
                                : AppLocalizations.of(context)!.lightMode,
                        isDarkTheme: isDarkTheme,
                        value: isDarkTheme,
                        onChanged: (value) {
                          context.read<ThemeBloc>().add(SetTheme(value ? 'dark' : 'light'));
                        },
                        showDivider: false,
                      ),
                    ],
                  ),

                  // Support & Help Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.supportAndHelp,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.description,
                        title: AppLocalizations.of(context)!.termsOfService,
                        subtitle: AppLocalizations.of(context)!.readTermsAndConditions,
                        isDarkTheme: isDarkTheme,
                        onTap: () {
                          // Navigate to terms of service
                          context.push(AppRoutes.terms);
                        },
                      ),
                      _buildSettingsOption(
                        icon: Icons.privacy_tip,
                        title: AppLocalizations.of(context)!.privacyPolicy,
                        subtitle: AppLocalizations.of(context)!.readPrivacyPolicy,
                        isDarkTheme: isDarkTheme,
                        onTap: () {
                          // Navigate to privacy policy
                          context.push(AppRoutes.privacy);
                        },
                      ),
                    ],
                  ),

                  // Account Actions Section
                  _buildSectionCard(
                    title: AppLocalizations.of(context)!.accountActions,
                    children: [
                      _buildSettingsOption(
                        icon: Icons.logout,
                        title: AppLocalizations.of(context)!.logout,
                        subtitle: AppLocalizations.of(context)!.signOutOfAccount,
                        isDarkTheme: isDarkTheme,
                        onTap: () => _showLogoutDialog(context, isDarkTheme),
                        isDestructive: true,
                        showDivider: false,
                      ),

                      _buildSettingsOption(
                        icon: Icons.no_accounts,
                        title: AppLocalizations.of(context)!.deleteAccount,
                        subtitle: AppLocalizations.of(context)!.deleteAccountDesc,
                        isDarkTheme: isDarkTheme,
                        onTap: () => _showDeleteDialog(context, isDarkTheme),
                        isDestructive: true,
                        showDivider: false,
                      ),
                    ],
                  ),

                  // SizedBox(height: 10.h),
                ],
              ),
            ).fadeAndSlideAnimation(),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 2.w),
              padding: EdgeInsets.all(12.w),
              child: CustomText(text: title, fontWeight: FontWeight.bold),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkTheme,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
    bool isVisible = true,
  }) {
    return isVisible
        ? Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all((isTablet() ? 7 : 12).w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          icon,
                          color: isDestructive ? Colors.red : (isDarkTheme ? Colors.white : Colors.black),
                          size: (isTablet() ? 12 : 20).sp,
                        ),
                      ),
                      SizedBox(width: (isTablet() ? 10 : 16).w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: title,
                              fontWeight: FontWeight.w600,
                              color: isDestructive ? Colors.red : (isDarkTheme ? Colors.white : Colors.black),
                            ),
                            // SizedBox(height: 4.h),
                            // CustomText(
                            //   text: subtitle,
                            //   fontSize: 14.sp,
                            //   color: isDarkTheme ? Colors.grey : Colors.grey.shade600,
                            // ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: (isTablet() ? 12 : 20).sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
        : const SizedBox.shrink();
  }

  Widget _buildSettingsOptionWithSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkTheme,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all((isTablet() ? 7 : 12).w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: isDarkTheme ? Colors.white : Colors.black, size: (isTablet() ? 12 : 20).sp),
              ),
              SizedBox(width: (isTablet() ? 10 : 16).w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: title,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                    // SizedBox(height: 4.h),
                    // CustomText(
                    //   text: subtitle,
                    //   fontSize: 14.sp,
                    //   color: isDarkTheme ? Colors.grey : Colors.grey.shade600,
                    // ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primaryColor,
                inactiveTrackColor:
                    isDarkTheme ? Colors.grey.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: isDarkTheme ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
            height: 1.h,
            indent: 56.w,
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkTheme) {
    final router = GoRouter.of(context); // ← capture here, safe

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
          title: CustomText(text: AppLocalizations.of(context)!.logout, fontSize: 18, fontWeight: FontWeight.bold),
          content: CustomText(text: AppLocalizations.of(context)!.areYouSureLogout, fontSize: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(text: AppLocalizations.of(context)!.cancel, fontSize: 16),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                LocationTracker().stopTracking();
                await Global.setDeliveryBoyStatus(false);
                await Global.clearDeliveryBoyStatus();
                await Global.clearUserToken();
                await Global.clearIdToken();
                // Navigate to login page
                router.go(AppRoutes.login);
              },
              child: CustomText(text: AppLocalizations.of(context)!.logout, fontSize: 16),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, bool isDarkTheme) {
    final profileBloc = context.read<ProfileBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
          title: CustomText(
            text: AppLocalizations.of(context)!.deleteAccount,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(text: AppLocalizations.of(context)!.deleteAccountDesc, fontSize: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: CustomText(text: AppLocalizations.of(context)!.cancel, fontSize: 16),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                profileBloc.add(const DeleteProfileEvent());
              },
              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColors.errorColor)),
              child: CustomText(text: AppLocalizations.of(context)!.delete, color: AppColors.backgroundColor),
            ),
            // TextButton(
            //   onPressed: () async {
            //     Navigator.of(context).pop();
            //
            //     LocationTracker().stopTracking();
            //     await Global.setDeliveryBoyStatus(false);
            //     await Global.clearDeliveryBoyStatus();
            //     await () {};
            //
            //     await Global.clearUserToken();
            //     await Global.clearIdToken();
            //     // Navigate to login page
            //     if (!context.mounted) return;
            //     GoRouter.of(context).pushReplacement(AppRoutes.login);
            //   },
            //   child: CustomText(text: AppLocalizations.of(context)!.delete, fontSize: 16),
            // ),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, bool isDarkTheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, locState) {
            final currentLanguage = locState.languageCode;
            final availableLanguages = context.read<LocalizationBloc>().getAvailableLanguages();

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Container(
                constraints: BoxConstraints(maxHeight: 600.h),
                decoration: BoxDecoration(
                  color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20.r, offset: Offset(0, 10.h)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.1),
                            AppColors.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(Icons.language_rounded, color: AppColors.primaryColor, size: 24.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: AppLocalizations.of(context)!.selectLanguage,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: 2.h),
                                CustomText(
                                  text: AppLocalizations.of(context)!.chooseYourPreferredLanguage,
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                          // Close button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20.sp,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Language options with scroll
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Column(
                          children:
                              availableLanguages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final language = entry.value;
                                final isSelected = language['code'] == currentLanguage;
                                final isLast = index == availableLanguages.length - 1;

                                return _buildEnhancedLanguageOption(
                                  languageCode: language['code'] as String,
                                  languageName: language['name'] as String,
                                  languageNameEnglish: language['nameEnglish'] as String,
                                  isSelected: isSelected,
                                  isLast: isLast,
                                  onTap: () {
                                    context.read<LocalizationBloc>().add(ChangeLocale(language['code'] as String));
                                    Navigator.of(context).pop();
                                    ToastManager.show(
                                      context: context,
                                      message: AppLocalizations.of(context)!.languageChangedTo(language['name']),
                                      type: ToastType.success,
                                    );
                                  },
                                  isDarkTheme: isDarkTheme,
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    // Bottom padding
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedLanguageOption({
    required String languageCode,
    required String languageName,
    required String languageNameEnglish,
    required bool isSelected,
    required bool isLast,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Language flag/code container
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primaryColor, AppColors.primaryColor.withValues(alpha: 0.8)],
                              )
                              : LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ],
                              ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ]
                              : [],
                    ),
                    child: Center(
                      child: CustomText(
                        text: languageCode.toUpperCase(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Language names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: languageName,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primaryColor : Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(height: 2.h),
                        CustomText(
                          text: languageNameEnglish,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isSelected ? Icon(Icons.check_rounded, color: Colors.white, size: 18.sp) : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider (except for last item)
        if (!isLast)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.0),
                  Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                  Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
