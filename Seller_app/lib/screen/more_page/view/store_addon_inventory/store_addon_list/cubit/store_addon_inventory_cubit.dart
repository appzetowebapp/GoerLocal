import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/json_parser.dart';
import '../../../../../products_page/product_addons/create_product_addons/models/lookup_models.dart';
import '../repo/store_addon_inventory_repo.dart';
import 'store_addon_inventory_state.dart';

class StoreAddonInventoryCubit extends Cubit<StoreAddonInventoryState> {
  final StoreAddonInventoryRepo _repo = StoreAddonInventoryRepo();

  StoreAddonInventoryCubit() : super(const StoreAddonInventoryState());

  Future<void> fetchInventory({bool isRefresh = false}) async {
    if (isRefresh) {
      emit(state.copyWith(status: ApiStatus.loading, items: [], currentPage: 1, hasMore: true));
    } else {
      if (!state.hasMore || state.status == ApiStatus.loadingMore) return;

      if (state.items.isEmpty) {
        emit(state.copyWith(status: ApiStatus.loading));
      } else {
        emit(state.copyWith(status: ApiStatus.loadingMore));
      }
    }

    try {
      final response = await _repo.getStoreAddonInventory(
        page: state.currentPage,
        search: state.searchQuery,
        storeId: state.selectedStoreId,
        addonGroupId: state.selectedGroupId,
      );

      if (response.success) {
        final newItems = isRefresh ? response.data.items : [...state.items, ...response.data.items];
        emit(
          state.copyWith(
            status: ApiStatus.success,
            items: newItems,
            total: response.data.total,
            currentPage: response.data.currentPage + 1,
            hasMore: response.data.currentPage < response.data.lastPage,
          ),
        );
      } else {
        emit(state.copyWith(status: ApiStatus.failure, message: response.message));
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }

  Future<void> fetchLookupData() async {
    try {
      final storesRes = await _repo.getLookupStores();
      final groupsRes = await _repo.getLookupAddonGroups();

      List<StoreLookup> stores = [];
      List<AddonGroupLookup> groups = [];

      if (storesRes['success'] == true) {
        stores = JsonParser.list<StoreLookup>(
          storesRes['data'],
          (json) => StoreLookup.fromJson(json as Map<String, dynamic>),
        );
      }

      if (groupsRes['success'] == true) {
        groups = JsonParser.list<AddonGroupLookup>(
          groupsRes['data'],
          (json) => AddonGroupLookup.fromJson(json as Map<String, dynamic>),
        );
      }

      emit(state.copyWith(lookupStores: stores, lookupAddonGroups: groups));
    } catch (e) {
      // Silent error for lookups or handle as needed
    }
  }

  void onFilterStoreChanged(int? id) => emit(state.copyWith(tempStoreId: id));
  void onFilterGroupChanged(int? id) => emit(state.copyWith(tempGroupId: id));

  void applyFilters() {
    emit(
      state.copyWith(
        selectedStoreId: state.tempStoreId,
        selectedGroupId: state.tempGroupId,
        currentPage: 1,
        hasMore: true,
      ),
    );
    fetchInventory(isRefresh: true);
  }

  void clearFilters() {
    emit(state.resetFilters());
    fetchInventory(isRefresh: true);
  }

  void syncTempFilters() {
    emit(state.copyWith(tempStoreId: state.selectedStoreId, tempGroupId: state.selectedGroupId));
  }

  void searchInventory(String query) {
    emit(state.copyWith(searchQuery: query, currentPage: 1, hasMore: true));
    fetchInventory(isRefresh: true);
  }

  void loadMore() {
    if (state.status != ApiStatus.loadingMore && state.hasMore) {
      fetchInventory();
    }
  }

  void reset() {
    emit(const StoreAddonInventoryState());
  }

  Future<void> deleteInventoryItem(int id) async {
    emit(state.copyWith(deleteStatus: ApiStatus.loading));
    try {
      final response = await _repo.deleteStoreAddonItem(id);
      if (response['success'] == true) {
        final updatedItems = state.items.where((item) => item.id != id).toList();
        emit(
          state.copyWith(
            deleteStatus: ApiStatus.success,
            deleteMessage: response['message'],
            items: updatedItems,
            total: state.total - 1,
          ),
        );
        // Reset status to initial so it doesn't trigger again
        emit(state.copyWith(deleteStatus: ApiStatus.initial));
      } else {
        emit(state.copyWith(deleteStatus: ApiStatus.failure, deleteMessage: response['message']));
      }
    } catch (e) {
      emit(state.copyWith(deleteStatus: ApiStatus.failure, deleteMessage: e.toString()));
    }
  }
}
