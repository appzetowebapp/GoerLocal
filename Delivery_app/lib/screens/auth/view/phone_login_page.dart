import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_event.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_state.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    return CustomScaffold(
      wantSafeArea: false,
      resizeToAvoidBottomInset: true,
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (BuildContext context, PhoneAuthState state) {
          if (state.status == PhoneAuthStatus.otpSent) {
            ToastManager.show(context: context, message: state.message);
            // Navigate to OTP verification page using GoRouter
            context.push(
              AppRoutes.phoneOtpVerification,
              extra: {
                'verificationId': state.verificationId,
                'phoneNumber': _completePhoneNumber,
              },
            );
          } else if (state.status == PhoneAuthStatus.failed) {
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.success) {
            ToastManager.show(context: context, message: state.message);
            // Use go() to replace navigation stack

            redirectionCondition(context);
            // context.go(AppRoutes.dashboard);
          }
        },
        child: Form(
          key: _formKey,
          child: Container(
            decoration:
                isDark
                    ? null
                    : const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.borderColor, AppColors.borderColor],
                      ),
                    ),
            child: Column(
              children: [
                /// Green area - approximately half of the screen
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// logo
                      logo(isDark),
                    ],
                  ),
                ),

                /// Form section - approximately half of the screen
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22.r),
                        topRight: Radius.circular(22.r),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 15.h),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: 'Phone Login',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: CustomText(
                                  text:
                                      'Enter your phone number to receive OTP',
                                  color: Colors.grey,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          phoneNumberField(isDark),
                          SizedBox(height: 30.h),

                          /// Submit button
                          submitButton(),
                          SizedBox(height: 15.h),

                          /// Divider with OR
                          orDivider(),
                          SizedBox(height: 15.h),

                          /// Navigate to email login
                          navigateToEmailLogin(),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Widget logo(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 200.h,
          width: 250.w,
          child: Image.asset(
            myLogoImage(isDark),
            width: 250.w,
            height: 200.h,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget phoneNumberField(bool isDark) {
    return IntlPhoneField(
      controller: _phoneController,
      decoration: InputDecoration(
        hintText: 'Phone Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDarkColor : AppColors.cardLightColor,
      ),
      initialCountryCode: 'IN',
      onChanged: (phone) {
        setState(() {
          // Ensure E.164 format with + prefix
          String phoneNumber = phone.completeNumber;
          if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+$phoneNumber';
          }
          _completePhoneNumber = phoneNumber;
        });
      },
      validator: (phone) {
        if (phone == null || phone.number.isEmpty) {
          return 'Please enter your phone number';
        }
        return null;
      },
    );
  }

  Widget submitButton() {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        final isLoading = state.status == PhoneAuthStatus.sendingOTP;

        return CustomButton(
          text: isLoading ? 'Sending OTP...' : 'Send OTP',
          onPressed:
              isLoading
                  ? null
                  : () {
                    if (_formKey.currentState!.validate()) {
                      if (_completePhoneNumber.isEmpty) {
                        ToastManager.show(
                          context: context,
                          message: 'Please enter a valid phone number',
                        );
                        return;
                      }

                      context.read<PhoneAuthBloc>().add(
                        SendOTPEvent(phoneNumber: _completePhoneNumber),
                      );
                    }
                  },
        );
      },
    );
  }

  Widget orDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: const CustomText(text: 'OR', color: Colors.grey),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget navigateToEmailLogin() {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push(AppRoutes.login);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomText(text: 'Login with Email?'),
          SizedBox(width: 5.w),
          const CustomText(
            text: 'Click here',
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
