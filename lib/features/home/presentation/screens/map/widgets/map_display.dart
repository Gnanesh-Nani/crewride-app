import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget that displays the interactive map with tiles, polylines, and markers
class MapDisplay extends StatelessWidget {
  final MapController mapController;
  final LatLng? userLocation;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final String mapTilerUrlTemplate;
  final String mapTilerApiKey;

  const MapDisplay({
    super.key,
    required this.mapController,
    this.userLocation,
    required this.markers,
    required this.polylines,
    required this.mapTilerUrlTemplate,
    required this.mapTilerApiKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mapStyle = isDarkMode ? 'streets-v2-dark' : 'streets-v2';

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userLocation ?? const LatLng(13.0827, 80.2707),
        initialZoom: 15,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: mapTilerUrlTemplate
              .replaceAll('{style}', mapStyle)
              .replaceAll('{key}', mapTilerApiKey),
          userAgentPackageName: 'com.example.crewride_app',
          maxZoom: 19,
          tileProvider: NetworkTileProvider(),
          keepBuffer: 5,
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
