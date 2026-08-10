import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class ProductAddonRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getProductAddonGroups({
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
      };

      final response = await _helper.get(ApiRoutes.productAddOneListApi, queryParameters: queryParameters);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteProductAddonGroup({required int variantId,required int groupId}) async {
    try {
      final response = await _helper.delete("${ApiRoutes.deleteProductAddOnApi}/$variantId/$groupId");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Future<dynamic> createProductAddonGroup(Map<String, dynamic> data) async {
  //   try {
  //     final response = await _helper.post(ApiRoutes.addOnGroupListApi, data);
  //     return response;
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }
  //
  // Future<dynamic> updateProductAddonGroup(int id, Map<String, dynamic> data) async {
  //   try {
  //     final response = await _helper.post("${ApiRoutes.addOnGroupListApi}/$id", data);
  //     return response;
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }
}
