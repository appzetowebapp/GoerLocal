import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

class CashfreeSubscriptionPayment {
  final CFPaymentGatewayService _gateway = CFPaymentGatewayService();

  Future<void> pay({
    required String orderId,
    required String paymentSessionId,
    required String environment,
    required void Function(String orderId) onSuccess,
    required void Function(String message) onError,
  }) async {
    _gateway.setCallback(
      (String orderId) => onSuccess(orderId),
      (CFErrorResponse error, String orderId) =>
          onError(error.getMessage() ?? 'Payment failed'),
    );

    final CFEnvironment env = environment == 'production'
        ? CFEnvironment.PRODUCTION
        : CFEnvironment.SANDBOX;

    try {
      final session = CFSessionBuilder()
          .setEnvironment(env)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      final payment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _gateway.doPayment(payment);
    } on CFException catch (e) {
      onError(e.message);
    }
  }
}
