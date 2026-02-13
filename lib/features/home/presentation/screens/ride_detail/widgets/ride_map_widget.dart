import 'package:crewride_app/features/home/domain/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RideMapWidget extends StatelessWidget {
  final List<Waypoint> waypoints;
  final double initialZoom;
  final Map<String, dynamic>? routePath;

  const RideMapWidget({
    super.key,
    required this.waypoints,
    this.initialZoom = 17,
    this.routePath,
  });

  Widget _buildPinMarker(String? waypointType, int waypointNumber) {
    Color pinColor;

    if (waypointType == 'start') {
      pinColor = Colors.green;
    } else if (waypointType == 'destination') {
      pinColor = Colors.red;
    } else {
      pinColor = Colors.yellow[700] ?? Colors.yellow;
    }

    return Icon(
      Icons.location_on,
      color: pinColor,
      size: 40,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  List<Marker> _buildMapMarkers(List<Waypoint> waypoints) {
    int waypointCounter = 1;
    return waypoints.map((waypoint) {
      int currentNumber = waypointCounter;

      // Only increment counter for subdestinations (not start or destination)
      if (waypoint.type != 'start' && waypoint.type != 'destination') {
        waypointCounter++;
      }

      return Marker(
        point: LatLng(waypoint.latitude, waypoint.longitude),
        width: 40,
        height: 50,
        alignment: Alignment.center,
        child: _buildPinMarker(waypoint.type, currentNumber),
      );
    }).toList();
  }

  List<Polyline> _buildPolylines() {
    // If routePath is available, use it
    if (routePath != null) {
      final coordinates = routePath!['coordinates'] as List<dynamic>?;
      if (coordinates != null && coordinates.isNotEmpty) {
        final points = coordinates
            .whereType<List<dynamic>>()
            .where((coord) => coord.length >= 2)
            .map(
              (coord) => LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ),
            )
            .toList();

        if (points.isNotEmpty) {
          return [
            Polyline(
              points: points,
              strokeWidth: 8,
              color: Colors.blue.withOpacity(0.6),
            ),
          ];
        }
      }
    }

    // Fallback to connecting waypoints
    return [
      Polyline(
        points: waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList(),
        strokeWidth: 8,
        color: Colors.blue.withOpacity(0.6),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      color: Colors.grey[300],
      child: waypoints.isNotEmpty
          ? FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  waypoints[0].latitude,
                  waypoints[0].longitude,
                ),
                initialZoom: initialZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.crewride.crewride_app',
                ),
                MarkerLayer(markers: _buildMapMarkers(waypoints)),
                PolylineLayer(polylines: _buildPolylines()),
              ],
            )
          : Stack(
              children: [
                Container(color: Colors.grey[200]),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 192,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Colors.grey[50]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
