import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../data/models/equb_model.dart';
import '../../data/repositories/equb_repository.dart';

class MyEqubsController extends GetxController {
  late final EqubRepository _equbRepository;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<EqubModel> equbs = <EqubModel>[].obs;
  final RxMap<String, int> currentRoundByEqubId = <String, int>{}.obs;
  final RxMap<String, int> wonRoundByEqubId = <String, int>{}.obs;

  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    _equbRepository = Get.isRegistered<EqubRepository>()
        ? Get.find<EqubRepository>()
        : EqubRepository(api: Get.find<ApiClient>());

    try {
      final list = await _equbRepository.list(myEqubsOnly: true, status: 'ACTIVE');
      equbs.assignAll(list);

      await _loadRoundMeta(list);
    } catch (_) {
      errorMessage.value = 'Failed to load your equbs';
      equbs.clear();
      currentRoundByEqubId.clear();
      wonRoundByEqubId.clear();
    } finally {
      isLoading.value = false;
    }
  }

  double paidForEqub(String equbId) {
    final equb = equbs.firstWhereOrNull((e) => e.id == equbId);
    return equb?.memberPaidAmount ?? 0;
  }

  Future<void> _loadRoundMeta(List<EqubModel> equbList) async {
    currentRoundByEqubId.clear();
    wonRoundByEqubId.clear();
    for (final equb in equbList) {
      if (equb.currentRoundNumber > 0) {
        currentRoundByEqubId[equb.id] = equb.currentRoundNumber;
      }
      if (equb.wonRoundNumber > 0 || equb.hasWon) {
        wonRoundByEqubId[equb.id] = equb.wonRoundNumber;
      }
    }
  }
}

