import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class AddonGroupsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getAddonGroups({
    int page = 1,
    int perPage = 15,
    String? search,
    String? selectionType,
    String? status,
    bool? isRequired,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (selectionType != null) 'selection_type': selectionType,
        if (status != null) 'status': status,
        if (isRequired != null) 'is_required': isRequired.toString(),
      };

      final response = await _helper.get(ApiRoutes.addOnGroupListApi, queryParameters: queryParameters);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteAddonGroup(int id) async {
    try {
      final response = await _helper.delete("${ApiRoutes.addOnGroupListApi}/$id");
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> createAddonGroup(Map<String, dynamic> data) async {
    try {
      final response = await _helper.post(ApiRoutes.addOnGroupListApi, data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateAddonGroup(int id, Map<String, dynamic> data) async {
    try {
      final response = await _helper.post("${ApiRoutes.addOnGroupListApi}/$id", data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
