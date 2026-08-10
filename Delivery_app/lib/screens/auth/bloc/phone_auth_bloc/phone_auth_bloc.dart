import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/screens/auth/repo/auth_repo.dart';
import 'package:hyper_local/screens/auth/repo/phone_auth_repo.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'phone_auth_event.dart';
import 'phone_auth_state.dart';

class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  final PhoneAuthRepository _phoneAuthRepository = PhoneAuthRepository();

  final SystemSettingsBloc _systemSettingsBloc;

  PhoneAuthBloc(this._systemSettingsBloc) : super(const PhoneAuthState()) {
    on<SendOTPEvent>(_onSendOTP);

    on<SendOTPForRegistrationEvent>(_onSendOTPForRegistration);

    on<VerifyOTPEvent>(_onVerifyOTP);

    on<VerifyOTPAndRegisterEvent>(_onVerifyOTPAndRegister);

    on<AutoVerificationCompletedEvent>(_onAutoVerificationCompleted);

    on<ResendOTPEvent>(_onResendOTP);

    on<ResetPhoneAuthEvent>(_onResetPhoneAuth);
  }

  Future<bool> _shouldUseBackendOtp() async {
    try {
      final dio = Dio();
      final response = await dio.get('${deliveryZoneUrl}settings/auth-config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['useBackendOtpApi'] == true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching auth config: $e');
    }
    return _systemSettingsBloc.currentSettings?.isCustomSmsEnabled ?? false;
  }

  Future<void> _onSendOTP(
    SendOTPEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.sendingOTP, clearMessage: true),
    );
    try {
      if (kDebugMode) {
        debugPrint('📱 Sending OTP to: ${event.phoneNumber}');
      }

      final isCustomSms = await _shouldUseBackendOtp();

      final result = await _phoneAuthRepository.sendOTP(
        phoneNumber: event.phoneNumber,
        isCustomSms: isCustomSms,
      );

      if (!emit.isDone) {
        if (result['autoVerified'] == true) {
          // Auto verification completed
          add(
            AutoVerificationCompletedEvent(
              credential: result['credential'] as PhoneAuthCredential,
            ),
          );
        } else {
          // OTP sent successfully
          emit(
            state.copyWith(
              status: PhoneAuthStatus.otpSent,
              verificationId: result['verificationId'],
              message: 'OTP sent successfully to ${event.phoneNumber}',
            ),
          );
        }
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(status: PhoneAuthStatus.failed, message: e.toString()),
        );
      }
    }
  }

  Future<void> _onVerifyOTP(
    VerifyOTPEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.verifyingOTP, clearMessage: true),
    );
    try {
      // Verify OTP and get idToken
      final isCustomSms = await _shouldUseBackendOtp();

      final verifyResult = await _phoneAuthRepository.verifyOTP(
        verificationId: event.verificationId,
        otp: event.otp,
        isCustomSms: isCustomSms,
      );

      if (verifyResult['success'] == true) {
        // If Custom SMS, we might have accessToken directly
        if (isCustomSms && verifyResult.containsKey('accessToken')) {
          final String accessToken = verifyResult['accessToken'];
          final String message =
              verifyResult['message'] ?? 'OTP verified successfully';

          // Emit verified state
          emit(
            state.copyWith(
              status: PhoneAuthStatus.otpVerified,
              idToken: '',
              message: message,
            ),
          );

          // Skip backend callback, save token directly
          emit(state.copyWith(status: PhoneAuthStatus.authenticating));

          if (kDebugMode) {
            debugPrint('💾 [Custom SMS] Saving access token directly...');
            debugPrint('Access Token: $accessToken');
          }

          // Store accessToken
          await Global.setUserToken(accessToken);
          await Global.setIdToken('');
          await Global.refreshCachedToken();

          emit(
            state.copyWith(
              status: PhoneAuthStatus.success,
              message: message,
              accessToken: accessToken,
            ),
          );
          return;
        }

        final String idToken = verifyResult['idToken'] ?? '';

        emit(
          state.copyWith(
            status: PhoneAuthStatus.otpVerified,
            idToken: idToken,
            message: 'OTP verified successfully',
          ),
        );

        // Send idToken to backend
        emit(state.copyWith(status: PhoneAuthStatus.authenticating));

        final response = await _phoneAuthRepository.sendIdTokenToBackend(
          idToken: idToken,
        );

        if (response.success) {
          final accessToken = response.accessToken ?? '';

          if (kDebugMode) {
            debugPrint('💾 Saving tokens...');
            debugPrint('Access Token: $accessToken');
            debugPrint('ID Token: $idToken');
          }

          // Store both idToken and accessToken
          await Global.setUserToken(accessToken);
          await Global.setIdToken(idToken);

          // Refresh cached token to ensure it's loaded
          await Global.refreshCachedToken();

          if (kDebugMode) {
            final savedToken = await Global.getUserToken();
            debugPrint(
              '✅ Token saved and verified: ${savedToken?.isNotEmpty ?? false}',
            );
            debugPrint('Saved Token: $savedToken');
          }

          emit(
            state.copyWith(
              status: PhoneAuthStatus.success,
              message: response.message,
              accessToken: accessToken,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: PhoneAuthStatus.failed,
              message: response.message,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: PhoneAuthStatus.failed,
            message: 'OTP verification failed',
          ),
        );
      }
    } on UserNotFoundException catch (e) {
      await _phoneAuthRepository.signOut();
      emit(
        state.copyWith(
          status: PhoneAuthStatus.userNotFound,
          message: e.message,
        ),
      );
    } catch (e) {
      await Global.clearUserToken();
      emit(
        state.copyWith(
          status: PhoneAuthStatus.failed,
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onAutoVerificationCompleted(
    AutoVerificationCompletedEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.verifyingOTP, clearMessage: true),
    );
    try {
      // Sign in with credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        event.credential,
      );

      // Get ID Token
      String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        emit(
          state.copyWith(
            status: PhoneAuthStatus.failed,
            message: 'Failed to get ID token',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: PhoneAuthStatus.otpVerified,
          idToken: idToken,
          message: 'Phone verified automatically',
        ),
      );

      if (event.registrationData != null) {
        // Registration flow - call register API
        add(
          VerifyOTPAndRegisterEvent(
            verificationId: '',
            otp: '',
            registrationData: event.registrationData!,
          ),
        );
        return;
      }

      // Login flow - send idToken to backend
      emit(state.copyWith(status: PhoneAuthStatus.authenticating));

      final response = await _phoneAuthRepository.sendIdTokenToBackend(
        idToken: idToken,
      );

      if (response.success) {
        final accessToken = response.accessToken ?? '';

        if (kDebugMode) {
          debugPrint('💾 [Auto-Verify] Saving tokens...');
          debugPrint('Access Token: $accessToken');
          debugPrint('ID Token: $idToken');
        }

        // Store both idToken and accessToken
        await Global.setUserToken(accessToken);
        await Global.setIdToken(idToken);

        // Refresh cached token to ensure it's loaded
        await Global.refreshCachedToken();

        if (kDebugMode) {
          final savedToken = await Global.getUserToken();
          debugPrint(
            '✅ [Auto-Verify] Token saved: ${savedToken?.isNotEmpty ?? false}',
          );
        }

        emit(
          state.copyWith(
            status: PhoneAuthStatus.success,
            message: response.message,
            accessToken: accessToken,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PhoneAuthStatus.failed,
            message: response.message,
          ),
        );
      }
    } on UserNotFoundException catch (e) {
      await _phoneAuthRepository.signOut();
      emit(
        state.copyWith(
          status: PhoneAuthStatus.userNotFound,
          message: e.message,
        ),
      );
    } catch (e) {
      await Global.clearUserToken();
      emit(
        state.copyWith(status: PhoneAuthStatus.failed, message: e.toString()),
      );
    }
  }

  Future<void> _onResendOTP(
    ResendOTPEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.sendingOTP, clearMessage: true),
    );
    try {
      final isCustomSms = await _shouldUseBackendOtp();

      final result = await _phoneAuthRepository.resendOTP(
        phoneNumber: event.phoneNumber,
        isCustomSms: isCustomSms,
      );

      if (!emit.isDone) {
        if (result['autoVerified'] == true) {
          // Auto verification completed
          add(
            AutoVerificationCompletedEvent(
              credential: result['credential'] as PhoneAuthCredential,
              registrationData: event.registrationData,
            ),
          );
        } else {
          // OTP resent successfully
          emit(
            state.copyWith(
              status: PhoneAuthStatus.otpResent,
              verificationId: result['verificationId'],
              message: 'OTP resent successfully',
            ),
          );
        }
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(status: PhoneAuthStatus.failed, message: e.toString()),
        );
      }
    }
  }

  Future<void> _onResetPhoneAuth(
    ResetPhoneAuthEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(const PhoneAuthState());
  }

  Future<void> _onSendOTPForRegistration(
    SendOTPForRegistrationEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.sendingOTP, clearMessage: true),
    );
    try {
      if (kDebugMode) {
        debugPrint('📱 Sending OTP for registration to: ${event.phoneNumber}');
      }

      final isCustomSms = await _shouldUseBackendOtp();

      final result = await _phoneAuthRepository.sendOTP(
        phoneNumber: event.phoneNumber,
        isCustomSms: isCustomSms,
      );

      if (!emit.isDone) {
        if (result['autoVerified'] == true) {
          // Auto verification completed - proceed with registration
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(
                result['credential'] as PhoneAuthCredential,
              );
          String? idToken = await userCredential.user?.getIdToken();

          if (idToken != null) {
            // Call register API directly
            add(
              VerifyOTPAndRegisterEvent(
                verificationId: '',
                otp: '',
                registrationData: event.registrationData,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: PhoneAuthStatus.failed,
                message: 'Failed to get ID token',
              ),
            );
          }
        } else {
          // OTP sent successfully
          emit(
            state.copyWith(
              status: PhoneAuthStatus.otpSent,
              verificationId: result['verificationId'],
              message: 'OTP sent successfully to ${event.phoneNumber}',
            ),
          );
        }
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(status: PhoneAuthStatus.failed, message: e.toString()),
        );
      }
    }
  }

  Future<void> _onVerifyOTPAndRegister(
    VerifyOTPAndRegisterEvent event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(
      state.copyWith(status: PhoneAuthStatus.verifyingOTP, clearMessage: true),
    );
    try {
      String idToken = '';
      String accessTokenFromResult = '';
      final isCustomSms = await _shouldUseBackendOtp();

      if (event.verificationId.isNotEmpty && event.otp.isNotEmpty) {
        // Verify OTP and get idToken
        try {
          final verifyResult = await _phoneAuthRepository.verifyOTP(
            verificationId: event.verificationId,
            otp: event.otp,
            isCustomSms: isCustomSms,
          );

          if (verifyResult['success'] == true) {
            idToken = verifyResult['idToken'] ?? '';
            accessTokenFromResult = verifyResult['accessToken'] ?? '';
          } else {
            emit(
              state.copyWith(
                status: PhoneAuthStatus.failed,
                message: 'OTP verification failed',
              ),
            );
            return;
          }
        } on UserNotFoundException catch (_) {
          // This is completely expected during Registration.
          // The OTP was correct, but the user is indeed a new user.
          // Proceed with the registration flow!
          idToken = '';
          accessTokenFromResult = '';
        }
      } else if (!isCustomSms) {
        // Already verified (auto-verification), get current token - only for Firebase
        idToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';
        if (idToken.isEmpty) {
          emit(
            state.copyWith(
              status: PhoneAuthStatus.failed,
              message: 'Failed to get ID token',
            ),
          );
          return;
        }
      }

      if (idToken.isNotEmpty || isCustomSms) {
        emit(
          state.copyWith(
            status: PhoneAuthStatus.otpVerified,
            idToken: idToken,
            message: 'OTP verified successfully',
          ),
        );

        // Call registration API
        emit(state.copyWith(status: PhoneAuthStatus.registering));

        final regData = event.registrationData;

        if (kDebugMode) {
          debugPrint('📝 Starting registration with OTP verified...');
        }

        final response = await AuthRepository().register(
          name: regData['name'],
          email: regData['email'],
          mobile: regData['mobile'],
          country: regData['country'],
          iso2: regData['iso2'],
          password: regData['password'],
          confirmPassword: regData['confirmPassword'],
          address: regData['address'],
          driverLicenseNumber: regData['driverLicenseNumber'],
          vehicleType: regData['vehicleType'],
          deliveryZoneId: regData['deliveryZoneId'],
          driverLicenseFile: regData['driverLicenseFile'] as File,
          vehicleRegistrationFile: regData['vehicleRegistrationFile'] as File,
          friends_code: regData['friends_code'],
        );

        if (response['success'] == true) {
          final accessToken =
              response['access_token']?.toString() ?? accessTokenFromResult;

          if (kDebugMode) {
            debugPrint('💾 Registration successful! Saving tokens...');
            debugPrint('Access Token: $accessToken');
          }

          // Store tokens
          await Global.setUserToken(accessToken);
          await Global.setIdToken(idToken);
          await Global.refreshCachedToken();

          if (kDebugMode) {
            final savedToken = await Global.getUserToken();
            debugPrint(
              '✅ Token saved after registration: ${savedToken?.isNotEmpty ?? false}',
            );
          }

          emit(
            state.copyWith(
              status: PhoneAuthStatus.registrationSuccess,
              message: response['message'] ?? 'Registration successful',
              accessToken: accessToken,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: PhoneAuthStatus.failed,
              message: response['message'] ?? 'Registration failed',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: PhoneAuthStatus.failed,
            message: 'OTP verification failed',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registration error: $e');
      }
      emit(
        state.copyWith(
          status: PhoneAuthStatus.failed,
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
