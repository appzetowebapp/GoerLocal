import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class PhoneAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event to send OTP to phone number
class SendOTPEvent extends PhoneAuthEvent {
  final String phoneNumber;

  SendOTPEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Event to verify OTP
class VerifyOTPEvent extends PhoneAuthEvent {
  final String verificationId;
  final String otp;

  VerifyOTPEvent({required this.verificationId, required this.otp});

  @override
  List<Object?> get props => [verificationId, otp];
}

/// Event when verification is completed automatically
class AutoVerificationCompletedEvent extends PhoneAuthEvent {
  final PhoneAuthCredential credential;
  final Map<String, dynamic>? registrationData;

  AutoVerificationCompletedEvent({
    required this.credential,
    this.registrationData,
  });

  @override
  List<Object?> get props => [credential, registrationData];
}

/// Event to resend OTP
class ResendOTPEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final Map<String, dynamic>? registrationData;

  ResendOTPEvent({required this.phoneNumber, this.registrationData});

  @override
  List<Object?> get props => [phoneNumber, registrationData];
}

/// Event to send OTP for registration
class SendOTPForRegistrationEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final Map<String, dynamic> registrationData;

  SendOTPForRegistrationEvent({
    required this.phoneNumber,
    required this.registrationData,
  });

  @override
  List<Object?> get props => [phoneNumber, registrationData];
}

/// Event to verify OTP and complete registration
class VerifyOTPAndRegisterEvent extends PhoneAuthEvent {
  final String verificationId;
  final String otp;
  final Map<String, dynamic> registrationData;

  VerifyOTPAndRegisterEvent({
    required this.verificationId,
    required this.otp,
    required this.registrationData,
  });

  @override
  List<Object?> get props => [verificationId, otp, registrationData];
}

/// Event to reset phone auth state
class ResetPhoneAuthEvent extends PhoneAuthEvent {}
