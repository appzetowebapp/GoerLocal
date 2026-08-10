import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/currency_formatter.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../config/helper.dart';
import '../../../model/available_orders.dart';

class EarningsDetailsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;

  const EarningsDetailsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all((isTablet() ? 12 : 16).h),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                    size: sz(20, seprateTabletSize: 16).sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomText(
                      text: AppLocalizations.of(context)!.earningsDetails,
                      fontSize: sz(16, seprateTabletSize: 12),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: sz(24, seprateTabletSize: 18).sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
            ),
            Padding(
              padding: EdgeInsets.all((isTablet() ? 12 : 16).h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEarningsRow(
                    context,
                    AppLocalizations.of(context)!.baseFee,
                    CurrencyFormatter.formatAmount(
                      context,
                      order.earnings?.breakdown?.baseFee ?? '0',
                    ),
                  ),
                  _buildEarningsRow(
                    context,
                    AppLocalizations.of(context)!.perStorePickupFee,
                    CurrencyFormatter.formatAmount(
                      context,
                      order.earnings?.breakdown?.perStorePickupFee ?? '0',
                    ),
                  ),
                  _buildEarningsRow(
                    context,
                    AppLocalizations.of(context)!.distanceBasedFee,
                    CurrencyFormatter.formatAmount(
                      context,
                      order.earnings?.breakdown?.distanceBasedFee ?? '0',
                    ),
                  ),
                  _buildEarningsRow(
                    context,
                    AppLocalizations.of(context)!.perOrderIncentive,
                    CurrencyFormatter.formatAmount(
                      context,
                      order.earnings?.breakdown?.perOrderIncentive ?? '0',
                    ),
                  ),
                  Divider(height: 24.h),
                  _buildEarningsRow(
                    context,
                    AppLocalizations.of(context)!.totalEarnings,
                    CurrencyFormatter.formatAmount(
                      context,
                      order.earnings?.total ?? '0',
                    ),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsRow(
    BuildContext context,
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize:
                isTotal
                    ? sz(16, seprateTabletSize: 12)
                    : sz(14, seprateTabletSize: 10),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color:
                isTotal
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          CustomText(
            text: amount,
            fontSize:
                isTotal
                    ? sz(18, seprateTabletSize: 14)
                    : sz(14, seprateTabletSize: 10),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color:
                isTotal
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
