import 'package:crewride_app/core/constants/endpoints/ride_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:crewride_app/core/constants/endpoints/user_endpoints.dart';
import 'package:crewride_app/core/network/dio_client.dart';

class RideApi {
  final Dio _dio = DioClient.instance;

  Future<Response> getMyRides() {
    return _dio.get(UserEndpoints.myRides);
  }

  Future<Response> createRide({required String title, String? description}) {
    return _dio.post(
      RideEndpoints.createRide,
      data: {'title': title, 'description': description ?? ''},
    );
  }

  Future<Response> addWaypoints(
    String rideId,
    List<Map<String, dynamic>> waypoints,
  ) {
    return _dio.post(
      RideEndpoints.addWaypoints(rideId),
      data: {'waypoints': waypoints},
    );
  }
}
