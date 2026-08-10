import 'package:equatable/equatable.dart';

import '../../../../../service/api_base_helper.dart';
import '../model/addon_group_model.dart';

class AddonGroupsState extends Equatable {
  final ApiStatus fetchStatus;
  final List<AddonGroup> addonGroups;
  final int currentPage;
  final int lastPage;
  final int total;
  final String message;
  final bool hasMore;
  final bool? operationSuccess;
  final String? operationMessage;

  const AddonGroupsState({
    this.fetchStatus = ApiStatus.initial,
    this.addonGroups = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message = '',
    this.hasMore = true,
    this.operationSuccess,
    this.operationMessage,
  });

  AddonGroupsState copyWith({
    ApiStatus? fetchStatus,
    List<AddonGroup>? addonGroups,
    int? currentPage,
    int? lastPage,
    int? total,
    String? message,
    bool? hasMore,
    bool? operationSuccess,
    String? operationMessage,
    bool clearMessage = false,
  }) {
    return AddonGroupsState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      addonGroups: addonGroups ?? this.addonGroups,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      message: clearMessage ? '' : (message ?? this.message),
      operationSuccess: operationSuccess,
      operationMessage: operationMessage ?? this.operationMessage,
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    addonGroups,
    currentPage,
    lastPage,
    total,
    message,
    hasMore,
    operationSuccess,
    operationMessage,
  ];
}
