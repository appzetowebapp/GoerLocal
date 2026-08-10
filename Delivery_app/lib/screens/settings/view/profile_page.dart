import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../../config/colors.dart';
import '../../../config/helper.dart';
import '../bloc/profile_bloc/profile_bloc.dart';
import '../bloc/profile_bloc/profile_event.dart';
import '../bloc/profile_bloc/profile_state.dart';
import '../model/profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.profile,
        showRefreshButton: true,
        onRefreshPressed: () {
          context.read<ProfileBloc>().add(const LoadProfile());
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
                  builder: (context, statusState) {
                    final isOnline = statusState.isOnline;
                    return BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, profileState) {
                        if (profileState.fetchStatus == ApiStatus.success && profileState.profile != null) {
                          final profile = profileState.profile!;
                          final profilePictureUrl = profile.user?.profileImage;

                          return CustomCard(
                            padding: EdgeInsets.all(10.w),
                            child: Row(
                              children: [
                                // Avatar resized to match reference
                                // CustomImageContainer(imagePath: profilePictureUrl ?? "", height: 70.r, width: 70.r),
                                CustomAvatar(imageUrl: profilePictureUrl ?? "", radius: 35.r),

                                SizedBox(width: 12.w), // reduced from 16

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        text:
                                            profile.deliveryBoy?.fullName ??
                                            profile.user?.name ??
                                            AppLocalizations.of(context)!.deliveryPartner,
                                        fontSize: sz(16, seprateTabletSize: 12), // updated
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),

                                      SizedBox(height: 8.h),

                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, // reduced from 14
                                          vertical: 4.h, // reduced from 5/6
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              profile.deliveryBoy != null
                                                  ? (isOnline ? Colors.green : Colors.orange).withValues(
                                                    alpha: context.isDarkMode ? 0.3 : 0.15,
                                                  )
                                                  : Colors.grey.withValues(alpha: context.isDarkMode ? 0.3 : 0.15),
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: CustomText(
                                          text:
                                              isOnline
                                                  ? AppLocalizations.of(context)!.active
                                                  : AppLocalizations.of(context)!.inactive,
                                          fontSize: sz(10, seprateTabletSize: 6), // updated
                                          fontWeight: FontWeight.w600,
                                          color:
                                              profile.deliveryBoy != null
                                                  ? (isOnline
                                                      ? (context.isDarkMode ? Colors.green[300] : Colors.green[700])
                                                      : (context.isDarkMode ? Colors.orange[300] : Colors.orange[700]))
                                                  : (context.isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (profileState.fetchStatus == ApiStatus.failed) {
                          return Container();
                        } else {
                          // Loading state resized
                          return CustomCard(
                            padding: EdgeInsets.all(10.w),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 35.r, // reduced from 40
                                  backgroundColor: Colors.grey[200],
                                ),

                                SizedBox(width: 12.w), // reduced from 16

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(width: 120.w, height: 16.h, color: Colors.grey[200]),
                                      SizedBox(height: 8.h),
                                      Container(width: 80.w, height: 12.h, color: Colors.grey[200]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Profile Options
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: AppLocalizations.of(context)!.personalInformation,
                  subtitle: AppLocalizations.of(context)!.updatePersonalDetails,
                  onTap: () => context.push(AppRoutes.personalInfo),
                ),
                _buildProfileOption(
                  icon: Icons.phone_outlined,
                  title: AppLocalizations.of(context)!.contactInformation,
                  subtitle: AppLocalizations.of(context)!.updatePhoneAndEmail,
                  onTap: () => context.push(AppRoutes.contactInfo),
                ),
                _buildProfileOption(
                  icon: Icons.directions_car_outlined,
                  title: AppLocalizations.of(context)!.vehicleInformation,
                  subtitle: AppLocalizations.of(context)!.updateVehicleDetails,
                  onTap: () => context.push(AppRoutes.vehicleInfo),
                ),
                // _buildProfileOption(
                //   icon: Icons.location_on_outlined,
                //   title: AppLocalizations.of(context)!.deliveryZones,
                //   subtitle: AppLocalizations.of(context)!.manageDeliveryAreas,
                //   onTap: () => context.push('/delivery-zone'),
                // ),
                _buildProfileOption(
                  icon: Icons.verified_user_outlined,
                  title: AppLocalizations.of(context)!.verificationStatus,
                  subtitle: AppLocalizations.of(context)!.checkVerificationStatus,
                  onTap: () => context.push(AppRoutes.verificationStatus),
                ),
                _buildProfileOption(
                  icon: Icons.document_scanner_outlined,
                  title: AppLocalizations.of(context)!.documents,
                  subtitle: AppLocalizations.of(context)!.uploadAndManageDocuments,
                  onTap: () => context.push(AppRoutes.documents),
                ),
              ],
            ).fadeAndSlideAnimation(),
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context, ProfileModel profile) {
    final String name = profile.deliveryBoy?.fullName ?? AppLocalizations.of(context)!.deliveryPartner;

    final String initials = _getInitials(name);

    return Text(initials, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";

    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = "";

    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0].toUpperCase();
    }
    if (nameParts.length > 1) {
      initials += nameParts.last[0].toUpperCase();
    }

    return initials;
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: CustomCard(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all((isTablet() ? 7 : 12).w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: (isTablet() ? 12 : 18).sp),
                ),
                SizedBox(width: (isTablet() ? 10 : 16).w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: title,
                        fontSize: sz(14, seprateTabletSize: 10),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: subtitle,
                        fontSize: sz(12, seprateTabletSize: 9),
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: (isTablet() ? 12 : 16).sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
