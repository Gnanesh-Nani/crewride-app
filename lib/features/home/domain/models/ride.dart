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
    // Handle new format with location.coordinates
    double latitude = 0;
    double longitude = 0;

    if (json['location'] is Map<String, dynamic>) {
      final location = json['location'] as Map<String, dynamic>;
      if (location['coordinates'] is List) {
        final coords = location['coordinates'] as List<dynamic>;
        if (coords.length >= 2) {
          longitude = (coords[0] as num).toDouble();
          latitude = (coords[1] as num).toDouble();
        }
      }
    } else {
      // Fallback to old format
      latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
      longitude = (json['longitude'] as num?)?.toDouble() ?? 0;
    }

    return Waypoint(
      id: json['id']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      type: json['type'] as String?,
      orderIndex: json['orderIndex'] != null
          ? (json['orderIndex'] as num).toInt()
          : null,
    );
  }
}

class RideMember {
  final String username;
  final String fullname;
  final String? avatarurl;

  RideMember({required this.username, required this.fullname, this.avatarurl});

  factory RideMember.fromJson(Map<String, dynamic> json) {
    return RideMember(
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      avatarurl: json['avatarurl'] as String?,
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
  final String? rideMemberStatus;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final String? crewId;
  final List<Waypoint> waypoints;
  final List<RideMember> rideMembers;
  final Map<String, dynamic>? routePath;
  final int? distanceMeters;
  final bool isCreatedByYou;
  final bool isJoinedByYou;
  final String? leaderName;

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
    this.rideMemberStatus,
    this.waypoints = const [],
    this.rideMembers = const [],
    this.routePath,
    this.distanceMeters,
    this.isCreatedByYou = false,
    this.isJoinedByYou = false,
    this.leaderName,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final waypointsJson = (json['waypoints'] as List<dynamic>?) ?? [];
    final waypoints = waypointsJson
        .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
        .toList();

    final rideMembersJson = (json['rideMembers'] as List<dynamic>?) ?? [];
    final rideMembers = rideMembersJson
        .map((e) => RideMember.fromJson(e as Map<String, dynamic>))
        .toList();

    return Ride(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId']?.toString() ?? '',
      visibility: json['visibility'] ?? 'public',
      rideStatus: json['rideStatus'] ?? '',
      rideMemberStatus: json['rideMemberStatus'] as String?,
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      crewId: json['crewId']?.toString(),
      waypoints: waypoints,
      rideMembers: rideMembers,
      routePath: json['routePath'] as Map<String, dynamic>?,
      distanceMeters: json['distanceMeters'] as int?,
      isCreatedByYou: json['isCreatedByYou'] as bool? ?? false,
      isJoinedByYou: json['isJoinedByYou'] as bool? ?? false,
      leaderName: json['leaderName'] as String?,
    );
  }
}
