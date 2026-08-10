import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class AuthState extends Equatable {
  final ApiStatus status;
  final String message;
  final MobileANdEmailStatus mobileANdEmailStatus;
  final String? verificationStatus;

  const AuthState({
    this.status = ApiStatus.initial,
    this.message = '',
    this.mobileANdEmailStatus = MobileANdEmailStatus.initial,
    this.verificationStatus,
  });

  AuthState copyWith({
    ApiStatus? status,
    String? message,
    bool clearMessage = false,
    MobileANdEmailStatus? mobileANdEmailStatus,
    String? verificationStatus,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: clearMessage ? '' : (message ?? this.message),
      mobileANdEmailStatus: mobileANdEmailStatus ?? this.mobileANdEmailStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  List<Object?> get props => [status, message, mobileANdEmailStatus, verificationStatus];
}
