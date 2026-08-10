import '../../../../../service/json_parser.dart';

class ProductAddonListItem {
  final int id;
  final int productVariantId;
  final int addonGroupId;
  final String productTitle;
  final String variantTitle;
  final String groupTitle;
  final int storesCount;
  final int itemsCount;
  final String updatedAt;

  ProductAddonListItem({
    required this.id,
    required this.productVariantId,
    required this.addonGroupId,
    required this.productTitle,
    required this.variantTitle,
    required this.groupTitle,
    required this.storesCount,
    required this.itemsCount,
    required this.updatedAt,
  });

  factory ProductAddonListItem.fromJson(Map<String, dynamic> json) {
    return ProductAddonListItem(
      id: JsonParser.intValue('id'),
      productVariantId: JsonParser.intValue('product_variant_id'),
      addonGroupId: JsonParser.intValue('addon_group_id'),
      productTitle: JsonParser.string('product_title'),
      variantTitle: JsonParser.string('variant_title'),
      groupTitle: JsonParser.string('group_title'),
      storesCount: JsonParser.intValue('stores_count'),
      itemsCount: JsonParser.intValue('items_count'),
      updatedAt: JsonParser.string('updated_at'),
    );
  }
}
