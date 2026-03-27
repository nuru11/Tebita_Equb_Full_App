import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../data/models/equb_model.dart';
import '../../data/repositories/equb_repository.dart';
import '../auth/auth_controller.dart';

class HomeController extends GetxController {
  final EqubRepository _equbRepository = Get.find<EqubRepository>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<EqubModel> equbs = <EqubModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString joiningEqubId = ''.obs;
  final RxList<String> joinedEqubIds = <String>[].obs;
  final RxBool showMyEqubsOnly = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchEqubs();
  }

  Future<void> fetchEqubs({
    bool? myEqubsOnly,
    bool isRefresh = false,
  }) async {
    final useMyEqubsOnly = myEqubsOnly ?? showMyEqubsOnly.value;
    if (!isRefresh) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    errorMessage.value = '';
    try {
      final items = await _equbRepository.list(
        myEqubsOnly: useMyEqubsOnly,
        status: 'ACTIVE',
      );
      equbs.assignAll(items);

      // Refresh list of equbs the current user has joined (active only)
      final myEqubs = await _equbRepository.list(
        myEqubsOnly: true,
        status: 'ACTIVE',
      );
      joinedEqubIds.assignAll(myEqubs.map((e) => e.id));
    } catch (e) {
      errorMessage.value = 'Failed to load equbs';
    } finally {
      if (!isRefresh) {
        isLoading.value = false;
      } else {
        isRefreshing.value = false;
      }
    }
  }

  Future<void> refreshEqubs() {
    return fetchEqubs(isRefresh: true);
  }

  Future<void> toggleMyEqubsOnly() async {
    final nextValue = !showMyEqubsOnly.value;
    showMyEqubsOnly.value = nextValue;
    await fetchEqubs(myEqubsOnly: nextValue);
  }

  Future<void> logout() => _authController.logout();

  Future<void> joinEqub(EqubModel equb) async {
    if (joinedEqubIds.contains(equb.id)) {
      return;
    }
    joiningEqubId.value = equb.id;
    errorMessage.value = '';
    var success = false;
    try {
      await _equbRepository.join(equb.id);
      if (!joinedEqubIds.contains(equb.id)) {
        joinedEqubIds.add(equb.id);
      }
      await fetchEqubs();
      success = true;
    } on DioException catch (e) {
      final err = e.response?.data;
      final msg = err is Map && err['error'] is String
          ? err['error'] as String
          : 'Failed to join equb';
      errorMessage.value = msg;
      Get.snackbar(
        'Join failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      errorMessage.value = 'Failed to join equb';
      Get.snackbar(
        'Join failed',
        'Failed to join equb',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      joiningEqubId.value = '';
      if (success) {
        Get.snackbar(
          'Joined',
          'You have joined this equb',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

