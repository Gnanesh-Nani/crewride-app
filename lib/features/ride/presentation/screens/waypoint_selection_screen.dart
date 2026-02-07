import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crewride_app/features/home/data/ride_api.dart';
import 'package:geolocator/geolocator.dart';

class _PinPainter extends CustomPainter {
  final Color color;

  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw shadow
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.7),
      12,
      shadowPaint,
    );

    // Draw pin circle (top part)
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.35), 12, paint);

    // Draw pin triangle point (bottom)
    final trianglePath = ui.Path();
    trianglePath.moveTo(size.width / 2 - 12, size.height * 0.35);
    trianglePath.lineTo(size.width / 2 + 12, size.height * 0.35);
    trianglePath.lineTo(size.width / 2, size.height);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // Draw white border around circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      12,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

class WaypointSelectionScreen extends StatefulWidget {
  const WaypointSelectionScreen({super.key});

  @override
  _WaypointSelectionScreenState createState() =>
      _WaypointSelectionScreenState();
}

class _WaypointSelectionScreenState extends State<WaypointSelectionScreen> {
  late Map<String, dynamic> rideData;
  String _selectedType = 'start';
  final List<Map<String, dynamic>> _waypoints = [];
  int _nextOrderIndex = 0;
  late LatLng _currentLocation;
  bool _locationLoaded = false;

  // MapTiler API key and URL loaded from .env file
  late final String _mapTilerApiKey = dotenv.env['MAP_TILER_API_KEY'] ?? '';
  late final String _mapTilerUrlTemplate =
      dotenv.env['MAPTILER_URL_TEMPLATE'] ?? '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rideData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
    } catch (e) {
      // Fallback to default location if permission denied or error
      setState(() {
        _currentLocation = LatLng(13.0827, 80.2707);
        _locationLoaded = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Using default location. Error: $e')),
        );
      }
    }
  }

  void _addWaypoint(LatLng point) {
    // Check if trying to add duplicate start or destination
    if (_selectedType == 'start') {
      final hasStart = _waypoints.any((w) => w['type'] == 'start');
      if (hasStart) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only add one START waypoint')),
        );
        return;
      }
    } else if (_selectedType == 'destination') {
      final hasDest = _waypoints.any((w) => w['type'] == 'destination');
      if (hasDest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only add one DESTINATION waypoint'),
          ),
        );
        return;
      }
    }

    setState(() {
      _waypoints.add({
        'type': _selectedType,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'orderIndex': _nextOrderIndex++,
      });
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
  }

  void _changeWaypointType(int index) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change waypoint type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'start'),
            child: const Text('Start'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'subdestination'),
            child: const Text('Subdestination'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'destination'),
            child: const Text('Destination'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() {
        _waypoints[index]['type'] = selected;
      });
    }
  }

  Future<void> _submitWaypoints() async {
    final startCount = _waypoints.where((w) => w['type'] == 'start').length;
    final destCount = _waypoints
        .where((w) => w['type'] == 'destination')
        .length;

    if (startCount != 1 || destCount != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must have exactly 1 START and 1 DESTINATION'),
        ),
      );
      return;
    }

    if (_waypoints.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least 2 waypoints')));
      return;
    }

    // Return waypoints back to create_ride_screen
    if (mounted) {
      Navigator.pop(context, _waypoints);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Waypoints')),
      body: Column(
        children: [
          // Type selection buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select pin type then tap map:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedType = 'start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'start'
                              ? Theme.of(context).colorScheme.primary
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey[300]),
                          foregroundColor: _selectedType == 'start'
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        ),
                        child: const Text('START'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedType = 'subdestination'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'subdestination'
                              ? Theme.of(context).colorScheme.primary
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey[300]),
                          foregroundColor: _selectedType == 'subdestination'
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        ),
                        child: const Text('SUBDEST'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedType = 'destination'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'destination'
                              ? Theme.of(context).colorScheme.primary
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey[300]),
                          foregroundColor: _selectedType == 'destination'
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        ),
                        child: const Text('DEST'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: _locationLoaded
                ? FlutterMap(
                    options: MapOptions(
                      center: _currentLocation,
                      zoom: 17,
                      onTap: (tapPosition, latlng) => _addWaypoint(latlng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _mapTilerUrlTemplate
                            .replaceAll(
                              '{style}',
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'streets-v2-dark'
                                  : 'streets-v2',
                            )
                            .replaceAll('{key}', _mapTilerApiKey),
                        userAgentPackageName: 'com.example.crewride_app',
                        maxZoom: 19,
                        tileProvider: NetworkTileProvider(),
                        keepBuffer: 5,
                      ),
                      MarkerLayer(
                        markers: [
                          // Current location marker
                          Marker(
                            point: _currentLocation,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    width: 40,
                                    height: 40,
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 16,
                                    height: 16,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Waypoint markers
                          ..._waypoints.asMap().entries.map((e) {
                            final wp = e.value;
                            final idx = e.key;
                            final type = wp['type'];
                            Color pinColor;
                            if (type == 'start') {
                              pinColor = Colors.green;
                            } else if (type == 'destination') {
                              pinColor = Colors.red;
                            } else {
                              pinColor = Colors.orange;
                            }

                            return Marker(
                              point: LatLng(wp['latitude'], wp['longitude']),
                              width: 50,
                              height: 60,
                              child: GestureDetector(
                                onTap: () => _changeWaypointType(idx),
                                onLongPress: () => _removeWaypoint(idx),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Pin shape
                                    CustomPaint(
                                      painter: _PinPainter(pinColor),
                                      size: const Size(40, 50),
                                    ),
                                    // Number in pin
                                    Positioned(
                                      top: 10,
                                      child: Text(
                                        (idx + 1).toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // Waypoints list
          if (_waypoints.isNotEmpty)
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey[100],
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _waypoints.length,
                  itemBuilder: (context, index) {
                    final wp = _waypoints[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${index + 1}. ${wp['type']} (${wp['latitude'].toStringAsFixed(4)}, ${wp['longitude'].toStringAsFixed(4)})',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        onPressed: () => _removeWaypoint(index),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Submit button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    onPressed: _submitWaypoints,
                    label: const Text('Submit Waypoints'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
