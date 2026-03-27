import 'package:get/get.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repo = Get.find<NotificationRepository>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onReady() {
    super.onReady();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _repo.list();
      notifications.assignAll(list);
    } catch (_) {
      errorMessage.value = 'Failed to load notifications';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await _repo.markRead(n.id);
      final idx = notifications.indexWhere((e) => e.id == n.id);
      if (idx >= 0) {
        notifications[idx] = NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }
    } catch (_) {}
  }
}
