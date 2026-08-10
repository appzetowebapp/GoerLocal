import '../../../../../service/api_base_helper.dart';
import '../../product_addons_group/model/product_addons_model.dart';
import '../models/lookup_models.dart';
import '../models/matrix_model.dart';

class CreateProductAddonsState {
  final ApiStatus status;
  final String? message;
  final ProductAddon? editModel;

  // Data for selection
  final List<ProductLookup> products;
  final List<VariantLookup> variants;
  final List<AddonGroupLookup> addonGroups;

  // Selected data
  final List<ProductLookup> selectedProducts;
  final List<VariantLookup> selectedVariants;
  final List<AddonGroupLookup> selectedAddonGroups;

  // Matrices data
  final List<AddonMatrix> matrices;
  // Key: pairKey_storeId, Value: List of addon item IDs
  final Map<String, List<int>> selections;

  // Loading states for lookups
  final bool isProductsLoading;
  final bool isVariantsLoading;
  final bool isAddonGroupsLoading;

  // Pagination for Products
  final int productsPage;
  final bool productsHasMore;
  final bool isProductsLoadingMore;

  // Pagination for Add-on Groups
  final int addonGroupsPage;
  final bool addonGroupsHasMore;
  final bool isAddonGroupsLoadingMore;

  CreateProductAddonsState({
    this.status = ApiStatus.initial,
    this.message,
    this.editModel,
    this.products = const [],
    this.variants = const [],
    this.addonGroups = const [],
    this.selectedProducts = const [],
    this.selectedVariants = const [],
    this.selectedAddonGroups = const [],
    this.isProductsLoading = false,
    this.isVariantsLoading = false,
    this.isAddonGroupsLoading = false,
    this.matrices = const [],
    this.selections = const {},
    this.productsPage = 1,
    this.productsHasMore = true,
    this.isProductsLoadingMore = false,
    this.productsSearchQuery = '',
    this.addonGroupsPage = 1,
    this.addonGroupsHasMore = true,
    this.isAddonGroupsLoadingMore = false,
    this.addonGroupsSearchQuery = '',
  });

  final String productsSearchQuery;
  final String addonGroupsSearchQuery;

  CreateProductAddonsState copyWith({
    ApiStatus? status,
    String? message,
    ProductAddon? editModel,
    List<ProductLookup>? products,
    List<VariantLookup>? variants,
    List<AddonGroupLookup>? addonGroups,
    List<ProductLookup>? selectedProducts,
    List<VariantLookup>? selectedVariants,
    List<AddonGroupLookup>? selectedAddonGroups,
    bool? isProductsLoading,
    bool? isVariantsLoading,
    bool? isAddonGroupsLoading,
    List<AddonMatrix>? matrices,
    Map<String, List<int>>? selections,
    int? productsPage,
    bool? productsHasMore,
    bool? isProductsLoadingMore,
    String? productsSearchQuery,
    int? addonGroupsPage,
    bool? addonGroupsHasMore,
    bool? isAddonGroupsLoadingMore,
    String? addonGroupsSearchQuery,
  }) {
    return CreateProductAddonsState(
      status: status ?? this.status,
      message: message ?? this.message,
      editModel: editModel ?? this.editModel,
      products: products ?? this.products,
      variants: variants ?? this.variants,
      addonGroups: addonGroups ?? this.addonGroups,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      selectedVariants: selectedVariants ?? this.selectedVariants,
      selectedAddonGroups: selectedAddonGroups ?? this.selectedAddonGroups,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
      isVariantsLoading: isVariantsLoading ?? this.isVariantsLoading,
      isAddonGroupsLoading: isAddonGroupsLoading ?? this.isAddonGroupsLoading,
      matrices: matrices ?? this.matrices,
      selections: selections ?? this.selections,
      productsPage: productsPage ?? this.productsPage,
      productsHasMore: productsHasMore ?? this.productsHasMore,
      isProductsLoadingMore: isProductsLoadingMore ?? this.isProductsLoadingMore,
      productsSearchQuery: productsSearchQuery ?? this.productsSearchQuery,
      addonGroupsPage: addonGroupsPage ?? this.addonGroupsPage,
      addonGroupsHasMore: addonGroupsHasMore ?? this.addonGroupsHasMore,
      isAddonGroupsLoadingMore: isAddonGroupsLoadingMore ?? this.isAddonGroupsLoadingMore,
      addonGroupsSearchQuery: addonGroupsSearchQuery ?? this.addonGroupsSearchQuery,
    );
  }
}
