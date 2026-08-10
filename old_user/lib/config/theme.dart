import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AppTheme {
  /// App main color
  static const Color primaryColor = Color(0xFF131124); // Dark Navy/Purple
  static Color primaryVariant = primaryColor.withValues(alpha: 0.8);

  static Color lightFontColor = Colors.black;
  static Color darkFontColor = Colors.white;

  /// Light Theme Colors
  static const Color mainLightBackgroundColor = Colors.white;
  static Color mainLightBackgroundColor2 = Colors.grey.shade200;
  static const Color mainLightContainerBgColor = Color(0xFFF7FAFC);
  static const Color lightSecondary = Color(0xFFE0E0E0);
  static const Color lightTertiary = Color(0xFF131124);
  static Color lightProductCardColor = Colors.grey.shade100;
  static const Color lightSubCategoryCardColor = Color(0xFFE5FBFF);
  static Color lightOutline = Colors.grey.shade200;
  static Color lightOutlineVariant = Colors.grey.shade300;

  /// Dark Theme Colors
  static const Color mainDarkBackgroundColor = Color(0xFF0C0A1A);
  static const Color mainDarkContainerBgColor = Color(0xFF131124);
  static const Color darkSubCategoryCardColor = Color(0xFF1A172E);
  static const Color darkExtraCardColor  = Color(0xFF252147);
  static const Color darkTertiary =  Color(0xFFE0E0E0);

  static Color darkProductCardColor =  Color(0xFF1A172E);
  static Color darkOutline = Colors.grey.shade800;
  static Color darkOutlineVariant = Colors.white10;

  /// Typography
  static const String fontFamily = 'LexendDeca';

  /// Messages Color
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orangeAccent;

  /// Rating Star color
  static const Color ratingStarColor = Color(0xFFEEAB18);
  static const IconData ratingStarIcon = TablerIcons.star;
  static const IconData ratingStarIconFilled = TablerIcons.star_filled;
  static const IconData ratingStarIconHalfFilled = TablerIcons.star_half_filled;


  /// Delivery Time Widget Color
  static const Color deliveryTimeWidgetColor = Color(0xFFC2FBFF);

  /// Discount Card Color
  static const Color discountCardColor = Color(0xFF256533);

  ///Coupon Card Colors
  static Color couponShadeColor = Colors.blue.shade50;
  static Color couponCollectBgColor = primaryColor.withValues(alpha: 0.1);
  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      surface: mainLightBackgroundColor,
      surfaceContainer: mainLightBackgroundColor2,
      primary: primaryColor,
      onPrimary: lightProductCardColor,
      onSecondary: lightSubCategoryCardColor,
      secondary: const Color.fromARGB(255, 255, 255, 255),
      tertiary: lightTertiary,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      onSecondaryContainer: Colors.grey[700]
    ),
    fontFamily: AppTheme.fontFamily,

    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(
          lightTertiary,
        ),
      )
    ),

  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      onPrimary: darkProductCardColor,
      onSecondary: darkSubCategoryCardColor,
      secondary: darkExtraCardColor,
      surface: mainDarkBackgroundColor,
      surfaceContainer: mainDarkContainerBgColor,
      tertiary: darkTertiary,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      onSecondaryContainer: Colors.white54
    ),
    fontFamily: AppTheme.fontFamily,
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(
              darkTertiary,
            ),
          )
      )
  );
}