import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationApi {
  final Dio _dio;

  LocationApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// Get user's friends list with their locations
  Future<Response> getFriendsLocations() async {
    try {
      final response = await _dio.get('/api/location/friends');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's current location
  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/api/location/update',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Start sharing location
  Future<Response> startLocationSharing() async {
    try {
      final response = await _dio.post('/api/location/start-sharing');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Stop sharing location
  Future<Response> stopLocationSharing() async {
    try {
      final response = await _dio.post('/api/location/stop-sharing');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get specific friend's location
  Future<Response> getFriendLocation(String friendId) async {
    try {
      final response = await _dio.get('/api/location/friend/$friendId');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
