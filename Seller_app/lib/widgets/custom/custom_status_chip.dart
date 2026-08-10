import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class CustomStatusChip extends StatelessWidget {
  final String label;
  final Color baseColor;
  final ScreenType screenType;

  const CustomStatusChip({super.key, required this.label, required this.baseColor, required this.screenType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: UIUtils.gapMD(screenType), vertical: UIUtils.gapSM(screenType)),
      decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4.0)),
      child: Text(
        label,
        style: TextStyle(
          color: baseColor,
          fontSize: UIUtils.body(screenType),
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
