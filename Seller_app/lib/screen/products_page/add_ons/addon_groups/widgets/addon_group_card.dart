import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_status_chip.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';

class AddonGroupCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const AddonGroupCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    // Derived Display values
    final bool isRequired = data['is_required'] ?? false;
    final requiredText = isRequired ? 'Yes' : 'No';
    final requiredColor = isRequired ? Colors.orange : Colors.grey;

    final String status = data['status']?.toString() ?? '';
    final statusText = status.isNotEmpty ? "${status[0].toUpperCase()}${status.substring(1)}" : '';
    final statusColor = status.toLowerCase() == 'active' ? Colors.green : Colors.grey;

    final String selectionType = data['selection_type']?.toString() ?? '';
    final selectionText = selectionType.isNotEmpty
        ? "${selectionType[0].toUpperCase()}${selectionType.substring(1)}"
        : '';
    final selectionColor = selectionType.toLowerCase() == 'active' || selectionType.toLowerCase() == 'multiple'
        ? Colors.green
        : Colors.grey;

    String formattedDate = data['date']?.toString() ?? "Aug 08, 2025";
    try {
      if (data['created_at'] != null && data['created_at'].toString().isNotEmpty) {
        DateTime dateTime = DateTime.parse(data['created_at'].toString());
        formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      // Keep default or passed date
    }
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          data['title']?.toString() ?? '',
          style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: FontWeight.w600),
        ),
        SizedBox(height: UIUtils.gapLG(screenType)),

        // Info Rows
        _buildInfoRow('${l10n?.isRequiredLabel ?? 'Required'}:', requiredText, requiredColor),
        SizedBox(height: UIUtils.gapMD(screenType)),
        _buildInfoRow('${l10n?.status ?? 'Status'}:', statusText, statusColor),
        SizedBox(height: UIUtils.gapMD(screenType)),
        _buildInfoRow('${l10n?.selectionType ?? 'Selection Type'}:', selectionText, selectionColor),

        SizedBox(height: UIUtils.gapXL(screenType)),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${data['items_count'] ?? 0} ${l10n?.totalItems ?? 'Total Items'}",
              style: TextStyle(fontSize: UIUtils.body(screenType), color: Colors.grey.shade600),
            ),
            // Text(
            //   formattedDate,
            //   style: TextStyle(
            //     fontSize: UIUtils.body(screenType),
            //     color: Colors.grey.shade600,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color chipColor) {
    return Row(
      children: [
        SizedBox(
          width: 120, // Fixed width for alignment
          child: Text(
            label,
            style: TextStyle(fontSize: UIUtils.body(screenType), color: Colors.grey.shade600),
          ),
        ),
        CustomStatusChip(label: value, baseColor: chipColor, screenType: screenType),
      ],
    );
  }
}
