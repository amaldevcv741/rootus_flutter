import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiClient {
  // Uses adb reverse to map device localhost to PC localhost
  // static const String baseUrl = 'https://mushroom-backend-jnks.onrender.com';
  static const String baseUrl = 'http://127.0.0.1:3000'; // Local development

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint('🌐 [API LOG] $object'),
      ),
    );

  Dio get dio => _dio;
}