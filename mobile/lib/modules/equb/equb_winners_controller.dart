import 'package:get/get.dart';

import '../../data/equb_schedule.dart';
import '../../data/repositories/equb_repository.dart';

class EqubWinnersController extends GetxController {
  final EqubRepository _repo = Get.find<EqubRepository>();

  late final String equbId;
  late final String equbName;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<DateTime> nextRoundDue = Rxn<DateTime>();
  final RxList<EqubWinnerItem> winners = <EqubWinnerItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      equbId = args['equbId']?.toString() ?? '';
      equbName = args['equbName']?.toString() ?? 'Equb';
    } else {
      equbId = '';
      equbName = 'Equb';
    }
    if (equbId.isEmpty) {
      isLoading.value = false;
      errorMessage.value = 'Missing equb';
      return;
    }
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final raw = await _repo.getRounds(equbId);
      final rounds = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      nextRoundDue.value = parseNextRoundDueDate(rounds);
      winners.assignAll(parseWinnersFromRounds(rounds));
    } catch (_) {
      errorMessage.value = 'Failed to load winners and schedule';
      nextRoundDue.value = null;
      winners.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
