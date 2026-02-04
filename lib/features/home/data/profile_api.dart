import 'package:dio/dio.dart';
import 'package:crewride_app/core/constants/endpoints/user_endpoints.dart';
import 'package:crewride_app/core/network/dio_client.dart';

class ProfileApi {
  final Dio _dio = DioClient.instance;

  Future<Response> getUserProfile() {
    return _dio.get(UserEndpoints.myProfile);
  }

  Future<Response> updateProfile({
    required String fullName,
    required String avatarUrl,
    required String bikeModel,
    required String bikeNumber,
    required String bio,
  }) {
    return _dio.patch(
      UserEndpoints.myProfile,
      data: {
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'bikeModel': bikeModel,
        'bikeNumber': bikeNumber,
        'bio': bio,
      },
    );
  }
}
