import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../../product_addons_group/model/product_addons_model.dart';
import '../models/lookup_models.dart';
import '../models/matrix_model.dart';
import 'create_product_addons_state.dart';

class CreateProductAddonsCubit extends Cubit<CreateProductAddonsState> {
  CreateProductAddonsCubit() : super(CreateProductAddonsState());
  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  void initEdit(ProductAddon model) {
    emit(
      state.copyWith(
        editModel: model,
        selectedVariants: [
          VariantLookup(
            id: model.productVariantId,
            title: model.variantTitle,
            productId: 0,
            product: model.productTitle,
          ),
        ],
        selectedAddonGroups: [
          AddonGroupLookup(id: model.addonGroupId, title: model.groupTitle),
        ],
      ),
    );
    fetchMatrix();
  }

  Future<void> searchProducts(String query) async {
    emit(
      state.copyWith(
        isProductsLoading: true,
        productsPage: 1,
        productsHasMore: true,
        productsSearchQuery: query,
      ),
    );
    try {
      final response = await _apiHelper.get(
        ApiRoutes.lookupProductsApi,
        queryParameters: {'search': query, 'page': 1, 'limit': 15},
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final products = data.map((e) => ProductLookup.fromJson(e)).toList();
      emit(
        state.copyWith(
          products: products,
          isProductsLoading: false,
          productsHasMore: products.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isProductsLoading: false));
    }
  }

  Future<void> loadMoreProducts() async {
    if (state.isProductsLoadingMore || !state.productsHasMore) return;

    emit(state.copyWith(isProductsLoadingMore: true));
    try {
      final nextPage = state.productsPage + 1;
      final response = await _apiHelper.get(
        ApiRoutes.lookupProductsApi,
        queryParameters: {
          'search': state.productsSearchQuery,
          'page': nextPage,
          'limit': 15,
        },
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final newProducts = data.map((e) => ProductLookup.fromJson(e)).toList();

      emit(
        state.copyWith(
          products: [...state.products, ...newProducts],
          productsPage: nextPage,
          isProductsLoadingMore: false,
          productsHasMore: newProducts.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isProductsLoadingMore: false));
    }
  }

  void selectProducts(List<ProductLookup> products) {
    emit(
      state.copyWith(
        selectedProducts: products,
        selectedVariants: [],
        matrices: [],
        selections: {},
      ),
    ); // Clear everything on product change
    if (products.isNotEmpty) {
      fetchVariants(products.map((e) => e.id).toList());
    } else {
      emit(state.copyWith(variants: []));
    }
  }

  Future<void> fetchVariants(List<int> productIds) async {
    if (productIds.isEmpty) {
      emit(state.copyWith(variants: []));
      return;
    }
    emit(state.copyWith(isVariantsLoading: true));
    try {
      final response = await _apiHelper.get(
        ApiRoutes.lookupVariantsBulkApi,
        queryParameters: {'product_ids': productIds.join(',')},
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final variants = data.map((e) => VariantLookup.fromJson(e)).toList();
      emit(state.copyWith(variants: variants, isVariantsLoading: false));
    } catch (e) {
      emit(state.copyWith(isVariantsLoading: false));
    }
  }

  void selectVariants(List<VariantLookup> variants) {
    emit(
      state.copyWith(selectedVariants: variants, matrices: [], selections: {}),
    );
    fetchMatrix();
  }

  Future<void> searchAddonGroups(String query) async {
    emit(
      state.copyWith(
        isAddonGroupsLoading: true,
        addonGroupsPage: 1,
        addonGroupsHasMore: true,
        addonGroupsSearchQuery: query,
      ),
    );
    try {
      final response = await _apiHelper.get(
        ApiRoutes.lookupAddonGroupsApi,
        queryParameters: {'search': query, 'page': 1, 'limit': 15},
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final groups = data.map((e) => AddonGroupLookup.fromJson(e)).toList();
      emit(
        state.copyWith(
          addonGroups: groups,
          isAddonGroupsLoading: false,
          addonGroupsHasMore: groups.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isAddonGroupsLoading: false));
    }
  }

  Future<void> loadMoreAddonGroups() async {
    if (state.isAddonGroupsLoadingMore || !state.addonGroupsHasMore) return;

    emit(state.copyWith(isAddonGroupsLoadingMore: true));
    try {
      final nextPage = state.addonGroupsPage + 1;
      final response = await _apiHelper.get(
        ApiRoutes.lookupAddonGroupsApi,
        queryParameters: {
          'search': state.addonGroupsSearchQuery,
          'page': nextPage,
          'limit': 15,
        },
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final newGroups = data.map((e) => AddonGroupLookup.fromJson(e)).toList();

      emit(
        state.copyWith(
          addonGroups: [...state.addonGroups, ...newGroups],
          addonGroupsPage: nextPage,
          isAddonGroupsLoadingMore: false,
          addonGroupsHasMore: newGroups.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isAddonGroupsLoadingMore: false));
    }
  }

  void selectAddonGroups(List<AddonGroupLookup> groups) {
    emit(
      state.copyWith(selectedAddonGroups: groups, matrices: [], selections: {}),
    );
    fetchMatrix();
  }

  Future<void> fetchMatrix() async {
    if (state.selectedVariants.isEmpty || state.selectedAddonGroups.isEmpty) {
      emit(state.copyWith(matrices: [], selections: {}));
      return;
    }

    emit(state.copyWith(status: ApiStatus.loading));

    final List<Map<String, int>> pairs = [];
    for (var v in state.selectedVariants) {
      for (var g in state.selectedAddonGroups) {
        pairs.add({'variant_id': v.id, 'group_id': g.id});
      }
    }

    try {
      final response = await _apiHelper.post(ApiRoutes.showProductAddonApi, {
        'pairs': pairs,
      });

      final matrixResponse = AddonMatrixResponse.fromJson(response);

      // Initialize selections
      final Map<String, List<int>> selections = {};
      for (var matrix in matrixResponse.matrices) {
        for (var store in matrix.stores) {
          final key = "${matrix.pairKey}_${store.id}";

          if (state.editModel != null) {
            // Pre-fill existing configurations in Edit mode
            final List<int> itemIds = matrix.existing
                .where((e) => e.storeId == store.id)
                .map((e) => e.addonItemId)
                .toList();
            selections[key] = itemIds;
          } else {
            // Clean slate for Create mode
            selections[key] = [];
          }
        }
      }

      emit(
        state.copyWith(
          status: ApiStatus.success,
          matrices: matrixResponse.matrices,
          selections: selections,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }

  void toggleItemSelection(String selectionKey, int itemId) {
    final currentSelections = Map<String, List<int>>.from(state.selections);
    final selectedItems = List<int>.from(currentSelections[selectionKey] ?? []);

    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }

    currentSelections[selectionKey] = selectedItems;
    emit(state.copyWith(selections: currentSelections));
  }

  void toggleStoreSelection(AddonMatrix matrix, int storeId, bool enable) {
    final key = "${matrix.pairKey}_$storeId";
    final currentSelections = Map<String, List<int>>.from(state.selections);

    if (enable) {
      // Select all items in this group for this store if enabling
      currentSelections[key] = matrix.items.map((e) => e.id).toList();
    } else {
      // Clear selections for this store
      currentSelections[key] = [];
    }
    emit(state.copyWith(selections: currentSelections));
  }

  Future<void> saveAttachments() async {
    if (state.matrices.isEmpty) return;

    emit(state.copyWith(status: ApiStatus.loading));

    final List<Map<String, dynamic>> attachments = [];

    for (var matrix in state.matrices) {
      final List<Map<String, dynamic>> stores = [];

      for (var store in matrix.stores) {
        final selectionKey = "${matrix.pairKey}_${store.id}";
        final selectedItemIds = state.selections[selectionKey] ?? [];

        final Map<String, dynamic> storeData = {'store_id': store.id};

        if (selectedItemIds.isNotEmpty) {
          storeData['apply'] = true;
          storeData['items'] = selectedItemIds
              .map((id) => {'addon_item_id': id})
              .toList();
        }

        stores.add(storeData);
      }

      attachments.add({
        'product_variant_id': matrix.variant.id,
        'addon_group_id': matrix.group.id,
        'stores': stores,
      });
    }

    try {
      final response = await _apiHelper.post(
        state.editModel != null
            ? ApiRoutes.updateProductAddonApi(
                state.editModel!.productVariantId,
                state.editModel!.addonGroupId,
              )
            : ApiRoutes.productAddOneListApi,
        state.editModel != null
            ? attachments.first
            : {'attachments': attachments},
      );

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: response['message'] ?? "Addons attached successfully",
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failure,
            message: response['message'] ?? "Failed to attach addons",
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }

  void resetStatus() {
    emit(state.copyWith(status: ApiStatus.initial));
  }
}
