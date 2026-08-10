import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class MultiSelectionField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final List<T> selectedItems;
  final String Function(T) itemLabel;
  final VoidCallback onTap;
  final Function(T) onDeleted;
  final bool isRequired;

  const MultiSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedItems,
    required this.itemLabel,
    required this.onTap,
    required this.onDeleted,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: label,
          hint: hint,
          isRequired: isRequired,
          readOnly: true,
          onTap: onTap,
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          controller: TextEditingController(
            text: selectedItems.isEmpty ? "" : "${selectedItems.length} items selected",
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedItems.map((item) {
              return Chip(
                label: Text(itemLabel(item), style: const TextStyle(fontSize: 12)),
                side: BorderSide(color: Colors.grey.shade300),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
                onDeleted: () => onDeleted(item),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
