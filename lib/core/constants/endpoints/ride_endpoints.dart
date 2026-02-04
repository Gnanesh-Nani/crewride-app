class RideEndpoints {
  static const String createRide = '/ride';
  static String addWaypoints(String rideId) => '/ride/$rideId/waypoints';
}
