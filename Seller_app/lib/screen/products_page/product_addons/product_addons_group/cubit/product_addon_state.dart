import 'package:equatable/equatable.dart';

import '../../../../../service/api_base_helper.dart';
import '../model/product_addons_model.dart';

class ProductAddonState extends Equatable {
  final ApiStatus fetchStatus;
  final List<ProductAddon> productAddOns;
  final int currentPage;
  final int lastPage;
  final int total;
  final String message;
  final bool hasMore;
  final bool? operationSuccess;
  final String? operationMessage;

  const ProductAddonState({
    this.fetchStatus = ApiStatus.initial,
    this.productAddOns = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message = '',
    this.hasMore = true,
    this.operationSuccess,
    this.operationMessage,
  });

  ProductAddonState copyWith({
    ApiStatus? fetchStatus,
    List<ProductAddon>? productAddOns,
    int? currentPage,
    int? lastPage,
    int? total,
    String? message,
    bool? hasMore,
    bool? operationSuccess,
    String? operationMessage,
    bool clearMessage = false,
  }) {
    return ProductAddonState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      productAddOns: productAddOns ?? this.productAddOns,
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
    productAddOns,
    currentPage,
    lastPage,
    total,
    message,
    hasMore,
    operationSuccess,
    operationMessage,
  ];
}
