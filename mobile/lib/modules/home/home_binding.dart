import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../data/repositories/equb_repository.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EqubRepository>(
      () => EqubRepository(api: Get.find<ApiClient>()),
    );
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

