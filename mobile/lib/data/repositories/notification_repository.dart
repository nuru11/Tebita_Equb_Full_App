import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _api;

  NotificationRepository({required ApiClient api}) : _api = api;

  Future<List<NotificationModel>> list({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      if (unreadOnly) 'unreadOnly': 'true',
      'limit': limit,
    };
    final response = await _api.dio.get<List<dynamic>>(
      ApiConstants.notifications,
      queryParameters: query,
      options: Options(responseType: ResponseType.json),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to load notifications',
      );
    }

    final data = response.data!;
    return data
        .map(
          (e) => NotificationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      ApiConstants.notificationMarkRead(id),
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to mark notification as read',
      );
    }
  }
}
