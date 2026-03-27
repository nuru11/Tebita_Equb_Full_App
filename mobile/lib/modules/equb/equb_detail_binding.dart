import 'package:get/get.dart';

import 'equb_detail_controller.dart';

class EqubDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EqubDetailController>(() => EqubDetailController());
  }
}

