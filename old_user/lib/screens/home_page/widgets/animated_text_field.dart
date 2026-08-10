import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/router/app_routes.dart';

class CustomAnimatedTextField extends StatelessWidget {
  const CustomAnimatedTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
      ),
      child: SizedBox(
        height: 42,
        child: GestureDetector(
          onTap: () {
            GoRouter.of(context).push(AppRoutes.search);
          },
          child: Stack(
            children: [
              Directionality(
                textDirection: Localizations.localeOf(context).languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
                child: AnimatedTextField(
                  animationDuration: const Duration(milliseconds: 500),
                  animationType: Animationtype.typer,
                  showCursor: false,
                  readOnly: true,
                  enabled: false,
                  hintTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                  ),
                  hintTexts: removeUnderscoresFromStringList(SettingsData.instance.homeGeneralSettings?.searchLabels?? [
                    'Search "ice cream"',
                    'Search "milk"',
                    'Search "rice"',
                    'Search "shampoo"',
                    'Search "namkeen"',
                  ]),
                  minLines: 1,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                    ),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(
                      HeroiconsOutline.magnifyingGlass,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      GoRouter.of(context).push(AppRoutes.shoppingList);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        HeroiconsOutline.viewfinderCircle,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}