import 'package:flutter/material.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class OrderDetailsSection extends StatelessWidget {
  final String orderId;
  final String payment;
  final String orderPlaced;
  final String placedAt;
  final String? otp;

  const OrderDetailsSection({
    super.key,
    required this.orderId,
    required this.payment,
    required this.orderPlaced,
    required this.placedAt,
    this.otp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.orderDetails,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 5),
            Column(
              children: [
                _buildOrderDetailRow(
                    AppLocalizations.of(context)!.orderId, orderId),
                _buildOrderDetailRow(
                    AppLocalizations.of(context)!.payment, payment),
                _buildOrderDetailRow(
                    AppLocalizations.of(context)!.orderPlaced, placedAt),
                if (otp != null && otp!.isNotEmpty)
                  _buildOrderDetailRow('OTP', otp!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
