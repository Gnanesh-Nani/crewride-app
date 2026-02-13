import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Builds user location marker widget
Widget buildUserLocationMarker() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
    ],
  );
}

/// Creates a marker for user location
Marker createUserLocationMarker(LatLng location) {
  return Marker(
    point: location,
    width: 80,
    height: 80,
    child: buildUserLocationMarker(),
  );
}

/// Builds waypoint marker with type-based styling
Marker buildWaypointMarker({
  required LatLng point,
  required String? type,
  required VoidCallback onTap,
}) {
  String waypointType = type?.toLowerCase() ?? 'stop';
  Color markerColor;
  IconData markerIcon;

  switch (waypointType) {
    case 'start':
      markerColor = Colors.green;
      markerIcon = Icons.play_arrow;
      break;
    case 'destination':
      markerColor = Colors.red;
      markerIcon = Icons.flag;
      break;
    default:
      markerColor = Colors.orange;
      markerIcon = Icons.location_on;
  }

  return Marker(
    point: point,
    width: 56,
    height: 56,
    child: GestureDetector(
      onTap: onTap,
      child: Icon(markerIcon, color: markerColor, size: 28),
    ),
  );
}
