import 'package:get/get.dart';

import '../core/api/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../modules/auth/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = SecureStorage();
    Get.put<SecureStorage>(storage, permanent: true);

    final api = ApiClient(
      storage: storage,
      onSessionExpired: () {
        Get.offAllNamed('/login');
      },
    );
    Get.put<ApiClient>(api, permanent: true);

    Get.put<AuthRepository>(
      AuthRepository(api: api, storage: storage),
      permanent: true,
    );

    Get.put<UserRepository>(
      UserRepository(api: api, storage: storage),
      permanent: true,
    );

    // Lazy so first frame is not blocked by controller init
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
