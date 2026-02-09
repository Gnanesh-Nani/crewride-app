import 'package:crewride_app/features/home/domain/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RideMapWidget extends StatelessWidget {
  final List<Waypoint> waypoints;

  const RideMapWidget({super.key, required this.waypoints});

  List<Marker> _buildMapMarkers(List<Waypoint> waypoints) {
    return waypoints.map((waypoint) {
      final isStart = waypoint.type == 'start';
      final isDestination = waypoint.type == 'destination';

      return Marker(
        point: LatLng(waypoint.latitude, waypoint.longitude),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStart
                ? Colors.black
                : isDestination
                ? Colors.red
                : Colors.blue,
          ),
          width: 16,
          height: 16,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();
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
                initialZoom: 13,
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
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: waypoints
                          .map((w) => LatLng(w.latitude, w.longitude))
                          .toList(),
                      strokeWidth: 3,
                      color: Colors.blue.withOpacity(0.6),
                    ),
                  ],
                ),
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
