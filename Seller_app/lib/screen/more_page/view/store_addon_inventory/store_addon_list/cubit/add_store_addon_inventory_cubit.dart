import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../config/api_routes.dart';
import '../../../../../../service/api_base_helper.dart';
import '../../../../../../screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import 'add_store_addon_inventory_state.dart';

class AddStoreAddonInventoryCubit extends Cubit<AddStoreAddonInventoryState> {
  final ApiBaseHelper _apiHelper = ApiBaseHelper();
  int? _editId;

  AddStoreAddonInventoryCubit() : super(const AddStoreAddonInventoryState());

  void init({int? editId}) {
    _editId = editId;
    fetchInitialLookups().then((_) {
      if (_editId != null) {
        fetchEditData();
      }
    });
  }

  Future<void> fetchInitialLookups() async {
    emit(state.copyWith(lookupStatus: ApiStatus.loading));
    try {
      final storesResponse = await _apiHelper.get(ApiRoutes.lookupStoresForInventoryApi);
      final groupsResponse = await _apiHelper.get(ApiRoutes.lookupAddonGroupsForInventoryApi);

      final stores = (storesResponse['data'] as List).map((e) => StoreLookup.fromJson(e)).toList();
      final groups = (groupsResponse['data'] as List).map((e) => AddonGroupLookup.fromJson(e)).toList();

      emit(
        state.copyWith(
          lookupStatus: ApiStatus.success,
          stores: stores,
          addonGroups: groups,
          // Add initial row if empty and not in edit mode
          itemRows: (state.itemRows.isEmpty && _editId == null)
              ? [InventoryItemRow(id: DateTime.now().millisecondsSinceEpoch.toString())]
              : null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(lookupStatus: ApiStatus.failure, message: e.toString()));
    }
  }

  Future<void> fetchEditData() async {
    if (_editId == null) return;
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      // Assuming there's a show API for single inventory item
      // Actually, we can get data from the list if needed, but a fresh fetch is better
      // Let's check if there is an API for show. I'll search in api_routes.dart
      final response = await _apiHelper.get("${ApiRoutes.stockInventoryListApi}/$_editId");
      final data = response['data'];

      if (data != null) {
        final store = state.stores.firstWhere(
          (s) => s.id == data['store_id'],
          orElse: () => StoreLookup(id: data['store_id'], name: data['store_name'] ?? 'Store'),
        );
        final group = state.addonGroups.firstWhere(
          (g) => g.id == data['addon_group_id'],
          orElse: () => AddonGroupLookup(id: data['addon_group_id'], title: data['addon_group_title'] ?? 'Group'),
        );

        // Fetch items for the group first
        final itemsResponse = await _apiHelper.get(ApiRoutes.lookupGroupItemsApi(group.id));
        final items = (itemsResponse['data'] as List).map((e) => AddonItemLookup.fromJson(e)).toList();

        final selectedItem = items.firstWhere(
          (i) => i.id == data['addon_item_id'],
          orElse: () =>
              AddonItemLookup(id: data['addon_item_id'], title: data['addon_item_title'] ?? 'Item', price: 0, cost: 0),
        );

        emit(
          state.copyWith(
            status: ApiStatus.initial,
            selectedStores: [store],
            itemRows: [
              InventoryItemRow(
                id: "edit_row",
                group: group,
                availableItems: items,
                selectedItem: selectedItem,
                price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
                cost: double.tryParse(data['cost']?.toString() ?? '0') ?? 0,
                stock: (data['stock'] as num?)?.toInt() ?? 0,
                isAvailable: data['is_available'] == true,
                existingInventoryId: _editId,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }

  void updateSelectedStores(List<StoreLookup> stores) {
    emit(state.copyWith(selectedStores: stores));
    // When store changes, we should re-fetch details for selected items in rows
    // Using the first selected store as a reference for existing state
    if (stores.isNotEmpty) {
      for (var row in state.itemRows) {
        if (row.selectedItem != null) {
          fetchItemState(row.id, row.selectedItem!.id);
        }
      }
    }
  }

  void addRow() {
    final newRows = List<InventoryItemRow>.from(state.itemRows);
    newRows.add(InventoryItemRow(id: DateTime.now().millisecondsSinceEpoch.toString()));
    emit(state.copyWith(itemRows: newRows));
  }

  void removeRow(String rowId) {
    if (state.itemRows.length <= 1) return; // Keep at least one row
    final newRows = state.itemRows.where((r) => r.id != rowId).toList();
    emit(state.copyWith(itemRows: newRows));
  }

  void updateRowGroup(String rowId, AddonGroupLookup? group) async {
    final rows = List<InventoryItemRow>.from(state.itemRows);
    final index = rows.indexWhere((r) => r.id == rowId);
    if (index == -1) return;

    if (group == null) {
      rows[index] = rows[index].copyWith(
        group: null,
        availableItems: [],
        selectedItem: null,
        price: 0,
        cost: 0,
        stock: 0,
      );
      emit(state.copyWith(itemRows: rows));
      return;
    }

    rows[index] = rows[index].copyWith(
      group: group,
      isLoadingState: true,
      selectedItem: null,
      availableItems: [], // Clear items immediately
      price: 0,
      cost: 0,
      stock: 0,
    );
    emit(state.copyWith(itemRows: rows));

    try {
      final response = await _apiHelper.get(ApiRoutes.lookupGroupItemsApi(group.id));
      final items = (response['data'] as List).map((e) => AddonItemLookup.fromJson(e)).toList();

      final updatedRows = List<InventoryItemRow>.from(state.itemRows);
      updatedRows[index] = updatedRows[index].copyWith(
        availableItems: items,
        isLoadingState: false,
        selectedItem: null,
      );
      emit(state.copyWith(itemRows: updatedRows));
    } catch (e) {
      final updatedRows = List<InventoryItemRow>.from(state.itemRows);
      updatedRows[index] = updatedRows[index].copyWith(isLoadingState: false);
      emit(state.copyWith(itemRows: updatedRows, message: e.toString()));
    }
  }

  void updateRowItem(String rowId, AddonItemLookup? item) {
    final rows = List<InventoryItemRow>.from(state.itemRows);
    final index = rows.indexWhere((r) => r.id == rowId);
    if (index == -1) return;

    if (item == null) {
      rows[index] = rows[index].copyWith(selectedItem: null, clearExistingId: true);
      emit(state.copyWith(itemRows: rows));
      return;
    }

    rows[index] = rows[index].copyWith(selectedItem: item, price: item.price, cost: item.cost);
    emit(state.copyWith(itemRows: rows));

    if (state.selectedStores.isNotEmpty) {
      fetchItemState(rowId, item.id);
    }
  }

  Future<void> fetchItemState(String rowId, int itemId) async {
    if (state.selectedStores.isEmpty) return;

    final rows = List<InventoryItemRow>.from(state.itemRows);
    final index = rows.indexWhere((r) => r.id == rowId);
    if (index == -1) return;

    rows[index] = rows[index].copyWith(isLoadingState: true);
    emit(state.copyWith(itemRows: rows));

    try {
      final response = await _apiHelper.get(ApiRoutes.lookupInventoryStateApi(state.selectedStores.first.id, itemId));
      final data = response['data'];

      final updatedRows = List<InventoryItemRow>.from(state.itemRows);
      if (data != null && data['exists'] == true) {
        updatedRows[index] = updatedRows[index].copyWith(
          price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
          cost: double.tryParse(data['cost']?.toString() ?? '0') ?? 0,
          stock: (data['stock'] as num?)?.toInt() ?? 0,
          isAvailable: data['is_available'] == true,
          existingInventoryId: (data['id'] as num?)?.toInt(),
          isLoadingState: false,
        );
      } else {
        updatedRows[index] = updatedRows[index].copyWith(isLoadingState: false, clearExistingId: true);
      }
      emit(state.copyWith(itemRows: updatedRows));
    } catch (e) {
      final updatedRows = List<InventoryItemRow>.from(state.itemRows);
      updatedRows[index] = updatedRows[index].copyWith(isLoadingState: false);
      emit(state.copyWith(itemRows: updatedRows));
    }
  }

  void updateRowFields(String rowId, {double? price, double? cost, int? stock, bool? isAvailable}) {
    final rows = List<InventoryItemRow>.from(state.itemRows);
    final index = rows.indexWhere((r) => r.id == rowId);
    if (index == -1) return;

    rows[index] = rows[index].copyWith(price: price, cost: cost, stock: stock, isAvailable: isAvailable);
    emit(state.copyWith(itemRows: rows));
  }

  Future<void> save() async {
    if (state.selectedStores.isEmpty) {
      emit(state.copyWith(message: "Please select at least one store"));
      return;
    }

    if (state.itemRows.any((r) => r.selectedItem == null)) {
      emit(state.copyWith(message: "Please select items for all rows"));
      return;
    }

    emit(state.copyWith(status: ApiStatus.loading));

    try {
      if (_editId != null) {
        // EDIT MODE: POST to /api/seller/store-addon-items/{id}
        final row = state.itemRows.first;
        final Map<String, dynamic> payload = {
          'store_id': state.selectedStores.first.id,
          'addon_item_id': row.selectedItem!.id,
          'price': row.price,
          'cost': row.cost,
          'stock': row.stock,
          'is_available': row.isAvailable,
        };

        final response = await _apiHelper.post(ApiRoutes.updateInventoryApi(_editId!), payload);
        if (response['success'] == true) {
          emit(
            state.copyWith(status: ApiStatus.success, message: response['message'] ?? "Inventory updated successfully"),
          );
        } else {
          emit(state.copyWith(status: ApiStatus.failure, message: response['message'] ?? "Failed to update inventory"));
        }
      } else {
        // ADD MODE: Bulk format
        final Map<String, dynamic> payload = {
          'store_ids': state.selectedStores.map((s) => s.id).toList(),
          'items': state.itemRows
              .map(
                (r) => {
                  'addon_item_id': r.selectedItem!.id,
                  'price': r.price,
                  'cost': r.cost,
                  'stock': r.stock,
                  'is_available': r.isAvailable,
                },
              )
              .toList(),
        };

        final response = await _apiHelper.post(ApiRoutes.bulkCreateInventoryApi, payload);

        if (response['success'] == true) {
          emit(
            state.copyWith(status: ApiStatus.success, message: response['message'] ?? "Inventory updated successfully"),
          );
        } else {
          emit(state.copyWith(status: ApiStatus.failure, message: response['message'] ?? "Failed to update inventory"));
        }
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }
}
