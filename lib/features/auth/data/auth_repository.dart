import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AppUser {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String email;
  final String? profileImageUrl;
  final double? latitude;
  final double? longitude;

  AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.email,
    this.profileImageUrl,
    this.latitude,
    this.longitude,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? email,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AppUser?> signIn({
    required String phone,
    required String password,
  }) async {
    debugPrint('🔑 [AUTH REPO] Attempting login for phone: $phone');
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );

      debugPrint('🔑 [AUTH REPO] Login HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final user = AppUser.fromJson(response.data['user']);
        await saveSession(user);
        debugPrint('✅ [AUTH REPO] Login successful for user: ${user.fullName} (${user.id})');
        return user;
      }
      throw Exception('Login failed');
    } catch (e) {
      debugPrint('❌ [AUTH REPO] Login error: $e');
      if (e is DioException &&
          e.response?.data != null &&
          e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AppUser?> signUp({
    required String fullName,
    required String phone,
    required String address,
    String? email,
    required String password,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
  }) async {
    debugPrint('📝 [AUTH REPO] Attempting registration for phone: $phone');
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {
          'fullName': fullName,
          'phone': phone,
          'address': address,
          'email': email ?? '',
          'password': password,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      debugPrint('📝 [AUTH REPO] Register HTTP status: ${response.statusCode}');

      if (response.statusCode == 201) {
        var user = AppUser.fromJson(response.data['user']);
        
        await saveSession(user);
        debugPrint('✅ [AUTH REPO] Registration successful for user: ${user.fullName}');
        return user;
      }
      throw Exception('Registration failed');
    } catch (e) {
      debugPrint('❌ [AUTH REPO] Registration error: $e');
      if (e is DioException &&
          e.response?.data != null &&
          e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> saveSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(user.toJson()));
      debugPrint('💾 [AUTH REPO] Saved session locally for user: ${user.phone}');
    } catch (e) {
      debugPrint('⚠️ [AUTH REPO] Warning: Could not save local session (Rebuild app with flutter run): $e');
    }
  }

  Future<AppUser?> getPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      if (userJson != null) {
        final user = AppUser.fromJson(jsonDecode(userJson));
        debugPrint('🔓 [AUTH REPO] Restored active session for user: ${user.phone}');
        return user;
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH REPO] Failed to restore session (Rebuild app with flutter run): $e');
    }
    debugPrint('ℹ️ [AUTH REPO] No active session found.');
    return null;
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    debugPrint('🔐 [AUTH REPO] Attempting password change for user ID: $userId');
    try {
      final response = await _apiClient.dio.put(
        '/api/auth/change-password',
        data: {
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Password change failed');
      }
      debugPrint('✅ [AUTH REPO] Password changed successfully');
    } catch (e) {
      debugPrint('❌ [AUTH REPO] Password change error: $e');
      if (e is DioException &&
          e.response?.data != null &&
          e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  Future<AppUser?> changeAddress(String newAddress, {double? latitude, double? longitude}) async {
    final currentUser = await getPersistedSession();
    if (currentUser == null) throw Exception('Not logged in');

    try {
      final response = await _apiClient.dio.put(
        '/api/auth/change-address',
        data: {
          'userId': currentUser.id,
          'newAddress': newAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final updatedUser = currentUser.copyWith(
          address: newAddress,
          latitude: latitude ?? currentUser.latitude,
          longitude: longitude ?? currentUser.longitude,
        );
        await saveSession(updatedUser);
        return updatedUser;
      }
      throw Exception('Address change failed');
    } catch (e) {
      if (e is DioException && e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('Failed to change address: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      debugPrint('🚪 [AUTH REPO] Cleared local user session.');
    } catch (e) {
      debugPrint('⚠️ [AUTH REPO] Failed to clear session: $e');
    }
  }

  Future<String> updateProfileImage(String userId, String profileImageUrl) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/user/$userId/profile-image',
        data: { 'profileImageUrl': profileImageUrl },
      );

      if (response.statusCode == 200) {
        return response.data['profileImageUrl'];
      }
      throw Exception('Failed to update image');
    } catch (e) {
      if (e is DioException && e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response!.data['error']);
      }
      throw Exception('Upload failed: ${e.toString()}');
    }
  }
}
