import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../ui_models/UI_Models.dart';

class CreateAddonGroupState extends Equatable {
  final ApiStatus status;
  final AddonGroupFormData data;
  final String? message;

  const CreateAddonGroupState({
    this.status = ApiStatus.initial,
    this.data = const AddonGroupFormData(),
    this.message,
  });

  CreateAddonGroupState copyWith({
    ApiStatus? status,
    AddonGroupFormData? data,
    String? message,
    bool clearMessage = false,
  }) {
    return CreateAddonGroupState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, data, message];
}
