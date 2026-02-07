import 'package:crewride_app/core/constants/endpoints/ride_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:crewride_app/core/constants/endpoints/user_endpoints.dart';
import 'package:crewride_app/core/network/dio_client.dart';

class RideApi {
  final Dio _dio = DioClient.instance;

  Future<Response> getMyRides() {
    return _dio.get(UserEndpoints.myRides);
  }

  Future<Response> getRideById(String rideId) {
    return _dio.get('${RideEndpoints.createRide}/$rideId');
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

  Future<Response> addWaypointsWithRoute(
    String rideId,
    List<Map<String, dynamic>> waypoints,
    Map<String, dynamic> routePath,
    double distanceMeters,
  ) {
    return _dio.post(
      RideEndpoints.addWaypoints(rideId),
      data: {
        'waypoints': waypoints,
        'routePath': routePath,
        'distanceMeters': distanceMeters,
      },
    );
  }

  Future<Response> startRide(String rideId) {
    return _dio.post('${RideEndpoints.createRide}/$rideId/start');
  }

  Future<Response> endRide(String rideId) {
    return _dio.post('${RideEndpoints.createRide}/$rideId/end');
  }

  Future<Response> cancelRide(String rideId) {
    return _dio.delete('${RideEndpoints.createRide}/$rideId/cancel');
  }

  Future<Response> acceptRideInvitation(String rideId) {
    return _dio.post('${RideEndpoints.createRide}/$rideId/join');
  }

  Future<Response> searchRides(String searchText) {
    return _dio.get(
      '${RideEndpoints.searchRide}',
      queryParameters: {'text': searchText},
    );
  }
}
