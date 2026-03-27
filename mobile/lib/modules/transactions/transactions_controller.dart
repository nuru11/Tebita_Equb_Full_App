import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../data/models/transaction_model.dart';

class TransactionsController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.dio.get<List<dynamic>>('/api/payments/me');
      if (response.data != null) {
        transactions.assignAll(
          response.data!
              .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        transactions.clear();
      }
    } catch (_) {
      errorMessage.value = 'Failed to load transactions';
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
