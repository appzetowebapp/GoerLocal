import 'package:equatable/equatable.dart';
import '../../../../../../service/api_base_helper.dart';
import '../../../../../../screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';

class AddStoreAddonInventoryState extends Equatable {
  final ApiStatus status;
  final ApiStatus lookupStatus;
  final String? message;
  
  // Lookups
  final List<StoreLookup> stores;
  final List<AddonGroupLookup> addonGroups;
  
  // Selections
  final List<StoreLookup> selectedStores;
  final List<InventoryItemRow> itemRows;

  const AddStoreAddonInventoryState({
    this.status = ApiStatus.initial,
    this.lookupStatus = ApiStatus.initial,
    this.message,
    this.stores = const [],
    this.addonGroups = const [],
    this.selectedStores = const [],
    this.itemRows = const [],
  });

  AddStoreAddonInventoryState copyWith({
    ApiStatus? status,
    ApiStatus? lookupStatus,
    String? message,
    List<StoreLookup>? stores,
    List<AddonGroupLookup>? addonGroups,
    List<StoreLookup>? selectedStores,
    List<InventoryItemRow>? itemRows,
    bool clearSelectedStores = false,
  }) {
    return AddStoreAddonInventoryState(
      status: status ?? this.status,
      lookupStatus: lookupStatus ?? this.lookupStatus,
      message: message,
      stores: stores ?? this.stores,
      addonGroups: addonGroups ?? this.addonGroups,
      selectedStores: clearSelectedStores ? const [] : (selectedStores ?? this.selectedStores),
      itemRows: itemRows ?? this.itemRows,
    );
  }

  @override
  List<Object?> get props => [status, lookupStatus, message, stores, addonGroups, selectedStores, itemRows];
}

class InventoryItemRow extends Equatable {
  final String id; // Local unique ID for the row
  final AddonGroupLookup? group;
  final List<AddonItemLookup> availableItems;
  final AddonItemLookup? selectedItem;
  final double price;
  final double cost;
  final int stock;
  final bool isAvailable;
  final bool isLoadingState;
  final int? existingInventoryId; // If editing an existing record

  const InventoryItemRow({
    required this.id,
    this.group,
    this.availableItems = const [],
    this.selectedItem,
    this.price = 0,
    this.cost = 0,
    this.stock = 0,
    this.isAvailable = true,
    this.isLoadingState = false,
    this.existingInventoryId,
  });

  InventoryItemRow copyWith({
    AddonGroupLookup? group,
    List<AddonItemLookup>? availableItems,
    AddonItemLookup? selectedItem,
    double? price,
    double? cost,
    int? stock,
    bool? isAvailable,
    bool? isLoadingState,
    int? existingInventoryId,
    bool clearExistingId = false,
  }) {
    return InventoryItemRow(
      id: id,
      group: group ?? this.group,
      availableItems: availableItems ?? this.availableItems,
      selectedItem: selectedItem ?? this.selectedItem,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      isLoadingState: isLoadingState ?? this.isLoadingState,
      existingInventoryId: clearExistingId ? null : (existingInventoryId ?? this.existingInventoryId),
    );
  }

  @override
  List<Object?> get props => [id, group, availableItems, selectedItem, price, cost, stock, isAvailable, isLoadingState, existingInventoryId];
}

class AddonItemLookup {
  final int id;
  final String title;
  final double price;
  final double cost;

  AddonItemLookup({required this.id, required this.title, required this.price, required this.cost});

  factory AddonItemLookup.fromJson(Map<String, dynamic> json) {
    return AddonItemLookup(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      cost: double.tryParse(json['cost']?.toString() ?? '0') ?? 0,
    );
  }
}
