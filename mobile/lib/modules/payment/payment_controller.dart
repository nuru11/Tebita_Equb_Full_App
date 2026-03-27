import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';

class PaymentController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> submitPayment({
    String? equbId,
    required String roundId,
    String? contributionId,
    required double amount,
    required String currency,
    required String imageBase64,
    String? reference,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      // 1) Upload screenshot and get URL
      final uploadResp = await _api.dio.post<Map<String, dynamic>>(
        '/api/uploads/payment',
        data: {'imageBase64': imageBase64},
        options: Options(contentType: 'application/json'),
      );
      if (uploadResp.statusCode != 201 || uploadResp.data == null) {
        throw DioException(
          requestOptions: uploadResp.requestOptions,
          response: uploadResp,
          message: 'Failed to upload screenshot',
        );
      }
      final screenshotUrl = uploadResp.data!['url'] as String;

      // 2) Create payment transaction
      final paymentResp = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.payments,
        data: {
          if (equbId != null) 'equbId': equbId,
          'roundId': roundId,
          if (contributionId != null) 'contributionId': contributionId,
          'type': 'CONTRIBUTION',
          'amount': amount,
          'currency': currency,
          'reference': reference,
          'screenshotUrl': screenshotUrl,
        },
        options: Options(contentType: 'application/json'),
      );

      if (paymentResp.statusCode != 201) {
        throw DioException(
          requestOptions: paymentResp.requestOptions,
          response: paymentResp,
          message: 'Failed to create payment',
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        errorMessage.value = data['error'] as String;
      } else {
        errorMessage.value = e.message ?? 'Payment failed';
      }
      rethrow;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }
}

