import 'package:dio/dio.dart';

import 'api_constants.dart';
import '../storage/secure_storage.dart';

/// Dio-based API client with Bearer token and refresh-on-401.
/// Register [onSessionExpired] in [InitialBinding] to redirect to login when refresh fails.
class ApiClient {
  static const String _defaultBaseUrl = 'https://equbapi.shinur.com';
  // static const String _defaultBaseUrl = 'http://192.168.1.4:3000';

  final Dio _dio;
  final SecureStorage _storage;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;

  ApiClient({
    required SecureStorage storage,
    String baseUrl = _defaultBaseUrl,
    this.onSessionExpired,
    Dio? dio,
  })  : _storage = storage,
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      onSessionExpired?.call();
      return handler.next(err);
    }

    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final dio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          contentType: 'application/json',
          headers: {...err.requestOptions.headers}..remove('Authorization'),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data!['accessToken'] as String?;
        final newRefreshToken = response.data!['refreshToken'] as String?;
        if (accessToken != null && newRefreshToken != null) {
          await _storage.setTokens(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
          );
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $accessToken';
          final retry = await _dio.fetch(opts);
          return handler.resolve(
            Response(
              requestOptions: opts,
              data: retry.data,
              statusCode: retry.statusCode,
            ),
          );
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _isRefreshing = false;
    }

    await _storage.clearAll();
    onSessionExpired?.call();
    handler.next(err);
  }

  Dio get dio => _dio;
}
