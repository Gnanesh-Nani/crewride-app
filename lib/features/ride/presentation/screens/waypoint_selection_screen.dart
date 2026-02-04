import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crewride_app/features/home/data/ride_api.dart';

class WaypointSelectionScreen extends StatefulWidget {
  @override
  _WaypointSelectionScreenState createState() =>
      _WaypointSelectionScreenState();
}

class _WaypointSelectionScreenState extends State<WaypointSelectionScreen> {
  late Map<String, dynamic> rideData;
  String _selectedType = 'subdestination';
  List<Map<String, dynamic>> _waypoints = [];
  int _nextOrderIndex = 0;

  // MapTiler API key and URL loaded from .env file
  late final String _mapTilerApiKey = dotenv.env['MAP_TILER_API_KEY'] ?? '';
  late final String _mapTilerUrlTemplate =
      dotenv.env['MAPTILER_URL_TEMPLATE'] ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rideData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    });
  }

  void _addWaypoint(LatLng point) {
    setState(() {
      _waypoints.add({
        'type': _selectedType,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'orderIndex': _nextOrderIndex++,
      });
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added $_selectedType waypoint')));
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

    final rideId = rideData['id']?.toString();
    if (rideId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride ID missing')));
      return;
    }

    try {
      final api = RideApi();
      final res = await api.addWaypoints(rideId, _waypoints);

      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Waypoints saved!')));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data?['message'] ?? 'Failed to save waypoints'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                const Text(
                  'Select pin type then tap map:',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                              ? Colors.green
                              : Colors.grey[300],
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
                              ? Colors.orange
                              : Colors.grey[300],
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
                              ? Colors.red
                              : Colors.grey[300],
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
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(13.0827, 80.2707),
                zoom: 13,
                onTap: (tapPosition, latlng) => _addWaypoint(latlng),
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapTilerUrlTemplate
                      .replaceAll('{style}', 'streets-v2')
                      .replaceAll('{key}', _mapTilerApiKey),
                  userAgentPackageName: 'com.example.crewride_app',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(),
                  keepBuffer: 5,
                ),
                MarkerLayer(
                  markers: _waypoints.asMap().entries.map((e) {
                    final wp = e.value;
                    final idx = e.key;
                    final type = wp['type'];
                    return Marker(
                      point: LatLng(wp['latitude'], wp['longitude']),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _changeWaypointType(idx),
                        onLongPress: () => _removeWaypoint(idx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: type == 'start'
                                ? Colors.green
                                : type == 'destination'
                                ? Colors.red
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (idx + 1).toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Waypoints list
          if (_waypoints.isNotEmpty)
            Container(
              color: Colors.grey[100],
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
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 18),
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
