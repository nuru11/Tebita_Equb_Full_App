import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../data/repositories/notification_repository.dart';
import '../home/home_binding.dart';
import '../profile/notification_controller.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure home-related dependencies are available for the Home tab
    HomeBinding().dependencies();

    Get.lazyPut<NotificationRepository>(
      () => NotificationRepository(api: Get.find<ApiClient>()),
    );
    Get.lazyPut<NotificationController>(() => NotificationController());

    Get.lazyPut<MainController>(() => MainController());
  }
}

