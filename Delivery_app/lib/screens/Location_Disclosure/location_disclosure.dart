import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

import '../../config/constant.dart';
import '../../router/app_routes.dart';
import '../../utils/location_handler.dart';

class LocationDisclosure extends StatefulWidget {
  const LocationDisclosure({super.key});

  @override
  State<LocationDisclosure> createState() => _LocationDisclosureState();
}

class _LocationDisclosureState extends State<LocationDisclosure> {
  void navigate(BuildContext context) async {
    await Global.setLocationAgree(true);
    LocationHandler.initialize();
    GoRouter.of(context).pushReplacement(AppRoutes.home);
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: CustomText(
            text: AppLocalizations.of(context)!.locationPermissionRequired,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(text: AppLocalizations.of(context)!.locationMandateTitle, fontSize: 16.sp),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: CustomText(text: AppLocalizations.of(context)!.exitApp, fontSize: 16.sp),
            ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(text: AppLocalizations.of(context)!.ok, fontSize: 16.sp),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: context.height,
        width: context.width,
        child: Column(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomImageContainer(imagePath: "assets/location_disclose/locationdisclosure.png"),
            SizedBox(height: 30.sp),
            CustomText(
              text: AppLocalizations.of(context)!.locationDataUsageDisclosure,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            CustomText(text: "$appName  ${AppLocalizations.of(context)!.locationUsageDescription}."),
            SizedBox(height: 30.sp),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    backgroundColor: Colors.grey,
                    text: AppLocalizations.of(context)!.decline,
                    textColor: Colors.white,
                    onPressed: () => _showCancelDialog(context),
                  ),
                ),
                SizedBox(width: 20.sp),

                Expanded(
                  child: CustomButton(
                    text: AppLocalizations.of(context)!.accept,
                    textColor: Colors.white,
                    onPressed: () => navigate(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
