import '../../../../../service/json_parser.dart';

class ProductAddonsResponse {
  final bool success;
  final String message;
  final PaginatedProductAddons data;

  ProductAddonsResponse({required this.success, required this.message, required this.data});

  factory ProductAddonsResponse.fromJson(Map<String, dynamic> json) {
    return ProductAddonsResponse(
      success: JsonParser.boolValue(json['success']),
      message: JsonParser.string(json['message']),
      data: PaginatedProductAddons.fromJson(json['data'] ?? {}),
    );
  }
}

class PaginatedProductAddons {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<ProductAddon> data;

  PaginatedProductAddons({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory PaginatedProductAddons.fromJson(Map<String, dynamic> json) {
    return PaginatedProductAddons(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      data: JsonParser.list<ProductAddon>(json['data'], (v) => ProductAddon.fromJson(v as Map<String, dynamic>)),
    );
  }
}

class ProductAddon {
  final int id;
  final int productVariantId;
  final int addonGroupId;
  final String productTitle;
  final String variantTitle;
  final String groupTitle;
  final int storesCount;
  final int itemsCount;
  final DateTime? updatedAt;

  ProductAddon({
    required this.id,
    required this.productVariantId,
    required this.addonGroupId,
    required this.productTitle,
    required this.variantTitle,
    required this.groupTitle,
    required this.storesCount,
    required this.itemsCount,
    this.updatedAt,
  });

  factory ProductAddon.fromJson(Map<String, dynamic> json) {
    return ProductAddon(
      id: JsonParser.intValue(json['id']),
      productVariantId: JsonParser.intValue(json['product_variant_id']),
      addonGroupId: JsonParser.intValue(json['addon_group_id']),
      productTitle: JsonParser.string(json['product_title']),
      variantTitle: JsonParser.string(json['variant_title']),
      groupTitle: JsonParser.string(json['group_title']),
      storesCount: JsonParser.intValue(json['stores_count']),
      itemsCount: JsonParser.intValue(json['items_count']),
      updatedAt: JsonParser.dateTimeValue(json['updated_at']),
    );
  }
}
