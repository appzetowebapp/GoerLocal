import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_state.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../config/notification_service.dart';
import '../../../config/helper.dart';
import '../../../router/app_routes.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/user_verification/user_verification_bloc.dart';
import '../bloc/user_verification/user_verification_event.dart';

/// Tracks which field is currently being verified so the single
/// [UserVerificationBloc] state can be scoped correctly.
enum _VerifyingField { none, email, phone }

class RegisterPage extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  const RegisterPage({super.key, this.userName, this.userEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ─── Form ────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ─── Password visibility ─────────────────────────────────────────────────
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // ─── Phone field data ────────────────────────────────────────────────────
  String _completePhoneNumber = '';
  String _countryCode = '';
  String _phoneNumber = '';
  String _countryIso2 = '';
  String _countryName = '';

  // ─── Verification tracking ───────────────────────────────────────────────
  /// Which field fired the last verification request.
  _VerifyingField _activeVerifyField = _VerifyingField.none;

  /// Snapshot of the last phone-specific verification result so the phone
  /// helper row doesn't flicker when email state changes later.
  bool? _phoneVerified; // null = unknown, true = available, false = taken
  String? _phoneHelperText;
  Widget? _phoneStatusIcon;

  // ─── Debounce timers ─────────────────────────────────────────────────────
  DateTime? _lastEmailChange;
  DateTime? _lastPhoneChange;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName ?? '';
    _emailController.text = widget.userEmail ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserVerificationBloc>().add(ResetVerification());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Email change handler ─────────────────────────────────────────────────
  void _onEmailChanged(String value) {
    if (value.isEmpty) {
      setState(() => _activeVerifyField = _VerifyingField.none);
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    final now = DateTime.now();
    _lastEmailChange = now;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_lastEmailChange != now) return; // superseded by newer keystroke
      if (_emailController.text != value) return;

      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) return; // don't verify malformed emails

      setState(() => _activeVerifyField = _VerifyingField.email);
      context
          .read<UserVerificationBloc>()
          .add(VerifyUser(value: value, type: 'email'));
    });
  }

  // ─── Phone change handler ─────────────────────────────────────────────────
  void _onPhoneChanged(String number) {
    if (number.isEmpty) {
      setState(() {
        _activeVerifyField = _VerifyingField.none;
        _phoneVerified = null;
        _phoneHelperText = null;
        _phoneStatusIcon = null;
      });
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    final now = DateTime.now();
    _lastPhoneChange = now;

    // Reset phone helper while the user is still typing
    setState(() {
      _phoneVerified = null;
      _phoneHelperText = null;
      _phoneStatusIcon = null;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_lastPhoneChange != now) return;
      if (_phoneNumber != number) return;

      setState(() => _activeVerifyField = _VerifyingField.phone);
      String cleanPhone = _phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      context
          .read<UserVerificationBloc>()
          .add(VerifyUser(value: cleanPhone, type: 'mobile'));
    });
  }

  // ─── Consume verification bloc state for phone ───────────────────────────
  /// Called inside the BlocListener so phone helper state is snapshotted
  /// before the field is rebuilt by a later email state change.
  void _applyPhoneVerificationState(
      UserVerificationState state, AppLocalizations l10n) {
    if (_activeVerifyField != _VerifyingField.phone) return;

    if (state is VerifyingUser) {
      setState(() {
        _phoneVerified = null;
        _phoneHelperText = l10n.verifying;
        _phoneStatusIcon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
        );
      });
    } else if (state is UserVerified) {
      // On REGISTER the phone must be NEW (not already registered)
      final alreadyTaken = state.isUserVerified == true;
      setState(() {
        _phoneVerified = alreadyTaken ? false : true;
        _phoneHelperText = alreadyTaken
            ? l10n.phoneNumberAlreadyRegistered
            : l10n.phoneNumberAvailable;
        _phoneStatusIcon = Icon(
          alreadyTaken ? Icons.cancel : Icons.check_circle,
          color: alreadyTaken ? Colors.red : Colors.green,
          size: 16,
        );
      });
    } else if (state is UserVerificationFailed) {
      setState(() {
        _phoneVerified = null;
        _phoneHelperText = state.error.isNotEmpty ? state.error : l10n.unableToVerifyUser;
        _phoneStatusIcon =
        const Icon(Icons.error, color: AppTheme.errorColor, size: 16);
      });
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;

    // 1. Flutter form validators
    if (!_formKey.currentState!.validate()) return;

    // 2. Phone presence
    if (_completePhoneNumber.isEmpty || _phoneNumber.isEmpty) {
      ToastManager.show(
          context: context,
          message: l10n.pleaseEnterValidPhoneNumber,
          type: ToastType.error);
      return;
    }

    // 3. Email verification gate
    final verState = context.read<UserVerificationBloc>().state;
    if (_activeVerifyField == _VerifyingField.email && verState is VerifyingUser) {
      // Still checking – the button should already be disabled, but guard anyway
      return;
    }
    if (verState is UserVerified && verState.isUserVerified == true &&
        _activeVerifyField == _VerifyingField.email) {
      ToastManager.show(
          context: context,
          message: l10n.emailAlreadyRegisteredUseDifferent,
          type: ToastType.error);
      return;
    }
    if (verState is UserVerificationFailed &&
        _activeVerifyField == _VerifyingField.email) {
      ToastManager.show(
          context: context,
          message: l10n.errorVerifyingEmail,
          type: ToastType.error);
      return;
    }

    // 4. Phone verification gate (phone must be available / not taken)
    if (_phoneVerified == false) {
      ToastManager.show(
          context: context,
          message: l10n.phoneNumberAlreadyRegistered,
          type: ToastType.error);
      return;
    }

    // 5. Country metadata
    if (_countryCode.isEmpty || _countryIso2.isEmpty || _countryName.isEmpty) {
      ToastManager.show(
          context: context,
          message: l10n.pleaseSelectAValidCountryCode,   // add to ARB
          type: ToastType.error);
      return;
    }

    // 6. All good – dispatch events
    final registrationData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _phoneNumber,
      'password': _passwordController.text,
      'country': _countryName,
      'iso2': _countryIso2,
      'countryCode': _countryCode,
      'completePhoneNumber': _completePhoneNumber,
      'confirmPassword': _confirmPasswordController.text,
    };

    context.read<AuthBloc>().add(StoreRegistrationDataEvent(
      registrationData: registrationData,
      phoneNumber: _phoneNumber,
      countryCode: _countryCode,
      isoCode: _countryIso2,
    ));

    // Trigger AuthBloc to send OTP
    context.read<AuthBloc>().add(SendOtpToPhoneEvent(
      number: _phoneNumber,
      countryCode: _countryCode,
      isoCode: _countryIso2,
    ));
  }

  // ─── OTP navigation ───────────────────────────────────────────────────────
  void _handleRegister(String verificationId) {
    final l10n = AppLocalizations.of(context)!;
    final authBloc = context.read<AuthBloc>();
    final registrationData = authBloc.getPendingRegistrationData();

    if (registrationData == null) {
      ToastManager.show(
          context: context,
          message: l10n.registrationDataNotFound,
          type: ToastType.error);
      return;
    }
    if (!mounted) return;

    GoRouter.of(context).push(
      AppRoutes.otpVerification,
      extra: {
        'phoneNumber': registrationData['completePhoneNumber'],
        'registrationData': registrationData,
        'verificationId': verificationId,
        'userNumber': authBloc.getPendingPhoneNumber(),
        'countryCode': authBloc.getPendingCountryCode(),
        'isoCode': authBloc.getPendingIsoCode(),
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScaffold(
      title: l10n.register,
      showAppBar: true,
      showViewCart: false,
      body: MultiBlocListener(
        listeners: [
          // Auth events
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is LoginPhoneCodeSentState) {
                _handleRegister(state.verificationId ?? '');
              }
              if (state is AuthFailed) {
                ToastManager.show(
                    context: context,
                    message: state.error,
                    type: ToastType.error);
              }
            },
          ),
          // Verification events – snapshot phone results before they're lost
          BlocListener<UserVerificationBloc, UserVerificationState>(
            listener: (context, state) {
              _applyPhoneVerificationState(state, l10n);
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ── Header ──────────────────────────────────────────────
                Text(
                  l10n.createAccount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.black,
                    fontSize: isTablet(context) ? 28 : 20.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.pleaseFillDetailsCreateYourAccount,
                  style: TextStyle(
                      color: Colors.black, fontFamily: AppTheme.fontFamily),
                  textAlign: TextAlign.center,
                ), 
                const SizedBox(height: 32),

                // ── Full Name ────────────────────────────────────────────
                CustomTextFormField(
                  controller: _nameController,
                  labelText: l10n.fullName,
                  hintText: l10n.enterYourFullName,
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      ToastManager.show(
                          context: context,
                          message: l10n.pleaseEnterYourFullName,
                          type: ToastType.error);
                      return null;
                    }
                    if (value.trim().length < 2) {
                      ToastManager.show(
                          context: context,
                          message: l10n.nameMustBeAtLeast2Characters,
                          type: ToastType.error);
                      return null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ────────────────────────────────────────────────
                _EmailField(
                  controller: _emailController,
                  onChanged: _onEmailChanged,
                  // Only show email verification state when email is the active field
                  showVerificationState: _activeVerifyField == _VerifyingField.email,
                ),
                const SizedBox(height: 16),

                // ── Phone ────────────────────────────────────────────────
                _buildPhoneField(l10n),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────
                CustomTextFormField(
                  controller: _passwordController,
                  labelText: l10n.password,
                  hintText: l10n.enterYourPassword,
                  prefixIcon: Icons.lock,
                  suffixIcon: _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      ToastManager.show(
                          context: context,
                          message: l10n.pleaseEnterYourPassword,
                          type: ToastType.error);
                      return null;
                    }
                    if (value.length < 8) {
                      ToastManager.show(
                          context: context,
                          message: l10n.passwordMustBeAtLeast8Characters,
                          type: ToastType.error);
                      return null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ──────────────────────────────────────
                CustomTextFormField(
                  controller: _confirmPasswordController,
                  labelText: l10n.confirmPassword,
                  hintText: l10n.confirmYourPassword,
                  prefixIcon: Icons.lock,
                  suffixIcon: _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () => setState(() =>
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      ToastManager.show(
                          context: context,
                          message: l10n.pleaseConfirmYourPassword,
                          type: ToastType.error);
                      return null;
                    }
                    if (value != _passwordController.text) {
                      ToastManager.show(
                          context: context,
                          message: l10n.passwordsDoNotMatch,
                          type: ToastType.error);
                      return null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Submit button ─────────────────────────────────────────
                _SubmitButton(onPressed: _submit),
                const SizedBox(height: 16),

                // ── Login link ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAnAccount,
                      style:
                      TextStyle(fontSize: isTablet(context) ? 18 : 14, color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.login,
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet(context) ? 18 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Phone field widget ───────────────────────────────────────────────────
  Widget _buildPhoneField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntlPhoneField(
          showDropdownIcon: false,
          showCountryFlag: false,
          disableLengthCheck: true,
          cursorColor: Theme.of(context).colorScheme.tertiary,
          decoration: InputDecoration(
            labelText: l10n.phoneNumber,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isTablet(context) ? 20 : 16,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
            filled: true,
            fillColor: Colors.white,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
              fontSize: isTablet(context) ? 20 : 16,
            ),
            hintText: l10n.enterYourPhoneNumber,
            prefixIcon: Icon(
              Icons.phone,
              color: Colors.grey[600],
            ),
            prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontSize: isTablet(context) ? 20 : 16,
            ),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide:
              BorderSide(color: Colors.transparent),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          initialCountryCode: 'IN',
          textInputAction: TextInputAction.done,
          onChanged: (phone) {
            setState(() {
              _completePhoneNumber = phone.completeNumber;
              _countryCode = phone.countryCode;
              _phoneNumber = phone.number;
              _countryIso2 = phone.countryISOCode;
              _countryName = phone.countryISOCode.toUpperCase();
            });
            _onPhoneChanged(phone.number);
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ToastManager.show(
                  context: context,
                  message: l10n.pleaseEnterYourPhoneNumber,
                  type: ToastType.error,
                );
              });
              return null;
            }

            final number = phone.number.trim();

            if (number.length < 5) {
              return l10n.phoneNumberTooShort;
            }

            if (number.length > 16) {
              return l10n.phoneNumberTooLong;
            }

            if (!RegExp(r'^\d+$').hasMatch(number)) {
              return 'Only numbers allowed';
            }

            return null;
          },
        ),

        // Helper row – driven by snapshotted phone state
        if (_phoneHelperText != null) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              if (_phoneStatusIcon != null) ...[
                _phoneStatusIcon!,
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(
                  _phoneHelperText!,
                  style: TextStyle(
                    fontSize: isTablet(context) ? 18 : 12.sp,
                    color: _phoneVerified == true
                        ? Colors.green
                        : _phoneVerified == false
                        ? Colors.red
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Email field (extracted widget) ──────────────────────────────────────────
/// Builds the email field with inline verification feedback.
/// Receives [showVerificationState] so it only reacts to bloc state
/// when email is the field currently being verified.
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool showVerificationState;

  const _EmailField({
    required this.controller,
    required this.onChanged,
    required this.showVerificationState,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        // Determine helper content
        bool? isVerified;
        String? helperText;
        Widget? statusIcon;

        if (showVerificationState && controller.text.isNotEmpty) {
          if (state is VerifyingUser) {
            // spinner shown inline via Stack below
          } else if (state is UserVerified) {
            isVerified = state.isUserVerified; // true = already registered
            // On REGISTER: already registered = BAD (red), not registered = GOOD (green)
            helperText = isVerified == true
                ? l10n.emailAlreadyRegistered
                : l10n.emailAvailable;
            statusIcon = Icon(
              isVerified == true ? Icons.cancel : Icons.check_circle,
              color: isVerified == true ? Colors.red : Colors.green,
              size: 16,
            );
          } else if (state is UserVerificationFailed) {
            helperText = state.error.isNotEmpty ? state.error : l10n.errorVerifyingEmail;
            statusIcon =
            const Icon(Icons.error, color: Colors.red, size: 16);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Stack(
                children: [
                  CustomTextFormField(
                    controller: controller,
                    labelText: l10n.email,
                    hintText: l10n.enterYourEmail,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: onChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ToastManager.show(
                              context: context,
                              message: l10n.pleaseEnterYourEmail,
                              type: ToastType.error);
                        });
                        return null;
                      }
                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ToastManager.show(
                              context: context,
                              message: l10n.pleaseEnterAValidEmail,
                              type: ToastType.error);
                        });
                        return null;
                      }
                      return null;
                    },
                  ),
                  // Inline spinner while verifying
                  if (showVerificationState && state is VerifyingUser)
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: 40,
                      child: Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (statusIcon != null) ...[
                    statusIcon,
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      helperText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isVerified == true ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Submit button (extracted widget) ────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthLoading =
            authState is AuthLoading || authState is LoginCodeSentProgress;

        return BlocBuilder<UserVerificationBloc, UserVerificationState>(
          builder: (context, verState) {
            final isVerifying = verState is VerifyingUser;
            final isDisabled = isAuthLoading || isVerifying;

            return CustomButton(
              onPressed: isDisabled ? null : onPressed,
              child: isAuthLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : isVerifying
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.checkingEmail),
                ],
              )
                  : Text(
                l10n.createAccount,
                style: TextStyle(
                  fontSize: isTablet(context) ? 28 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        );
      },
    );
  }
}