import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/helper.dart';

class PreviouslyBoughtRepository {
  final String apiUrl = 'https://ec.appzetodemo.com/api/products/random-categories?limit=50';

  Future<Map<String, dynamic>> fetchPreviouslyBoughtProducts() async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(apiUrl, {});
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
