import 'package:equatable/equatable.dart';

import '../../../../../service/json_parser.dart';

class AddonGroupFormData extends Equatable {
  final int? id;
  final String title;
  final String selectionType;
  final bool isRequired;
  final int sortOrder;
  final String status;
  final List<AddonItemFormData> items;

  const AddonGroupFormData({
    this.id,
    this.title = '',
    this.selectionType = 'single',
    this.isRequired = false,
    this.sortOrder = 0,
    this.status = 'active',
    this.items = const [],
  });

  factory AddonGroupFormData.fromJson(Map<String, dynamic> json) {
    return AddonGroupFormData(
      id: json['id'] != null ? JsonParser.intValue(json['id']) : null,
      title: JsonParser.string(json['title'] ?? ''),
      selectionType: JsonParser.string(json['selection_type'] ?? 'single'),
      isRequired: JsonParser.boolValue(json['is_required'] ?? false),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
      status: JsonParser.string(json['status'] ?? 'active'),
      items: JsonParser.list<AddonItemFormData>(
        json['items'],
        (v) => AddonItemFormData.fromJson(v as Map<String, dynamic>),
      ),
    );
  }
  AddonGroupFormData copyWith({
    int? id,
    String? title,
    String? selectionType,
    bool? isRequired,
    int? sortOrder,
    String? status,
    List<AddonItemFormData>? items,
  }) {
    return AddonGroupFormData(
      id: id ?? this.id,
      title: title ?? this.title,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'selection_type': selectionType,
      'is_required': isRequired,
      'sort_order': sortOrder,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, title, selectionType, isRequired, sortOrder, status, items];
}

class AddonItemFormData extends Equatable {
  final int? id;
  final String title;
  final double price;
  final double? cost;
  final String? indicator;
  final bool isAvailable;
  final int sortOrder;
  final String status;

  const AddonItemFormData({
    this.id,
    this.title = '',
    this.price = 0.0,
    this.cost,
    this.indicator,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.status = 'active',
  });

  factory AddonItemFormData.fromJson(Map<String, dynamic> json) {
    return AddonItemFormData(
      id: json['id'] != null ? JsonParser.intValue(json['id']) : null,
      title: JsonParser.string(json['title'] ?? ''),
      price: JsonParser.doubleValue(json['price'] ?? 0.0),
      cost: json['cost'] != null ? JsonParser.doubleValue(json['cost']) : null,
      indicator: json['indicator']?.toString(),
      isAvailable: JsonParser.boolValue(json['is_available'] ?? true),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
      status: JsonParser.string(json['status'] ?? 'active'),
    );
  }
  AddonItemFormData copyWith({
    int? id,
    String? title,
    double? price,
    double? cost,
    String? indicator,
    bool? isAvailable,
    int? sortOrder,
    String? status,
  }) {
    return AddonItemFormData(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      indicator: indicator ?? this.indicator,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      if (cost != null) 'cost': cost,
      'indicator': indicator,
      'is_available': isAvailable,
      'sort_order': sortOrder,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, title, price, cost, indicator, isAvailable, sortOrder, status];
}
