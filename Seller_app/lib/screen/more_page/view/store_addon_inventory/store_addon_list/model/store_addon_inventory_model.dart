import '../../../../../../service/json_parser.dart';

class StoreAddonInventoryResponse {
  final bool success;
  final String message;
  final StoreAddonInventoryData data;

  StoreAddonInventoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory StoreAddonInventoryResponse.fromJson(Map<String, dynamic> json) {
    return StoreAddonInventoryResponse(
      success: JsonParser.boolValue(json['success']),
      message: JsonParser.string(json['message']),
      data: StoreAddonInventoryData.fromJson(json['data'] ?? {}),
    );
  }
}

class StoreAddonInventoryData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<StoreAddonItem> items;

  StoreAddonInventoryData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.items,
  });

  factory StoreAddonInventoryData.fromJson(Map<String, dynamic> json) {
    return StoreAddonInventoryData(
      currentPage: JsonParser.intValue(json['current_page'], fallback: 1),
      lastPage: JsonParser.intValue(json['last_page'], fallback: 1),
      perPage: JsonParser.intValue(json['per_page'], fallback: 15),
      total: JsonParser.intValue(json['total']),
      items: JsonParser.list<StoreAddonItem>(
        json['data'],
        (i) => StoreAddonItem.fromJson(i as Map<String, dynamic>),
      ),
    );
  }
}

class StoreAddonItem {
  final int id;
  final String uuid;
  final int storeId;
  final String storeName;
  final int addonItemId;
  final String addonItemTitle;
  final int addonGroupId;
  final String addonGroupTitle;
  final double price;
  final double? cost;
  final int stock;
  final bool isAvailable;
  final String? createdAt;
  final String? updatedAt;

  StoreAddonItem({
    required this.id,
    required this.uuid,
    required this.storeId,
    required this.storeName,
    required this.addonItemId,
    required this.addonItemTitle,
    required this.addonGroupId,
    required this.addonGroupTitle,
    required this.price,
    this.cost,
    required this.stock,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreAddonItem.fromJson(Map<String, dynamic> json) {
    return StoreAddonItem(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      storeId: JsonParser.intValue(json['store_id']),
      storeName: JsonParser.string(json['store_name']),
      addonItemId: JsonParser.intValue(json['addon_item_id']),
      addonItemTitle: JsonParser.string(json['addon_item_title']),
      addonGroupId: JsonParser.intValue(json['addon_group_id']),
      addonGroupTitle: JsonParser.string(json['addon_group_title']),
      price: JsonParser.doubleValue(json['price']),
      cost: json['cost'] != null ? JsonParser.doubleValue(json['cost']) : null,
      stock: JsonParser.intValue(json['stock']),
      isAvailable: JsonParser.boolValue(json['is_available']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }
}
