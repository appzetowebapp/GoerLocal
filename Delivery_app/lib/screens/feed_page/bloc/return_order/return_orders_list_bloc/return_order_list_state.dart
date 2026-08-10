import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../model/return_orders_list_model.dart';

class ReturnOrderListState extends Equatable {
  final ApiStatus status;
  final List<Pickups> orders;
  final bool hasReachedMax;
  final String message;
  final bool isRefreshing;

  const ReturnOrderListState({
    this.status = ApiStatus.initial,
    this.orders = const [],
    this.hasReachedMax = false,
    this.message = "",
    this.isRefreshing = false,
  });

  ReturnOrderListState copyWith({
    ApiStatus? status,
    List<Pickups>? orders,
    bool? hasReachedMax,
    String? message,
    bool? isRefreshing,
  }) {
    return ReturnOrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      message: message ?? this.message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    hasReachedMax,
    message,
    isRefreshing,
  ];
}
