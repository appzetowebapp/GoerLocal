import 'package:equatable/equatable.dart';

abstract class ReturnOrderListEvent extends Equatable {
  const ReturnOrderListEvent();

  @override
  List<Object?> get props => [];
}

class FetchReturnOrders extends ReturnOrderListEvent {
  final bool forceRefresh;

  const FetchReturnOrders({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadMoreReturnOrders extends ReturnOrderListEvent {
  const LoadMoreReturnOrders();
}

class RefreshReturnOrders extends ReturnOrderListEvent {
  const RefreshReturnOrders();
}
