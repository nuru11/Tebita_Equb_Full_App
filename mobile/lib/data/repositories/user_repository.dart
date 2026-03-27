import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  UserRepository({required ApiClient api, required SecureStorage storage})
      : _api = api,
        _storage = storage;

  Future<UserModel> updateMe({
    String? fullName,
    String? email,
    String? referenceCode,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    if (referenceCode != null) data['referenceCode'] = referenceCode;

    final response = await _api.dio.patch<Map<String, dynamic>>(
      ApiConstants.userMe,
      data: data,
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to update profile',
      );
    }

    final updated = UserModel.fromJson(response.data!);
    await _storage.setUserJson(jsonEncode(updated.toJson()));
    return updated;
  }
}

