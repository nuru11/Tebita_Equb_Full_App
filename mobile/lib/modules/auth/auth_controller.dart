import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt otpRetryAfter = 0.obs;

  bool get isLoggedIn => user.value != null;

  void clearError() => errorMessage.value = '';

  Future<void> login(String phone, String password) async {
    if (phone.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Phone and password are required';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final tokens = await _authRepository.login(
        phone: phone.trim(),
        password: password,
      );
      user.value = tokens.user;
      Get.offAllNamed('/main');
    } on DioException catch (e) {
      final err = e.response?.data;
      String msg;
      if (err is Map && err['error'] != null) {
        msg = err['error'] as String;
      } else if (e.response?.statusCode == 401) {
        msg = 'Invalid credentials';
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg = 'Network error. Check internet and try again.';
      } else {
        msg = e.message ?? 'Login failed';
      }
      errorMessage.value = msg;
    } catch (e) {
      final s = e.toString().toLowerCase();
      errorMessage.value = s.contains('socket') || s.contains('connection') || s.contains('handshake')
          ? 'Network error. Check internet and try again.'
          : (e.toString().length > 80 ? 'Login failed' : e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> requestRegisterOtp({
    required String phone,
  }) async {
    if (phone.trim().isEmpty) {
      errorMessage.value = 'Phone is required';
      return null;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _authRepository.requestRegisterOtp(phone: phone.trim());
      otpRetryAfter.value = result.retryAfter;
      return result.verificationId;
    } on DioException catch (e) {
      final err = e.response?.data;
      String msg = 'Failed to send verification code';
      if (err is Map && err['error'] != null) {
        msg = err['error'] as String;
      } else if (e.response?.statusCode == 409) {
        msg = 'Phone or email already registered';
      } else if (e.response?.statusCode == 429) {
        msg = 'Please wait before requesting a new code';
      }
      errorMessage.value = msg;
      return null;
    } catch (_) {
      errorMessage.value = 'Failed to send verification code';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyRegisterOtpAndRegister({
    required String phone,
    required String password,
    required String fullName,
    required String code,
    required String verificationId,
    String? email,
    String? referenceCode,
  }) async {
    if (phone.trim().isEmpty ||
        password.isEmpty ||
        fullName.trim().isEmpty ||
        code.trim().isEmpty) {
      errorMessage.value = 'Phone, password, full name and code are required';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authRepository.verifyRegisterOtpAndRegister(
        phone: phone.trim(),
        password: password,
        fullName: fullName.trim(),
        code: code.trim(),
        verificationId: verificationId,
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        referenceCode:
            referenceCode?.trim().isEmpty == true ? null : referenceCode?.trim(),
      );
      final tokens = await _authRepository.login(
        phone: phone.trim(),
        password: password,
      );
      user.value = tokens.user;
      errorMessage.value = '';
      Get.offAllNamed('/main');
    } on DioException catch (e) {
      final err = e.response?.data;
      final msg = err is Map && err['error'] != null
          ? (err['error'] as String)
          : (e.response?.statusCode == 409
              ? 'Phone or email already registered'
              : 'Registration failed');
      errorMessage.value = msg;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    user.value = null;
    Get.offAllNamed('/login');
  }

  Future<bool> updateProfile({
    required String fullName,
    String? email,
    String? referenceCode,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final updated = await _userRepository.updateMe(
        fullName: fullName.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        referenceCode:
            referenceCode?.trim().isEmpty == true ? null : referenceCode?.trim(),
      );
      user.value = updated;
      return true;
    } on DioException catch (e) {
      final err = e.response?.data;
      String msg = 'Failed to update profile';
      if (err is Map && err['error'] != null) {
        msg = err['error'] as String;
      } else if (e.response?.statusCode == 409) {
        msg = 'Phone or email already exists';
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg = 'Network error. Check internet and try again.';
      }
      errorMessage.value = msg;
      return false;
    } catch (_) {
      errorMessage.value = 'Failed to update profile';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Restore session from refresh token. Returns true if session is valid.
  Future<bool> checkAuth() async {
    final tokens = await _authRepository.refresh();
    if (tokens != null) {
      user.value = tokens.user;
      return true;
    }
    user.value = null;
    return false;
  }
}
