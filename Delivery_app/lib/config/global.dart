import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constant.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Global {
  static final ValueNotifier<bool> isAccountApprovedNotifier = ValueNotifier<bool>(false);

  static const String _boxName = 'UserDataBox';
  static const String _tokenKey = 'userToken';
  static const String _idTokenKey = 'firebaseIdToken';
  static const String _statusBoxName = 'DeliveryBoyStatusBox';
  static const String _statusKey = 'isOnline';
  static const String _locationAgreeKey = 'location_agree';

  static const String _languageNameBox = "_languageBoxLanguageDataBox";
  static const String _languageKey = 'selected_language';

  static const String _destinationName = "DestinationStatusBox";

  static const String _themeBoxName = "theme_box";
  static const String _themeKey = 'selected_theme';

  static Future<Box> get _userBox async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  static Future<Box> get _statusBox async {
    if (Hive.isBoxOpen(_statusBoxName)) {
      return Hive.box(_statusBoxName);
    }
    return await Hive.openBox(_statusBoxName);
  }

  static Future<Box> get _destinationBox async {
    if (Hive.isBoxOpen(_destinationName)) {
      return Hive.box(_destinationName);
    }
    return await Hive.openBox(_destinationName);
  }

  static Future<Box> get _languageBox async {
    if (Hive.isBoxOpen(_languageNameBox)) {
      return Hive.box(_languageNameBox);
    }

    return await Hive.openBox(_languageNameBox);
  }

  static Future<Box> get _themeBox async {
    if (Hive.isBoxOpen(_themeBoxName)) {
      return Hive.box(_themeBoxName);
    }

    return await Hive.openBox(_themeBoxName);
  }

  static Future<void> setUserToken(String token) async {
    final box = await _userBox;
    await box.put(_tokenKey, token);
    _cachedToken = token;
  }

  static Future<void> refreshCachedToken() async {
    final box = await _userBox;
    final tokenFromStorage = box.get(_tokenKey);

    _cachedToken = tokenFromStorage;

    // if (_cachedToken == null) {
    //   final allKeys = box.keys.toList();
    // }
  }

  static Future<String?> getUserToken() async {
    final box = await _userBox;
    final token = box.get(_tokenKey);

    return token;
  }

  static String? _cachedToken;

  static Future<void> initializeToken() async {
    final box = await _userBox;
    final tokenFromBox = box.get(_tokenKey);

    _cachedToken = tokenFromBox;
  }

  static String? get userToken {
    return _cachedToken;
  }

  static Future<void> clearUserToken() async {
    final box = await _userBox;
    await box.delete(_tokenKey);
    _cachedToken = null;
  }
  //////Location Agree Status

  static bool? _cachedLocationAgree;

  static Future<void> initializeLocationRequest() async {
    final box = await _userBox;
    _cachedLocationAgree = box.get(_locationAgreeKey) ?? false;
  }

  static Future<void> setLocationAgree(bool value) async {
    final box = await _userBox;
    await box.put(_locationAgreeKey, value);
    _cachedLocationAgree = value;
  }

  static bool get isLocationAccepted {
    return _cachedLocationAgree ?? false;
  }

  // Firebase ID Token management
  static String? _cachedIdToken;

  static Future<void> setIdToken(String idToken) async {
    final box = await _userBox;
    await box.put(_idTokenKey, idToken);
    _cachedIdToken = idToken;
    debugPrint('🔐 FIREBASE ID TOKEN SAVED TO HIVE');
  }

  static Future<String?> getIdToken() async {
    if (_cachedIdToken != null) {
      return _cachedIdToken;
    }

    final box = await _userBox;
    final idToken = box.get(_idTokenKey);
    _cachedIdToken = idToken;

    return idToken;
  }

  static Future<void> initializeIdToken() async {
    final box = await _userBox;
    _cachedIdToken = box.get(_idTokenKey);
  }

  static String? get idToken => _cachedIdToken;

  static Future<void> clearIdToken() async {
    final box = await _userBox;
    await box.delete(_idTokenKey);
    _cachedIdToken = null;
  }

  static const String _fcmTokenKey = 'fcmTokenValue';
  static String? _cachedFcmToken;

  static Future<void> setFCMToken(String token) async {
    final box = await _userBox;
    await box.put(_fcmTokenKey, token);
    _cachedFcmToken = token;
    debugPrint('🔔 FCM TOKEN SAVED TO HIVE: $token');
  }

  static Future<String?> getFCMToken() async {
    if (_cachedFcmToken != null) {
      return _cachedFcmToken;
    }

    final box = await _userBox;
    final token = box.get(_fcmTokenKey);
    _cachedFcmToken = token;

    if (token != null) {
      log('TOKEN :::: $token');
    } else {}

    return token;
  }

  static Future<void> printFCMToken() async {
    final token = await getFCMToken();
    if (token != null) {
      log('TOKEN :::::::::: $token');
    } else {}
  }

  static Future<void> setDeliveryBoyStatus(bool isOnline) async {
    final box = await _statusBox;
    await box.put(_statusKey, isOnline);
  }

  static Future<bool?> getDeliveryBoyStatus() async {
    final box = await _statusBox;
    return box.get(_statusKey) ?? false;
  }

  static bool? _cachedStatus;

  static Future<void> initializeStatus() async {
    final box = await _statusBox;
    _cachedStatus = box.get(_statusKey) ?? false;
  }

  static bool? get deliveryBoyStatus => _cachedStatus;

  static Future<void> debugTokenState() async {
    // final userBox = await _userBox;
    // final tokenFromBox = userBox.get(_tokenKey);
  }

  static Future<void> clearDeliveryBoyStatus() async {
    final box = await _statusBox;
    await box.delete(_statusKey);
    _cachedStatus = null;
  }

  //////////////////////////////

  static Future<void> setReachedDestinationStatus(
    String key,
    bool status,
  ) async {
    final box = await _destinationBox;
    await box.put(key, status);
  }

  static Future<bool?> getReachedDestinationStatus(String key) async {
    final box = await _destinationBox;
    return box.get(key) ?? false;
  }
  //////////////////////////////////

  static Future<void> setLanguage(String value) async {
    final box = await _languageBox;
    await box.put(_languageKey, value);
  }

  static Future<String?> getLanguage() async {
    final box = await _languageBox;
    return box.get(_languageKey);
  }

  static Future<String> getTheme() async {
    final box = await _themeBox;
    return box.get(_themeKey, defaultValue: defaultTheme);
  }

  static Future<void> setTheme(String theme) async {
    final box = await _themeBox;
    await box.put(_themeKey, theme);
  }
}
