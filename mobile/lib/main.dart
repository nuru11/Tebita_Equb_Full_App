import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings.dart';
import 'app/routes.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const EqubApp());
}

class EqubApp extends StatelessWidget {
  const EqubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return GetMaterialApp(
      title: 'Equb',
      theme: ThemeData(
        colorScheme: colorScheme,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
