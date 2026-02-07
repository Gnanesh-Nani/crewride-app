class RideEndpoints {
  static const String createRide = '/ride';
    static String searchRide = '/ride/search';
  static String addWaypoints(String rideId) => '/ride/$rideId/waypoints';
}
