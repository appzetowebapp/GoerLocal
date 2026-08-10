import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../../../../../products_page/product_addons/create_product_addons/models/lookup_models.dart';
import '../model/store_addon_inventory_model.dart';

class StoreAddonInventoryState extends Equatable {
  final ApiStatus status;
  final List<StoreAddonItem> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  final String? message;
  final String searchQuery;
  final List<StoreLookup> lookupStores;
  final List<AddonGroupLookup> lookupAddonGroups;
  final int? selectedStoreId;
  final int? selectedGroupId;
  final int? tempStoreId;
  final int? tempGroupId;

  final ApiStatus deleteStatus;
  final String? deleteMessage;

  const StoreAddonInventoryState({
    this.status = ApiStatus.initial,
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.message,
    this.searchQuery = '',
    this.deleteStatus = ApiStatus.initial,
    this.deleteMessage,
    this.lookupStores = const [],
    this.lookupAddonGroups = const [],
    this.selectedStoreId,
    this.selectedGroupId,
    this.tempStoreId,
    this.tempGroupId,
  });

  StoreAddonInventoryState copyWith({
    ApiStatus? status,
    List<StoreAddonItem>? items,
    int? total,
    int? currentPage,
    bool? hasMore,
    String? message,
    String? searchQuery,
    ApiStatus? deleteStatus,
    String? deleteMessage,
    List<StoreLookup>? lookupStores,
    List<AddonGroupLookup>? lookupAddonGroups,
    int? selectedStoreId,
    int? selectedGroupId,
    int? tempStoreId,
    int? tempGroupId,
  }) {
    return StoreAddonInventoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      message: message ?? this.message,
      searchQuery: searchQuery ?? this.searchQuery,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      deleteMessage: deleteMessage ?? this.deleteMessage,
      lookupStores: lookupStores ?? this.lookupStores,
      lookupAddonGroups: lookupAddonGroups ?? this.lookupAddonGroups,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      tempStoreId: tempStoreId ?? this.tempStoreId,
      tempGroupId: tempGroupId ?? this.tempGroupId,
    );
  }

  StoreAddonInventoryState resetFilters() {
    return StoreAddonInventoryState(
      status: status,
      items: items,
      total: total,
      currentPage: 1,
      hasMore: true,
      message: message,
      searchQuery: searchQuery,
      deleteStatus: deleteStatus,
      deleteMessage: deleteMessage,
      lookupStores: lookupStores,
      lookupAddonGroups: lookupAddonGroups,
      selectedStoreId: null,
      selectedGroupId: null,
      tempStoreId: null,
      tempGroupId: null,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    total,
    currentPage,
    hasMore,
    message,
    searchQuery,
    deleteStatus,
    deleteMessage,
    lookupStores,
    lookupAddonGroups,
    selectedStoreId,
    selectedGroupId,
    tempStoreId,
    tempGroupId,
  ];
}
