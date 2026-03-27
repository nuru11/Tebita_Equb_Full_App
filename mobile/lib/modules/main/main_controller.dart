import 'package:get/get.dart';

import '../home/home_controller.dart';
import '../profile/notification_controller.dart';

class MainController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;

    final homeController = Get.find<HomeController>();
    if (index == 0) {
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchNotifications();
      }
      // Home dashboard should always show "All" equbs.
      if (homeController.showMyEqubsOnly.value) {
        homeController.showMyEqubsOnly.value = false;
        homeController.fetchEqubs(myEqubsOnly: false);
      }
    } else if (index == 1) {
      homeController.showMyEqubsOnly.value = true;
      homeController.fetchEqubs(myEqubsOnly: true);
    }
  }

  /// Opens Equbs tab in "All" mode so the user can browse and join.
  void openBrowseAllEqubs() {
    currentIndex.value = 1;
    final homeController = Get.find<HomeController>();
    homeController.showMyEqubsOnly.value = false;
    homeController.fetchEqubs(myEqubsOnly: false);
  }
}

