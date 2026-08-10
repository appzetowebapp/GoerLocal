import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../model/store_addon_inventory_model.dart';

class StoreAddonInventoryRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<StoreAddonInventoryResponse> getStoreAddonInventory({
    int? addonGroupId,
    int page = 1,
    int perPage = 15,
    String? search,
    int? storeId,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'per_page': perPage};
    if (addonGroupId != null) queryParams['addon_group_id'] = addonGroupId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (storeId != null) queryParams['store_id'] = storeId;

    final response = await _helper.get(ApiRoutes.stockInventoryListApi, queryParameters: queryParams);
    return StoreAddonInventoryResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> getLookupStores() async {
    final response = await _helper.get(ApiRoutes.lookupStoresForInventoryApi);
    return response;
  }

  Future<Map<String, dynamic>> getLookupAddonGroups() async {
    final response = await _helper.get(ApiRoutes.lookupAddonGroupsForInventoryApi);
    return response;
  }

  Future<Map<String, dynamic>> deleteStoreAddonItem(int id) async {
    final response = await _helper.delete('${ApiRoutes.stockInventoryListApi}/$id');
    return response;
  }
}
