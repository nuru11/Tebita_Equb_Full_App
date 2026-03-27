import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../auth/auth_controller.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    // Run after the first frame so navigator is ready for offAllNamed
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    try {
      final authController = Get.find<AuthController>();
      // Timeout so we never hang (e.g. backend unreachable)
      final hasSession = await authController.checkAuth().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!isClosed) {
        if (hasSession) {
          Get.offAllNamed('/home');
        } else {
          Get.offAllNamed('/login');
        }
      }
    } catch (e, st) {
      if (!isClosed) {
        debugPrint('Splash checkAuth error: $e $st');
        Get.offAllNamed('/login');
      }
    }
  }
}
