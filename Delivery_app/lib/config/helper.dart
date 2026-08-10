import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';

import '../router/app_routes.dart';
import 'app_images.dart';

bool isTablet({BuildContext? context}) {
  final shortestSide = MediaQuery.of(context ?? navigatorKey.currentState!.context).size.shortestSide;
  return shortestSide >= 600;
}

double sz(double num, {double? seprateTabletSize}) {
  if (isTablet()) {
    return seprateTabletSize ?? num;
  }
  return num;
}

String? parseString(dynamic value, {String context = 'parseString'}) {
  if (value == null) {
    // developer.log('parseString: value is null → returning null', name: context);
    return null;
  }

  if (value == "") {
    // developer.log('parseString: value is empty string → returning null', name: context);
    return null;
  }

  final result = value.toString();
  return result;
}

int? parseInt(dynamic value, {String context = 'parseInt'}) {
  if (value == null) {
    // developer.log('parseInt: value is null → returning null', name: context);
    return null;
  }

  if (value == "") {
    // developer.log('parseInt: value is empty string → returning null', name: context);
    return null;
  }

  if (value is int) {
    // developer.log('parseInt: value is already int → $value', name: context);
    return value;
  }

  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    } else {
      // developer.log('parseInt: failed to parse string "$value" → returning null', name: context);
      return null;
    }
  }

  // developer.log('parseInt: unsupported type ${value.runtimeType} → returning null', name: context);
  return null;
}

bool? parseBool(dynamic value, {String context = 'parseBool'}) {
  if (value == null) {
    // developer.log('parseBool: value is null → returning null', name: context);
    return null;
  }

  if (value is bool) {
    return value;
  }

  final str = value.toString().trim().toLowerCase();

  if (str.isEmpty) {
    // developer.log('parseBool: trimmed string is empty → returning null', name: context);
    return null;
  }

  if (str == 'true' || str == '1' || str == 'yes' || str == 'on') {
    return true;
  }

  if (str == 'false' || str == '0' || str == 'no' || str == 'off') {
    // developer.log('parseBool: recognized falsy value "$str" → false', name: context);
    return false;
  }

  // developer.log('parseBool: unrecognized value "$str" (original: $value) → returning null', name: context);
  return null;
}

enum ApiStatus { initial, loading, success, failed }

enum MobileANdEmailStatus { initial, loading, isnew, isuse }

String myLogoImage(bool isDark) {
  return isDark ? AppImages.splashLightLogo : AppImages.splashLogo;
}

void redirectionCondition(BuildContext context) {
  if (Platform.isAndroid) {
    bool isUserAgree = Global.isLocationAccepted;
    if (isUserAgree) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.locaitonDisclosure);
    }
  } else {
    context.go(AppRoutes.home);
  }
}

String removeUnderscores(String label) {
  return label.replaceAll('_', ' ').trim();
}

bool isNetworkImage(String path) {
  return path.startsWith('http://') || path.startsWith('https://');
}
