class Waypoint {
  final String id;
  final double latitude;
  final double longitude;
  final String? type;
  final int? orderIndex;

  Waypoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.type,
    this.orderIndex,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String?,
      orderIndex: json['orderIndex'] != null
          ? (json['orderIndex'] as num).toInt()
          : null,
    );
  }
}

class Ride {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String visibility;
  final String rideStatus;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final String? crewId;
  final List<Waypoint> waypoints;

  Ride({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.visibility,
    required this.rideStatus,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.crewId,
    this.waypoints = const [],
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final waypointsJson = (json['waypoints'] as List<dynamic>?) ?? [];
    final waypoints = waypointsJson
        .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return Ride(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId']?.toString() ?? '',
      visibility: json['visibility'] ?? 'public',
      rideStatus: json['rideStatus'] ?? '',
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      crewId: json['crewId']?.toString(),
      waypoints: waypoints,
    );
  }
}
