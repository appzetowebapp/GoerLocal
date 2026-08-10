import 'package:hyper_local_seller/config/constant.dart';

class ApiRoutes {
  // DON"T CHANGE ANY OF THIS URLs
  static String mainUrl = '${AppConstants.domainUrl}/api';
  static String baseUrl = '$mainUrl/seller';

  // AUTH
  static String registerApi = '$baseUrl/register'; 
  static String registrationStatusApi = '$baseUrl/registration-status';
  static String loginApi = '$baseUrl/login'; 
 
  static String logoutApi = '$baseUrl/logout';
  static String forgetPasswordApi = '$mainUrl/forget-password';
  static String verifyUserApi = '$mainUrl/verify-user';
  static String callbackApi = '$mainUrl/auth/phone/callback';
  static String customSendOtpApi = '$mainUrl/auth/send-otp'; 
  static String customVerifyOtpApi = '$mainUrl/auth/verify-otp';

  static String settingsApi = '$mainUrl/settings';

  static String categoriesApi = '$mainUrl/categories';
  static String brandsApi = '$baseUrl/brands';
  static String attributesApi = '$baseUrl/attributes';
  static String attributeValueApi = '$baseUrl/attribute-values';
  static String productsApi = '$baseUrl/products';
  static String productFaqsApi = '$baseUrl/product-faqs';
  static String productsEnumsApi = '$productsApi/enums';
  static String taxGroupsApi = '$baseUrl/tax-classes';
  static String storesApi = '$baseUrl/stores';
  static String storesEnumsApi = '$storesApi/enums';
  static String rolesApi = '$baseUrl/roles';
  static String rolesListApi = '$rolesApi/list';
  static String permissionsApi = '$baseUrl/permissions';
  static String systemUsersApi = '$baseUrl/system-users';
  static String notificationsApi = '$baseUrl/notifications';

  static String dashboardDataApi = '$baseUrl/dashboard';
  static String ordersApi = '$baseUrl/orders';
  static String ordersEnumsApi = '$ordersApi/enums';

  // wallet / transactions
  static String walletApi = '$baseUrl/wallet';
  static String transactionsApi = '$walletApi/transactions';
  static String withdrawalsApi = '$baseUrl/withdrawals';
  static String withdrawalHistoryApi = '$withdrawalsApi/history';

  // commission
  static String unsettledCreditApi = '$baseUrl/commissions';
  static String unsettledDebitApi = '$unsettledCreditApi/debits';
  static String settledEarningsApi = '$unsettledCreditApi/history';

  // profile
  static String updateUserApi = '$mainUrl/user/profile';
  static String changePasswordApi = '$mainUrl/user/change-password';

  // delivery zone
  static String deliveryZonesApi = '$mainUrl/delivery-zone';

  // subscription plans
  static String subscriptionPlansApi = '$mainUrl/subscription/plans';
  static String checkEligibilityApi = '$baseUrl/subscription/check-eligibility';
  static String buySubscriptionPlanApi = '$baseUrl/subscription/buy';
  static String currentSubscriptionPlanApi = '$baseUrl/subscription/current';
  static String subscriptionPlanHistoryApi = '$baseUrl/subscription/history';
  static String deleteProfileApi = '$baseUrl/delete-account';
  static String addOnGroupListApi = "$baseUrl/addon-groups";
  static String productAddOneListApi = "$baseUrl/product-addons";
  static String deleteProductAddOnApi = "$baseUrl/product-addons";
  static String lookupProductsApi = '$baseUrl/product-addons/lookup/products';
  static String lookupVariantsBulkApi = '$baseUrl/product-addons/lookup/variants-bulk';
  static String lookupAddonGroupsApi = '$baseUrl/product-addons/lookup/addon-groups';
  static String showProductAddonApi = '$baseUrl/product-addons/show'; 
  static String updateProductAddonApi(int variantId, int groupId) =>
      '$baseUrl/product-addons/$variantId/$groupId';
  static String versionCheckApi = '$mainUrl/settings/check-version';
  static String stockInventoryListApi = "$baseUrl/store-addon-items";
  static String lookupStoresForInventoryApi = "$stockInventoryListApi/lookup/stores";
  static String lookupAddonGroupsForInventoryApi = "$stockInventoryListApi/lookup/addon-groups";
  static String lookupGroupItemsApi(int groupId) => "$stockInventoryListApi/lookup/groups/$groupId/items";
  static String lookupInventoryStateApi(int storeId, int itemId) =>
      "$stockInventoryListApi/lookup/state?store_id=$storeId&addon_item_id=$itemId";
  static String bulkCreateInventoryApi = "$stockInventoryListApi/bulk";
  static String updateInventoryApi(int id) => "$stockInventoryListApi/$id";
}
