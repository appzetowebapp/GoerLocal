import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class SubscriptionPlansRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getSubscriptionPlans() async {
    return await _helper.get(ApiRoutes.subscriptionPlansApi);
  }

  Future<dynamic> checkSubscriptionEligibility(int planId) async {
    final Map<String, dynamic> body = {"plan_id": planId};
    return await _helper.post(ApiRoutes.checkEligibilityApi, body);
  }

  Future<dynamic> buySubscriptionPlan(
    int planId,
    String paymentType,
    String? gatewayTransactionId,
  ) async {
    final Map<String, dynamic> body = {
      "plan_id": planId,
      "payment_type": paymentType,
      "gateway_transaction_id": gatewayTransactionId,
    };
    return await _helper.post(
      ApiRoutes.buySubscriptionPlanApi,
      body,
    );
  }

  Future<dynamic> getCurrentSubscriptionPlan() async {
    return await _helper.get(ApiRoutes.currentSubscriptionPlanApi);
  }
}
