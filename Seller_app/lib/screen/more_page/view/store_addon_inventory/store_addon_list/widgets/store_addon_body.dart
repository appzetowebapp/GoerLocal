import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_status_chip.dart';

class StoreAddonBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const StoreAddonBody({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = data['is_available'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow("Store", data['store_name']?.toString() ?? ''),
        _buildInfoRow("Addon Item", "${data['addon_item_title']} • ${data['addon_group_title']}"),
        _buildInfoRow("Price", data['price']?.toString() ?? '0.00'),
        _buildInfoRow("Cost", data['cost']?.toString() ?? '0.00'),
        _buildInfoRow("Stock", data['stock']?.toString() ?? '0'),
        _buildStatusRow("Is Available", isAvailable),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          CustomStatusChip(
            label: isAvailable ? "Active" : "Inactive",
            baseColor: isAvailable ? Colors.green : Colors.red,
            screenType: screenType,
          ),
        ],
      ),
    );
  }
}
