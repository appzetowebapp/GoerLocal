import 'dart:async';
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
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../l10n/app_localizations.dart';

class PhoneOTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isRegistration;
  final Map<String, dynamic>? registrationData;

  const PhoneOTPVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isRegistration = false,
    this.registrationData,
  });

  @override
  State<PhoneOTPVerificationPage> createState() =>
      _PhoneOTPVerificationPageState();
}

class _PhoneOTPVerificationPageState extends State<PhoneOTPVerificationPage> {
  late TextEditingController _otpController;
  final _formKey = GlobalKey<FormState>();
  String _currentOtp = '';
  int _resendTimer = 60;
  Timer? _timer;
  bool _isResentTap = false;

  @override
  void initState() {
    _otpController = TextEditingController();
    super.initState();
    _startResendTimer();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    try {
      _otpController.dispose();
    } catch (e) {
      debugPrint('Error disposing OTP controller: $e');
    }
    super.dispose();
  }

  void _startResendTimer() {
    _isResentTap = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;

    return CustomScaffold(
      wantSafeArea: false,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDark ? null : const Color.fromARGB(255, 0, 18, 177),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (BuildContext context, PhoneAuthState state) async {
          if (state.status == PhoneAuthStatus.otpVerified) {
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.success) {
            ///Here when i just enter number of Currently Registered User and this called

            ToastManager.show(context: context, message: state.message);
            // context.go(AppRoutes.dashboard);
            redirectionCondition(context);
          } else if (state.status == PhoneAuthStatus.registrationSuccess) {
            ///When New User Registered thnen this Shows up

            ToastManager.show(context: context, message: state.message);
            ToastManager.show(
              context: context,
              message: AppLocalizations.of(context)!.accountNotVerified,
            );
            context.go(AppRoutes.pendingApproval);

            // context.go(AppRoutes.dashboard);
          } else if (state.status == PhoneAuthStatus.userNotFound) {
            // Phone verified but no account — show message and redirect
            ToastManager.show(context: context, message: state.message);

            // Navigate back to login using go() to clear the phone login/otp stack
            context.go(AppRoutes.login);

            // Then push registration on top so login is in the backstack
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                context.push(AppRoutes.register);
              }
            });
          } else if (state.status == PhoneAuthStatus.failed) {
            setState(() {
              _isResentTap = false;
            });
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.otpResent) {
            ToastManager.show(
              context: context,
              message: 'OTP resent successfully',
            );
            _startResendTimer();
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
                        colors: [
                          Color.fromARGB(255, 10, 13, 155),
                          Color.fromARGB(255, 10, 13, 155),
                        ],
                      ),
                    ),
            child: Column(
              children: [
                /// Top section with icon
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 80.sp,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                /// Form section
                Expanded(
                  flex: 2,
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
                          const CustomText(
                            text: 'Verify OTP',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          const CustomText(
                            text: 'Enter the 6-digit code sent to',
                            color: Colors.grey,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5.h),
                          CustomText(
                            text: widget.phoneNumber,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30.h),
                          otpField(),
                          SizedBox(height: 30.h),

                          /// Verify button
                          verifyButton(),
                          SizedBox(height: 15.h),

                          /// Resend OTP
                          resendOTPWidget(),
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

  Widget otpField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: PinCodeTextField(
        textStyle: const TextStyle(color: AppColors.textColor),
        appContext: context,
        length: 6,
        controller: _otpController,
        obscureText: false,
        animationType: AnimationType.fade,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(10.r),
          fieldHeight: 50.h,
          fieldWidth: 45.w,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.grey.shade50,
          selectedFillColor: Colors.white,
          activeColor: AppColors.primaryColor,
          inactiveColor: Colors.grey.shade300,
          selectedColor: AppColors.primaryColor,
          errorBorderColor: Colors.red,
        ),
        cursorColor: AppColors.primaryColor,
        animationDuration: const Duration(milliseconds: 300),
        enableActiveFill: true,
        keyboardType: TextInputType.number,
        onCompleted: (value) {
          if (mounted) {
            setState(() {
              _currentOtp = value;
            });
          }
        },
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _currentOtp = value;
            });
          }
        },
      ),
    );
  }

  Widget verifyButton() {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        final isLoading =
            state.status == PhoneAuthStatus.verifyingOTP ||
            state.status == PhoneAuthStatus.authenticating ||
            state.status == PhoneAuthStatus.registering;

        String buttonText = 'Verify OTP';
        if (state.status == PhoneAuthStatus.verifyingOTP) {
          buttonText = 'Verifying...';
        } else if (state.status == PhoneAuthStatus.authenticating) {
          buttonText = 'Authenticating...';
        } else if (state.status == PhoneAuthStatus.registering) {
          buttonText = 'Registering...';
        }

        return CustomButton(
          text: buttonText,
          onPressed:
              isLoading
                  ? null
                  : () {
                    if (_currentOtp.length != 6) {
                      ToastManager.show(
                        context: context,
                        message: 'Please enter the complete 6-digit OTP',
                      );
                      return;
                    }

                    if (widget.isRegistration &&
                        widget.registrationData != null) {
                      // Registration flow - verify OTP and register
                      context.read<PhoneAuthBloc>().add(
                        VerifyOTPAndRegisterEvent(
                          verificationId: widget.verificationId,
                          otp: _currentOtp,
                          registrationData: widget.registrationData!,
                        ),
                      );
                    } else {
                      // Login flow - verify OTP
                      context.read<PhoneAuthBloc>().add(
                        VerifyOTPEvent(
                          verificationId: widget.verificationId,
                          otp: _currentOtp,
                        ),
                      );
                    }
                  },
        );
      },
    );
  }

  Widget PhoneAuthBlocOTPWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomText(text: "Didn't receive the code? "),
        if (_resendTimer > 0)
          CustomText(
            text: 'Resend in ${_resendTimer}s',
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          )
        else
          GestureDetector(
            onTap: () {
              context.read<PhoneAuthBloc>().add(
                ResendOTPEvent(
                  phoneNumber: widget.phoneNumber,
                  registrationData: widget.registrationData,
                ),
              );
            },
            child: const CustomText(
              text: 'Resend',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget resendOTPWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CustomText(text: "Didn't receive the code? "),

        if (_resendTimer > 0)
          CustomText(
            text: 'Resend in ${_resendTimer}s',
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          )
        else
          GestureDetector(
            onTap: () {
              if (_isResentTap) return;
              setState(() {
                _isResentTap = true;
              });
              context.read<PhoneAuthBloc>().add(
                ResendOTPEvent(
                  phoneNumber: widget.phoneNumber,
                  registrationData: widget.registrationData,
                ),
              );
            },
            child: CustomText(
              text: 'Resend',
              color: _isResentTap ? Colors.grey : AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
