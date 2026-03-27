import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../models/equb_model.dart';

class EqubRepository {
  final ApiClient _api;

  EqubRepository({required ApiClient api}) : _api = api;

  Future<List<EqubModel>> list({
    bool myEqubsOnly = false,
    String? status,
    String? memberType,
    String? type,
  }) async {
    final query = <String, dynamic>{};
    if (myEqubsOnly) query['myEqubsOnly'] = 'true';
    if (status != null) query['status'] = status;
    if (memberType != null) query['memberType'] = memberType;
    if (type != null) query['type'] = type;

    final response = await _api.dio.get<List<dynamic>>(
      ApiConstants.equbs,
      queryParameters: query.isEmpty ? null : query,
      options: Options(responseType: ResponseType.json),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to load equbs',
      );
    }

    final data = response.data!;
    return data
        .map(
          (e) => EqubModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> join(String equbId) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.equbJoin(equbId),
      data: const {},
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to join equb',
      );
    }
  }

  Future<EqubModel> getById(String id) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      ApiConstants.equbById(id),
      options: Options(responseType: ResponseType.json),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to load equb',
      );
    }

    return EqubModel.fromJson(response.data!);
  }

  /// Returns rounds for an equb (from GET /api/equbs/:equbId/rounds).
  /// Each map has id, roundNumber, status (PENDING, COLLECTING, DRAWN, COMPLETED), etc.
  Future<List<Map<String, dynamic>>> getRounds(String equbId) async {
    final response = await _api.dio.get<List<dynamic>>(
      ApiConstants.equbRounds(equbId),
      options: Options(responseType: ResponseType.json),
    );

    debugPrint('getRounds($equbId) status=${response.statusCode}');
    debugPrint('getRounds($equbId) data=${response.data}');

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to load rounds',
      );
    }

    return (response.data!)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Returns full round detail including contributions (from GET /api/equbs/:equbId/rounds/:roundId).
  /// Each contribution has id, member: { user: { id, ... } }, etc.
  Future<Map<String, dynamic>> getRoundById(String equbId, String roundId) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      ApiConstants.equbRoundById(equbId, roundId),
      options: Options(responseType: ResponseType.json),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to load round details',
      );
    }

    return response.data!;
  }

  Future<void> leave(String equbId) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      ApiConstants.equbLeave(equbId),
      data: const {},
      options: Options(contentType: 'application/json'),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to leave equb',
      );
    }
  }
}

