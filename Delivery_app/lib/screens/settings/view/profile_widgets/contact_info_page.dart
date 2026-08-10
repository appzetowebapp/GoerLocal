import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_event.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';

import '../../model/profile_model.dart';

import 'package:hyper_local/l10n/app_localizations.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  // Country field data
  String _countryName = '';

  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());
    context.read<SystemSettingsBloc>().add(FetchSystemSettings());
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populateFields(ProfileModel profile) {
    if (profile.user != null) {
      _mobileController.text = profile.user!.mobile ?? '';
      _emailController.text = profile.user!.email ?? '';
      _countryController.text = profile.user!.country ?? '';
      _countryName = profile.user!.country ?? '';
      // Set default country if none is set
      if (_countryName.isEmpty) {
        _countryName = 'India';
      }
    }
  }

  void _toggleEdit() {
    final bool isDemo = context.read<SystemSettingsBloc>().isDemo;
    if (isDemo) {
      ToastManager.show(
        context: context,
        message: context.read<SystemSettingsBloc>().demoMessage,
        type: ToastType.info,
      );
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // UpdateProfile now only needs the contact info fields we're updating
      context.read<ProfileBloc>().add(
        UpdateProfile(
          // Personal info fields are not needed for contact info updates
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          country: _countryName.trim(),
        ),
      );

      // The ProfileBloc will emit ProfileUpdating -> ProfileUpdated states
      // We'll handle these in the BlocConsumer listener
    }
  }

  void _cancelEdit() {
    // Reload profile data to reset fields

    context.read<ProfileBloc>().add(const ResetUpdateStatus());
    context.read<ProfileBloc>().add(const LoadProfile());
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.contactInformation,
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen:
            (previous, current) =>
                previous.fetchStatus != current.fetchStatus ||
                previous.updateStatus != current.updateStatus,
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.success &&
              state.updateStatus == ApiStatus.initial) {
            if (state.profile != null) _populateFields(state.profile!);
          } else if (state.updateStatus == ApiStatus.loading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state.updateStatus == ApiStatus.success) {
            setState(() {
              _isLoading = false;
              _isEditing = false;
            });
            if (state.profile != null) _populateFields(state.profile!);
            ToastManager.show(
              context: context,
              message: AppLocalizations.of(context)!.contactInformationUpdated,
              type: ToastType.success,
            );
            context.read<ProfileBloc>().add(const ResetUpdateStatus());
          } else if (state.fetchStatus == ApiStatus.failed ||
              state.updateStatus == ApiStatus.failed) {
            setState(() {
              _isLoading = false;
            });
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
          if (state.fetchStatus == ApiStatus.success ||
              state.updateStatus == ApiStatus.success) {
            if (state.profile != null) {
              return _buildContactInfoContent(state.profile!);
            }
          }
          if (state.fetchStatus == ApiStatus.failed) {
            return ErrorStateWidget(
              onRetry: () {
                context.read<ProfileBloc>().add(const LoadProfile());
              },
            );
          }
          return _buildContactInfoContent(state.profile ?? ProfileModel());
        },
      ),
    );
  }

  Widget _buildContactInfoContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Check if profile data is available
    final hasProfileData = profile.user != null || profile.deliveryBoy != null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Header
              _buildContactHeader(profile, isDarkTheme),
              SizedBox(height: 24.h),

              // Contact Information Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.phoneAndEmail,
                    ),
                    SizedBox(height: 16.h),

                    // Mobile Number
                    _buildInfoField(
                      label: AppLocalizations.of(context)!.mobileNumber,
                      controller: _mobileController,
                      icon: Icons.phone_outlined,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.mobileNumberRequired;
                        }
                        if (value.length < 10) {
                          return AppLocalizations.of(
                            context,
                          )!.mobileNumberMinLength;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Email
                    _buildInfoField(
                      label: AppLocalizations.of(context)!.emailAddress,
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.emailRequired;
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return AppLocalizations.of(
                            context,
                          )!.validEmailRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle(
                      AppLocalizations.of(context)!.locationInformation,
                    ),
                    SizedBox(height: 16.h),

                    // Country
                    _buildInfoField(
                      label: AppLocalizations.of(context)!.country,
                      controller: _countryController,
                      icon: Icons.public_outlined,
                      isEditing: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.countryRequired;
                        }
                        return null;
                      },
                      isCountryField: true,
                      onCountryTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          countryListTheme: CountryListThemeData(
                            flagSize: 25,
                            backgroundColor:
                                Theme.of(context).colorScheme.sameColorChange,
                            textStyle: TextStyle(
                              fontSize: (isTablet() ? 11 : 16).sp,
                              color:
                                  Theme.of(context).colorScheme.oppColorChange,
                            ),
                            bottomSheetHeight: 500,

                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.w),
                              topRight: Radius.circular(20.w),
                            ),
                            inputDecoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.search,
                              hintText: AppLocalizations.of(context)!.search,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color(
                                    0xFF8C98A8,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                          onSelect: (Country country) {
                            setState(() {
                              _countryController.text = country.name;
                              _countryName = country.name;
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Additional Contact Info
                    SizedBox(height: 24.h),

                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: AppLocalizations.of(context)!.cancel,
                              onPressed: _cancelEdit,
                              backgroundColor: Colors.grey,
                              textColor: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: CustomButton(
                              text:
                                  _isLoading
                                      ? AppLocalizations.of(context)!.saving
                                      : AppLocalizations.of(
                                        context,
                                      )!.saveChanges,
                              onPressed: _isLoading ? null : _saveChanges,
                              backgroundColor: AppColors.primaryColor,
                              textColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text:
                              hasProfileData
                                  ? AppLocalizations.of(
                                    context,
                                  )!.editInformation
                                  : AppLocalizations.of(context)!.loading,
                          onPressed: hasProfileData ? _toggleEdit : null,
                          backgroundColor: AppColors.primaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ],
          ).fadeAndSlideAnimation(),
    );
  }

  Widget _buildContactHeader(ProfileModel profile, bool isDarkTheme) {
    final hasProfileData = profile.user != null;
    final status = profile.deliveryBoy?.status;

    // Resolve status text safely
    final statusText =
        hasProfileData
            ? (status == 'active'
                ? 'ACTIVE'
                : status != null
                ? 'INACTIVE'
                : 'UNKNOWN')
            : AppLocalizations.of(context)!.loading.toUpperCase();

    // Resolve status color safely
    final statusColor =
        hasProfileData
            ? (status == 'active'
                ? Colors.green
                : status != null
                ? Colors.orange
                : Colors.grey)
            : Colors.grey;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((isTablet() ? 10 : 16).w), // ↓ reduced from 20
      decoration: BoxDecoration(
        color:
            isDarkTheme
                ? AppColors.cardDarkColor
                : AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ FIXED alignment
        children: [
          // Avatar
          CircleAvatar(
            radius: 35.r,
            backgroundColor:
                isDarkTheme
                    ? Theme.of(context).colorScheme.surface
                    : AppColors.primaryColor.withValues(alpha: 0.15),
            child: Icon(
              Icons.contact_phone,
              size: 28.sp,
              color: AppColors.primaryColor,
            ),
          ),

          SizedBox(width: 12.w), // ✅ match spacing with profile header

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name / Title
                CustomText(
                  text:
                      hasProfileData
                          ? (profile.deliveryBoy?.fullName ??
                              profile.user?.name ??
                              AppLocalizations.of(context)!.contactInformation)
                          : AppLocalizations.of(context)!.loading,
                  fontSize: sz(16, seprateTabletSize: 12), // ↓ from 18.sp
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8.h),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w, // ↓ from 14
                    vertical: 4.h, // ↓ from 7
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: isDarkTheme ? 0.3 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: CustomText(
                    text: statusText,
                    fontSize: sz(10, seprateTabletSize: 6), // ↓ from 10.sp
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkTheme
                            ? statusColor.withValues(alpha: 0.9)
                            : statusColor.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isCountryField = false,
    VoidCallback? onCountryTap,
  }) {
    final isEmpty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: sz(12, seprateTabletSize: 9), // ↓ from 14.sp
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),

        SizedBox(height: 6.h), // ↓ from 8

        if (isEditing)
          CustomTextFormField(
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            validator: validator,
            prefixIcon: icon,
            borderRadius: 12.0.r,
            borderColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.3),
            focusedBorderColor: AppColors.primaryColor,

            // 🎯 Smart behavior switch
            readOnly: isCountryField,
            onTap: isCountryField ? onCountryTap : null,
            hintText:
                isCountryField
                    ? AppLocalizations.of(context)!.pleaseSelectACountry
                    : null,

            textInputAction: TextInputAction.next,
          )
        else
          CustomCard(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w, // better balance than all(10)
              vertical: 10.h,
            ),
            height: 48.h, // perfectly synced with your form fields
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 18.sp, // ↓ from 20
                ),

                SizedBox(width: 10.w), // ↓ from 12

                Expanded(
                  child: CustomText(
                    fontSize: sz(14, seprateTabletSize: 10), // ↓ from 16.sp

                    text:
                        isEmpty
                            ? AppLocalizations.of(context)!.notProvided
                            : controller.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color:
                        isEmpty
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
