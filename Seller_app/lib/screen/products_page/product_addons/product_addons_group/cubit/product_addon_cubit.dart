import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/product_addons_group/cubit/product_addon_state.dart';

import 'package:hyper_local_seller/utils/debouncer.dart';

import '../../../../../service/api_base_helper.dart';
import '../model/product_addons_model.dart';
import '../repo/product_addon_repo.dart';

class ProductAddonCubit extends Cubit<ProductAddonState> {
  final ProductAddonRepo _repo;
  String? _searchQuery;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  ProductAddonCubit(this._repo) : super(const ProductAddonState()) {
    fetchProductAddon();
  }

  Future<void> fetchProductAddon({bool isRefresh = false}) async {
    if (isRefresh) {
      emit(state.copyWith(fetchStatus: ApiStatus.initial));
    }

    emit(state.copyWith(fetchStatus: ApiStatus.loading));

    try {
      final response = await _repo.getProductAddonGroups(page: 1, search: _searchQuery);

      final result = ProductAddonsResponse.fromJson(response);

      final data = result.data;

      if (result.success && data != null) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            productAddOns: data.data,
            currentPage: data.currentPage,
            lastPage: data.lastPage,
            total: data.total,
            hasMore: data.currentPage < data.lastPage,
          ),
        );
      } else {
        emit(state.copyWith(fetchStatus: ApiStatus.failure, message: result.message));
      }
    } catch (e) {
      emit(state.copyWith(fetchStatus: ApiStatus.failure, message: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state.fetchStatus == ApiStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(fetchStatus: ApiStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getProductAddonGroups(page: nextPage, search: _searchQuery);

      final result = ProductAddonsResponse.fromJson(response);
      final data = result.data;

      if (result.success && data != null) {
        final updatedList = List<ProductAddon>.from(state.productAddOns)..addAll(data.data);

        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            productAddOns: updatedList,
            currentPage: data.currentPage,
            lastPage: data.lastPage,
            total: data.total,
            hasMore: data.currentPage < data.lastPage,
          ),
        );
      } else {
        emit(state.copyWith(fetchStatus: ApiStatus.success, message: result.message));
      }
    } catch (e, stacktrace) {
      emit(state.copyWith(fetchStatus: ApiStatus.success, message: e.toString()));
    }
  }

  void searchProductAddon(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _debouncer.run(() {
      fetchProductAddon(isRefresh: true);
    });
  }

  void clearSearch() {
    _searchQuery = null;
    emit(state.copyWith(fetchStatus: ApiStatus.initial, productAddOns: []));
  }

  //
  void resetOperationStatus() {
    emit(state.copyWith(operationSuccess: null, operationMessage: null));
  }

  Future<void> deleteProductAddon({required int variantId,required int groupId}) async {
    emit(state.copyWith(operationSuccess: null, operationMessage: null));
    try {
      final response = await _repo.deleteProductAddonGroup(variantId: variantId,groupId: groupId);
      if (response['success'] == true) {
        emit(
          state.copyWith(
            operationSuccess: true,
            operationMessage: response['message'] ?? "Product Add-on deleted successfully",
          ),
        );
        fetchProductAddon(isRefresh: true);
      } else {
        emit(
          state.copyWith(
            operationSuccess: false,
            operationMessage: response['message'] ?? "Failed to delete add-on group",
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(operationSuccess: false, operationMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debouncer.dispose();
    return super.close();
  }
}
