import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../config/helper.dart';
import '../../../model/available_orders.dart';

class OrderItemsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> itemCards;
  final VoidCallback? onCollectAll;

  const OrderItemsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
    required this.itemCards,
    this.onCollectAll,
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
                    Icons.shopping_bag,
                    color: Theme.of(context).colorScheme.primary,
                    size: sz(20, seprateTabletSize: 16).sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomText(
                      text: AppLocalizations.of(context)!.orderItems,
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
                  if (order.items != null && order.items!.isNotEmpty) ...[
                    ...itemCards,
                    SizedBox(height: 16.h),
                    if (onCollectAll != null)
                      CustomButton(
                        text: AppLocalizations.of(context)!.collectAllItems,
                        onPressed: onCollectAll,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: (isTablet() ? 18 : 24).w,
                          vertical: (isTablet() ? 10 : 12).h,
                        ),
                        textStyle: TextStyle(
                          fontSize: sz(16, seprateTabletSize: 12).sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ] else
                    CustomText(
                      text: AppLocalizations.of(context)!.noData,
                      fontSize: sz(18, seprateTabletSize: 14),
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
