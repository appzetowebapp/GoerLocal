import 'package:equatable/equatable.dart';
import '../../../../../service/json_parser.dart';

class ProductLookup extends Equatable {
  final int id;
  final String title;
  final String type;
  final bool isVariant;
  final int variantsCount;

  const ProductLookup({
    required this.id,
    required this.title,
    required this.type,
    required this.isVariant,
    required this.variantsCount,
  });

  factory ProductLookup.fromJson(Map<String, dynamic> json) {
    return ProductLookup(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
      type: JsonParser.string(json['type']),
      isVariant: JsonParser.boolValue(json['is_variant']),
      variantsCount: JsonParser.intValue(json['variants_count']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class VariantLookup extends Equatable {
  final int id;
  final String title;
  final int productId;
  final String product;

  const VariantLookup({
    required this.id,
    required this.title,
    required this.productId,
    required this.product,
  });

  factory VariantLookup.fromJson(Map<String, dynamic> json) {
    return VariantLookup(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
      productId: JsonParser.intValue(json['product_id']),
      product: JsonParser.string(json['product']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class AddonGroupLookup extends Equatable {
  final int id;
  final String title;

  const AddonGroupLookup({required this.id, required this.title});

  factory AddonGroupLookup.fromJson(Map<String, dynamic> json) {
    return AddonGroupLookup(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class StoreLookup extends Equatable {
  final int id;
  final String name;

  const StoreLookup({required this.id, required this.name});

  factory StoreLookup.fromJson(Map<String, dynamic> json) {
    return StoreLookup(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
    );
  }

  @override
  List<Object?> get props => [id];
}
