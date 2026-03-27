import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Response from login or refresh.
class AuthTokens {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

class RegisterOtpRequestResponse {
  final String verificationId;
  final int retryAfter;

  const RegisterOtpRequestResponse({
    required this.verificationId,
    required this.retryAfter,
  });
}

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepository({required ApiClient api, required SecureStorage storage})
      : _api = api,
        _storage = storage;

  Future<RegisterOtpRequestResponse> requestRegisterOtp({
    required String phone,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.registerRequestOtp,
      data: {'phone': phone},
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    }

    final verificationId = response.data!['verificationId'] as String?;
    final retryAfter = response.data!['retryAfter'] as int? ?? 60;
    if (verificationId == null || verificationId.isEmpty) {
      throw Exception('Invalid OTP response');
    }

    return RegisterOtpRequestResponse(
      verificationId: verificationId,
      retryAfter: retryAfter,
    );
  }

  /// Register after successful OTP verification.
  Future<UserModel> verifyRegisterOtpAndRegister({
    required String phone,
    required String password,
    required String fullName,
    required String code,
    required String verificationId,
    String? email,
    String? referenceCode,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.registerVerifyOtp,
      data: {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        'code': code,
        'verificationId': verificationId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (referenceCode != null && referenceCode.isNotEmpty)
          'referenceCode': referenceCode,
      },
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 201 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    }

    final userJson = response.data!['user'] as Map<String, dynamic>?;
    if (userJson == null) throw Exception('Invalid register response');
    return UserModel.fromJson(userJson);
  }

  /// Login: returns tokens and user, saves to storage.
  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'phone': phone, 'password': password},
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    }

    final data = response.data!;
    final userJson = data['user'] as Map<String, dynamic>?;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final expiresIn = data['expiresIn'] as int? ?? 900;

    if (userJson == null || accessToken == null || refreshToken == null) {
      throw Exception('Invalid login response');
    }

    final user = UserModel.fromJson(userJson);
    await _storage.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storage.setUserJson(jsonEncode(user.toJson()));

    return AuthTokens(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }

  /// Refresh: use stored refreshToken, save new tokens, return new tokens and user.
  Future<AuthTokens?> refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data!;
      final userJson = data['user'] as Map<String, dynamic>?;
      final accessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      final expiresIn = data['expiresIn'] as int? ?? 900;

      if (userJson == null || accessToken == null || newRefreshToken == null) {
        return null;
      }

      final user = UserModel.fromJson(userJson);
      await _storage.setTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      await _storage.setUserJson(jsonEncode(user.toJson()));

      return AuthTokens(
        user: user,
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        expiresIn: expiresIn,
      );
    } catch (_) {
      return null;
    }
  }

  /// Logout: clear tokens and user from storage.
  Future<void> logout() async {
    await _storage.clearAll();
  }
}
