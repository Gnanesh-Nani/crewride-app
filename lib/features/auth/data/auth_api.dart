import 'package:crewride_app/core/constants/endpoints/auth_endpoints.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';


class AuthApi {
  final Dio _dio = DioClient.instance;

  Future<Response> login({
    required String email,
    required String password,
  }) {
    return _dio.post(
      AuthEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String fullName,
  }) {
    return _dio.post(
      AuthEndpoints.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'fullName': fullName,
      },
    );
  }

  Future<Response> refreshToken() {
    return _dio.post(AuthEndpoints.refresh);
  }
}
