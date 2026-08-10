// ignore_for_file: empty_catches, depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_event.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'config/theme/theme.dart';
import 'config/theme/theme_bloc/theme_bloc.dart';
import 'config/theme/theme_bloc/theme_event.dart';
import 'config/theme/theme_bloc/theme_state.dart';
import 'config/localization_bloc/localization_bloc.dart';
import 'config/localization_bloc/localization_event.dart';
import 'config/localization_bloc/localization_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/location_monitor_widget.dart';
import 'package:hyper_local/config/app_initializer.dart';
import 'package:hyper_local/config/injection_container.dart';
import 'package:hyper_local/utils/background_location_service.dart';
import 'package:hyper_local/config/app_bloc_observer.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppInitializer.initialize();

  await BackgroundLocationService.initializeService();
  await BackgroundLocationService.restartServicesIfNeeded();
  // FlutterNativeSplash.remove();

  Bloc.observer = AppBlocObserver();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeBloc>()..add(LoadTheme())),
        BlocProvider(
          create: (_) => sl<NotificationBloc>()..add(FetchNotifications()),
        ),
        BlocProvider(
          create: (_) => sl<SystemSettingsBloc>()..add(FetchSystemSettings()),
        ),
        BlocProvider(
          create: (_) => sl<LocalizationBloc>()..add(LoadSavedLocale()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDark = context.isDarkMode;
          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, locState) {
              return SafeArea(
                top: false,
                bottom: Platform.isIOS ? false : true,
                left: false,
                right: false,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: AppColor.getLightTheme(),
                  darkTheme: AppColor.getDarkTheme(),
                  themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                  locale: locState.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: LocalizationBloc.supportedLocales,
                  builder: (context, child) {
                    return FToastBuilder()(
                      context,
                      LocationMonitor(child: child!),
                    );
                  },
                  routerConfig: MyAppRoute.router,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
