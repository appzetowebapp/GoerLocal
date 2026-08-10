import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_image_container.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';
import '../../model/profile_model.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.documents,
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen:
            (previous, current) =>
                previous.documentUploadStatus != current.documentUploadStatus ||
                previous.fetchStatus != current.fetchStatus,
        listener: (context, state) {
          if (state.documentUploadStatus == ApiStatus.success &&
              state.message.isNotEmpty) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.success,
            );
          } else if (state.fetchStatus == ApiStatus.failed ||
              state.documentUploadStatus == ApiStatus.failed) {
            if (state.message.isNotEmpty) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          }
        },
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          }

          if (state.fetchStatus == ApiStatus.success && state.profile != null) {
            return _buildDocumentsContent(state.profile!);
          }

          if (state.fetchStatus == ApiStatus.failed) {
            return ErrorStateWidget(
              onRetry: () {
                context.read<ProfileBloc>().add(const LoadProfile());
              },
            );
          }

          return const Center(child: LoadingWidget());
        },
      ),
    );
  }

  Widget _buildDocumentsContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Documents Header
              _buildDocumentsHeader(profile, isDarkTheme),
              SizedBox(height: 24.h),

              // Required Documents
              _buildSectionTitle(
                AppLocalizations.of(context)!.requiredDocuments,
              ),
              SizedBox(height: 16.h),

              _buildDocumentCard(
                title: AppLocalizations.of(context)!.driverLicense,
                description:
                    AppLocalizations.of(context)!.driverLicenseDescription,
                icon: Icons.credit_card,
                status:
                    profile.deliveryBoy?.driverLicense != null &&
                            profile.deliveryBoy!.driverLicense!.isNotEmpty
                        ? AppLocalizations.of(context)!.uploaded
                        : AppLocalizations.of(context)!.notUploaded,
                color:
                    profile.deliveryBoy?.driverLicense != null &&
                            profile.deliveryBoy!.driverLicense!.isNotEmpty
                        ? Colors.green
                        : Colors.red,
                url:
                    profile.deliveryBoy?.driverLicense?.isNotEmpty == true
                        ? profile.deliveryBoy!.driverLicense!.first
                        : null,
                documentType: 'driver_license',
                isUploaded:
                    profile.deliveryBoy?.driverLicense != null &&
                    profile.deliveryBoy!.driverLicense!.isNotEmpty,
                allUrls: profile.deliveryBoy?.driverLicense,
              ),
              SizedBox(height: 16.h),

              _buildDocumentCard(
                title: AppLocalizations.of(context)!.vehicleRegistration,
                description:
                    AppLocalizations.of(
                      context,
                    )!.vehicleRegistrationDescription,
                icon: Icons.description_outlined,
                status:
                    profile.deliveryBoy?.vehicleRegistration != null &&
                            profile.deliveryBoy!.vehicleRegistration!.isNotEmpty
                        ? AppLocalizations.of(context)!.uploaded
                        : AppLocalizations.of(context)!.notUploaded,
                color:
                    profile.deliveryBoy?.vehicleRegistration != null &&
                            profile.deliveryBoy!.vehicleRegistration!.isNotEmpty
                        ? Colors.green
                        : Colors.red,
                url:
                    profile.deliveryBoy?.vehicleRegistration?.isNotEmpty == true
                        ? profile.deliveryBoy!.vehicleRegistration!.first
                        : null,
                documentType: 'vehicle_registration',
                isUploaded:
                    profile.deliveryBoy?.vehicleRegistration != null &&
                    profile.deliveryBoy!.vehicleRegistration!.isNotEmpty,
                allUrls: profile.deliveryBoy?.vehicleRegistration,
              ),
              SizedBox(height: 24.h),

              // Document Guidelines

              // Upload Progress
              if (profile.deliveryBoy?.driverLicense != null &&
                  profile.deliveryBoy?.vehicleRegistration != null) ...[
                _buildSectionTitle(
                  AppLocalizations.of(context)!.uploadProgress,
                ),
                SizedBox(height: 16.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: sz(32, seprateTabletSize: 24).sp,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: CustomText(
                              text:
                                  AppLocalizations.of(
                                    context,
                                  )!.allDocumentsUploaded,
                              fontSize: sz(18, seprateTabletSize: 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      CustomText(
                        text:
                            AppLocalizations.of(
                              context,
                            )!.allDocumentsUploadedDescription,
                        fontSize: sz(14, seprateTabletSize: 10),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildSectionTitle(AppLocalizations.of(context)!.nextSteps),
                SizedBox(height: 16.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: sz(32, seprateTabletSize: 24).sp,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: CustomText(
                              text: 'Action Required',
                              fontSize: sz(18, seprateTabletSize: 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      CustomText(
                        text:
                            'Please upload the required documents to complete your profile verification and start accepting orders.',
                        fontSize: sz(14, seprateTabletSize: 10),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ).fadeAndSlideAnimation(),
    );
  }

  Widget _buildDocumentsHeader(ProfileModel profile, bool isDarkTheme) {
    final uploadedCount =
        [
          profile.deliveryBoy?.driverLicense,
          profile.deliveryBoy?.vehicleRegistration,
        ].where((url) => url != null).length;

    const totalCount = 2;
    final progress = uploadedCount / totalCount;

    return CustomCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 35.r,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.folder_open,
              size: (isTablet() ? 22 : 30).sp,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: 'Document Management',
            fontSize: sz(20, seprateTabletSize: 16),
            fontWeight: FontWeight.bold,
            color:
                isDarkTheme
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: (progress == 1.0 ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: CustomText(
              text: '$uploadedCount of $totalCount Documents',
              fontSize: sz(12, seprateTabletSize: 9),
              fontWeight: FontWeight.w500,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: sz(12, seprateTabletSize: 9),
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required IconData icon,
    required String status,
    required Color color,
    String? url,
    required String documentType,
    required bool isUploaded,
    List<String>? allUrls,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: sz(20, seprateTabletSize: 16).sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            text: title,
                            fontSize: sz(16, seprateTabletSize: 11),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: CustomText(
                            text: status,
                            fontSize: sz(12, seprateTabletSize: 9),
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: description,
                      fontSize: sz(14, seprateTabletSize: 10),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Show document images if uploaded
          if (isUploaded && url != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: color,
                        size: sz(16, seprateTabletSize: 12).sp,
                      ),
                      SizedBox(width: 8.w),
                      CustomText(
                        text: 'Document Images:',
                        fontSize: sz(12, seprateTabletSize: 9),
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Display the document image(s)
                  if (allUrls != null && allUrls.length > 1) ...[
                    // Show multiple images in a grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet() ? 3 : 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: allUrls.length,
                      itemBuilder: (context, index) {
                        return CustomImageContainer(
                          borderRadius: BorderRadius.circular(8.r),
                          imagePath: allUrls[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          // errorBuilder: (context, error, stackTrace) {
                          //   return Container(
                          //     decoration: BoxDecoration(
                          //       color: Colors.grey.withValues(alpha: 0.2),
                          //       borderRadius: BorderRadius.circular(8.r),
                          //     ),
                          //     child: Column(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Icon(
                          //           Icons.error_outline,
                          //           color: Colors.grey,
                          //           size: sz(24, seprateTabletSize: 18).sp,
                          //         ),
                          //         SizedBox(height: 4.h),
                          //         CustomText(
                          //           text: 'Failed to load',
                          //           fontSize: sz(10, seprateTabletSize: 8),
                          //           color: Colors.grey,
                          //         ),
                          //       ],
                          //     ),
                          //   );
                          // },
                        );
                      },
                    ),
                  ] else ...[
                    // Show single image
                    CustomImageContainer(
                      borderRadius: BorderRadius.circular(8.r),
                      imagePath: url,
                      width: double.infinity,
                      height: (isTablet() ? 160 : 200).h,
                      fit: BoxFit.cover,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          const Row(children: [Spacer()]),
        ],
      ),
    );
  }
}
