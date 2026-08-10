import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';

import '../../../model/available_orders.dart';

import 'package:hyper_local/l10n/app_localizations.dart';

class PaymentMethodCard extends StatelessWidget {
  final Orders order;

  const PaymentMethodCard({super.key, required this.order});

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'cod':
      case 'cash on delivery':
        return Colors.blue;
      case 'online':
      case 'card':
      case 'upi':
      case 'wallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
      case 'cash on delivery':
        return Icons.money;
      case 'card':
      case 'credit card':
      case 'debit card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance;
      case 'wallet':
      case 'digital wallet':
        return Icons.account_balance_wallet;
      case 'online':
      case 'net banking':
        return Icons.account_balance;
      case 'paid':
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.schedule;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      width: double.infinity,
      height: (isTablet() ? 90 : 100).h,

      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all((isTablet() ? 6 : 8).h),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(
                order.paymentMethod ?? '',
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getPaymentMethodIcon(order.paymentMethod ?? ''),
              color: _getPaymentStatusColor(order.paymentMethod ?? ''),
              size: sz(20, seprateTabletSize: 16).sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: AppLocalizations.of(context)!.paymentMethod,
                  fontSize: sz(15, seprateTabletSize: 12),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: order.paymentMethod?.toUpperCase() ?? 'N/A',
                  fontSize: sz(16, seprateTabletSize: 11),
                  fontWeight: FontWeight.bold,
                  color: _getPaymentStatusColor(order.paymentMethod ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isTablet() ? 6 : 8).w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(
                order.paymentStatus ?? '',
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _getPaymentStatusColor(
                  order.paymentStatus ?? '',
                ).withValues(alpha: 0.3),
              ),
            ),
            child: CustomText(
              text: order.paymentStatus?.toUpperCase() ?? 'N/A',
              fontSize: sz(10, seprateTabletSize: 8),
              fontWeight: FontWeight.w600,
              color: _getPaymentStatusColor(order.paymentStatus ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}
