import '../../../../../service/json_parser.dart';

class AddonMatrixResponse {
  final bool success;
  final String message;
  final List<AddonMatrix> matrices;

  AddonMatrixResponse({
    required this.success,
    required this.message,
    required this.matrices,
  });

  factory AddonMatrixResponse.fromJson(Map<String, dynamic> json) {
    return AddonMatrixResponse(
      success: JsonParser.boolValue(json['success']),
      message: JsonParser.string(json['message']),
      matrices: JsonParser.list<AddonMatrix>(
        json['data']?['matrices'],
        (m) => AddonMatrix.fromJson(m as Map<String, dynamic>),
      ),
    );
  }
}

class AddonMatrix {
  final MatrixIdTitle variant;
  final MatrixIdTitle group;
  final List<MatrixIdTitle> stores;
  final List<MatrixItem> items;
  final List<MatrixExisting> existing;
  final List<MatrixInventory> inventory;

  AddonMatrix({
    required this.variant,
    required this.group,
    required this.stores,
    required this.items,
    required this.existing,
    required this.inventory,
  });

  factory AddonMatrix.fromJson(Map<String, dynamic> json) {
    return AddonMatrix(
      variant: MatrixIdTitle.fromJson(json['variant']),
      group: MatrixIdTitle.fromJson(json['group']),
      stores: JsonParser.list<MatrixIdTitle>(
        json['stores'],
        (s) => MatrixIdTitle.fromJson(s as Map<String, dynamic>),
      ),
      items: JsonParser.list<MatrixItem>(
        json['items'],
        (i) => MatrixItem.fromJson(i as Map<String, dynamic>),
      ),
      existing: JsonParser.list<MatrixExisting>(
        json['existing'],
        (e) => MatrixExisting.fromJson(e as Map<String, dynamic>),
      ),
      inventory: JsonParser.list<MatrixInventory>(
        json['inventory'],
        (i) => MatrixInventory.fromJson(i as Map<String, dynamic>),
      ),
    );
  }

  // Unique key for the variant-group pair
  String get pairKey => "${variant.id}_${group.id}";
}

class MatrixIdTitle {
  final int id;
  final String title;

  MatrixIdTitle({required this.id, required this.title});

  factory MatrixIdTitle.fromJson(Map<String, dynamic> json) {
    return MatrixIdTitle(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title'] ?? json['name']),
    );
  }
}

class MatrixItem {
  final int id;
  final String title;
  final double price;
  final double cost;

  MatrixItem({
    required this.id,
    required this.title,
    required this.price,
    required this.cost,
  });

  factory MatrixItem.fromJson(Map<String, dynamic> json) {
    return MatrixItem(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
      price: JsonParser.doubleValue(json['price']),
      cost: JsonParser.doubleValue(json['cost']),
    );
  }
}

class MatrixExisting {
  final int storeId;
  final int addonItemId;

  MatrixExisting({required this.storeId, required this.addonItemId});

  factory MatrixExisting.fromJson(Map<String, dynamic> json) {
    return MatrixExisting(
      storeId: JsonParser.intValue(json['store_id']),
      addonItemId: JsonParser.intValue(json['addon_item_id']),
    );
  }
}

class MatrixInventory {
  final int storeId;
  final int addonItemId;
  final double price;
  final double cost;
  final int stock;
  final bool isAvailable;

  MatrixInventory({
    required this.storeId,
    required this.addonItemId,
    required this.price,
    required this.cost,
    required this.stock,
    required this.isAvailable,
  });

  factory MatrixInventory.fromJson(Map<String, dynamic> json) {
    return MatrixInventory(
      storeId: JsonParser.intValue(json['store_id']),
      addonItemId: JsonParser.intValue(json['addon_item_id']),
      price: JsonParser.doubleValue(json['price']),
      cost: JsonParser.doubleValue(json['cost']),
      stock: JsonParser.intValue(json['stock']),
      isAvailable: JsonParser.boolValue(json['is_available']),
    );
  }
}
