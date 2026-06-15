import 'package:dio/dio.dart';
import 'dart:io';

class ApiClient {
  // If testing on Android emulator, use 10.0.2.2. 
  // If testing on iOS simulator, use localhost or 127.0.0.1.
  // Assuming your Node.js server will run on port 3000.
  static final String _baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:3000/v1' 
      : 'http://localhost:3000/v1';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Dio get dio => _dio;
}