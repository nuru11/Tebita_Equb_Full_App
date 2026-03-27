import 'package:get/get.dart';

import '../../data/models/equb_model.dart';
import '../../data/repositories/equb_repository.dart';
import '../home/home_controller.dart';

class EqubDetailController extends GetxController {
  final EqubRepository _repo = Get.find<EqubRepository>();

  final Rx<EqubModel?> equb = Rx<EqubModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isJoining = false.obs;
  final RxBool isLeaving = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    final id = arg is String ? arg : null;
    if (id != null) {
      _load(id);
    } else {
      isLoading.value = false;
      errorMessage.value = 'Missing equb id';
    }
  }

  Future<void> _load(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      equb.value = await _repo.getById(id);
    } catch (e) {
      errorMessage.value = 'Failed to load equb';
    } finally {
      isLoading.value = false;
    }
  }

  bool get isJoined {
    if (!Get.isRegistered<HomeController>()) return false;
    final home = Get.find<HomeController>();
    final current = equb.value;
    if (current == null) return false;
    return home.joinedEqubIds.contains(current.id);
  }

  Future<void> join() async {
    final current = equb.value;
    if (current == null) return;
    if (isJoined) return;

    isJoining.value = true;
    errorMessage.value = '';
    var success = false;
    try {
      await _repo.join(current.id);

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        if (!home.joinedEqubIds.contains(current.id)) {
          home.joinedEqubIds.add(current.id);
        }
        home.fetchEqubs();
      }
      success = true;
    } catch (e) {
      errorMessage.value = 'Failed to join equb';
      Get.snackbar(
        'Join failed',
        'Failed to join equb',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isJoining.value = false;
      if (success) {
        Get.snackbar(
          'Joined',
          'You have joined this equb',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> leave() async {
    final current = equb.value;
    if (current == null) return;
    if (!isJoined) return;

    isLeaving.value = true;
    errorMessage.value = '';
    var success = false;
    try {
      await _repo.leave(current.id);

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.joinedEqubIds.remove(current.id);
        home.fetchEqubs();
      }
      success = true;
    } catch (e) {
      errorMessage.value = 'Failed to leave equb';
      Get.snackbar(
        'Leave failed',
        'Failed to leave equb',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLeaving.value = false;
      if (success) {
        Get.snackbar(
          'Left equb',
          'You have left this equb',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

