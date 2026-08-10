// ignore_for_file: deprecated_member_use

import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'addon_group_model';

class AddonGroupResponse extends Equatable {
  final bool success;
  final String message;
  final AddonGroupData? data;

  const AddonGroupResponse({
    this.success = false,
    this.message = '',
    this.data,
  });

  factory AddonGroupResponse.fromJson(Map<String, dynamic> json) {
    return AddonGroupResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null ? AddonGroupData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['success'] = success;
    result['message'] = message;
    if (data != null) {
      result['data'] = data!.toJson();
    }
    return result;
  }

  @override
  List<Object?> get props => [success, message, data];
}

class AddonGroupData extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<AddonGroup> data;

  const AddonGroupData({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 15,
    this.total = 0,
    this.data = const [],
  });

  factory AddonGroupData.fromJson(Map<String, dynamic> json) {
    return AddonGroupData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      data: JsonParser.list<AddonGroup>(
        json['data'],
        (v) => AddonGroup.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['current_page'] = currentPage;
    result['last_page'] = lastPage;
    result['per_page'] = perPage;
    result['total'] = total;
    result['data'] = data.map((v) => v.toJson()).toList();
    return result;
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total, data];
}

class AddonGroup extends Equatable {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final String selectionType;
  final bool isRequired;
  final int sortOrder;
  final String status;
  final int itemsCount;
  final List<AddonItem> items;
  final String createdAt; // Placeholder property based on UI request

  const AddonGroup({
    this.id = 0,
    this.uuid = '',
    this.title = '',
    this.slug = '',
    this.selectionType = 'single',
    this.isRequired = false,
    this.sortOrder = 0,
    this.status = 'inactive',
    this.itemsCount = 0,
    this.items = const [],
    this.createdAt = '',
  });

  factory AddonGroup.fromJson(Map<String, dynamic> json) {
    return AddonGroup(
      id: JsonParser.intValue(json['id'] ?? 0),
      uuid: JsonParser.string(json['uuid'] ?? ''),
      title: JsonParser.string(json['title'] ?? ''),
      slug: JsonParser.string(json['slug'] ?? ''),
      selectionType: JsonParser.string(json['selection_type'] ?? 'single'),
      isRequired: JsonParser.boolValue(json['is_required'] ?? false),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
      status: JsonParser.string(json['status'] ?? 'inactive'),
      itemsCount: JsonParser.intValue(json['items_count'] ?? 0),
      items: JsonParser.list<AddonItem>(
        json['items'],
        (v) => AddonItem.fromJson(v as Map<String, dynamic>),
      ),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['id'] = id;
    result['uuid'] = uuid;
    result['title'] = title;
    result['slug'] = slug;
    result['selection_type'] = selectionType;
    result['is_required'] = isRequired;
    result['sort_order'] = sortOrder;
    result['status'] = status;
    result['items_count'] = itemsCount;
    result['created_at'] = createdAt;
    result['items'] = items.map((v) => v.toJson()).toList();
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        uuid,
        title,
        slug,
        selectionType,
        isRequired,
        sortOrder,
        status,
        itemsCount,
        items,
        createdAt,
      ];
}

class AddonItem extends Equatable {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final double price;
  final double cost;
  final String? indicator;
  final bool isAvailable;
  final int sortOrder;
  final String status;

  const AddonItem({
    this.id = 0,
    this.uuid = '',
    this.title = '',
    this.slug = '',
    this.price = 0.0,
    this.cost = 0.0,
    this.indicator,
    this.isAvailable = false,
    this.sortOrder = 0,
    this.status = 'inactive',
  });

  factory AddonItem.fromJson(Map<String, dynamic> json) {
    return AddonItem(
      id: JsonParser.intValue(json['id'] ?? 0),
      uuid: JsonParser.string(json['uuid'] ?? ''),
      title: JsonParser.string(json['title'] ?? ''),
      slug: JsonParser.string(json['slug'] ?? ''),
      price: JsonParser.doubleValue(json['price'] ?? 0.0),
      cost: JsonParser.doubleValue(json['cost'] ?? 0.0),
      indicator: json['indicator']?.toString(),
      isAvailable: JsonParser.boolValue(json['is_available'] ?? false),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
      status: JsonParser.string(json['status'] ?? 'inactive'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['id'] = id;
    result['uuid'] = uuid;
    result['title'] = title;
    result['slug'] = slug;
    result['price'] = price;
    result['cost'] = cost;
    result['indicator'] = indicator;
    result['is_available'] = isAvailable;
    result['sort_order'] = sortOrder;
    result['status'] = status;
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        uuid,
        title,
        slug,
        price,
        cost,
        indicator,
        isAvailable,
        sortOrder,
        status,
      ];
}
