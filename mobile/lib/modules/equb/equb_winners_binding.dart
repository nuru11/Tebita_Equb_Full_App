import 'package:get/get.dart';

import 'equb_winners_controller.dart';

class EqubWinnersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EqubWinnersController>(() => EqubWinnersController());
  }
}
