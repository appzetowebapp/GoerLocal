import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';

class OrderStatusBanner extends StatelessWidget {
  final String? orderStatus;
  final Color Function(String) getStatusColor;
  final String Function(String) getDisplayStatus;

  const OrderStatusBanner({
    super.key,
    required this.orderStatus,
    required this.getStatusColor,
    required this.getDisplayStatus,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = getDisplayStatus(orderStatus ?? '');
    final statusColor = getStatusColor(displayStatus);
    final isDelivered = displayStatus.toLowerCase() == 'delivered';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((isTablet() ? 12 : 16).h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isDelivered ? Icons.check_circle : Icons.access_time,
            color: statusColor,
            size: sz(20, seprateTabletSize: 16).sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomText(
              text: displayStatus.replaceAll('_', ' ').toUpperCase(),
              fontSize: sz(16, seprateTabletSize: 12),
              fontWeight: FontWeight.w600,
              color: statusColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
