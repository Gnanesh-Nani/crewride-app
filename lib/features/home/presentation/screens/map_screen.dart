import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/ride_api.dart';
import '../../data/location_service.dart';
import '../../domain/models/ride.dart';
import 'package:crewride_app/features/ride/presentation/screens/create_ride_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RideApi _rideApi = RideApi();

  LatLng? _userLocation;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<Ride> _rides = [];
  int _selectedRideIndex = 0;
  final Map<String, List<LatLng>> _routeCache = {};
  bool _isLoading = true;
  String? _error;
  bool _hasInitialized = false;

  late final String _mapTilerApiKey = dotenv.env['MAP_TILER_API_KEY'] ?? '';
  late final String _mapTilerUrlTemplate =
      dotenv.env['MAPTILER_URL_TEMPLATE'] ?? '';
  late final String _osrmUrl = dotenv.env['OSRM_URL'] ?? '';

  // Keep this widget alive when switching tabs to avoid reloading map tiles
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Only initialize once
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Check if location service is enabled
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!mounted) return;

      if (!isEnabled) {
        setState(() {
          _error = 'Location services disabled. Please enable them.';
          _isLoading = false;
        });
        return;
      }

      // Get user location
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (position != null) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }

      // Load rides and create markers
      await _loadRidesAndCreateMarkers();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading map: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRidesAndCreateMarkers() async {
    try {
      final response = await _rideApi.getMyRides();
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = (data['data'] as List<dynamic>? ?? [])
              .map((e) => Ride.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() {
            _rides = list;
          });

          // Show first ride by default (if available)
          if (_rides.isNotEmpty) {
            _selectedRideIndex = 0;
            await _showRideByIndex(_selectedRideIndex);
          } else {
            // no rides: clear markers/polylines but keep user marker
            _createUserMarkerOnly();
          }
        }
      }
    } catch (e) {
      print('Error loading rides: $e');
    }
  }

  void _createUserMarkerOnly() {
    final markers = <Marker>[];
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = [];
      });
    }
  }

  Future<void> _showRideByIndex(int index) async {
    if (index < 0 || index >= _rides.length) return;
    final ride = _rides[index];

    final markers = <Marker>[];
    final polylines = <Polyline>[];

    // User marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    // Sort waypoints by orderIndex when available
    final waypoints = List.of(ride.waypoints);
    waypoints.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

    // Try to get a routed path (follows roads) from a routing service.
    List<LatLng> routePoints = [];
    try {
      final cacheKey = '${ride.id}:${waypoints.map((w) => w.id).join(',')}';
      if (_routeCache.containsKey(cacheKey)) {
        routePoints = _routeCache[cacheKey]!;
      } else if (waypoints.length >= 2) {
        routePoints = await _fetchRouteForWaypoints(waypoints);
        if (routePoints.isNotEmpty) _routeCache[cacheKey] = routePoints;
      }
    } catch (e) {
      // ignore and fallback to straight lines
      print('Routing failed, falling back to straight lines: $e');
    }

    // If routing not available, fall back to direct waypoint-to-waypoint lines
    if (routePoints.isEmpty) {
      for (final wp in waypoints) {
        routePoints.add(LatLng(wp.latitude, wp.longitude));
      }
    }

    // Markers for waypoints (use type-based icons/colors)
    for (final wp in waypoints) {
      final point = LatLng(wp.latitude, wp.longitude);
      final type = wp.type?.toLowerCase();
      Color markerColor;
      IconData markerIcon;
      switch (type) {
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

      markers.add(
        Marker(
          point: point,
          width: 56,
          height: 56,
          child: GestureDetector(
            onTap: () => _showRideDetails(ride),
            child: Icon(markerIcon, color: markerColor, size: 28),
          ),
        ),
      );
    }

    if (routePoints.length >= 2) {
      polylines.add(
        Polyline(
          points: routePoints,
          strokeWidth: 4.0,
          color: Colors.blue.withOpacity(0.8),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
        _selectedRideIndex = index;
      });

      if (routePoints.isNotEmpty) {
        try {
          _mapController.move(routePoints.first, 13);
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(routePoints.first, 13);
            } catch (_) {}
          });
        }
      } else if (_userLocation != null) {
        try {
          _mapController.move(_userLocation!, 15);
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(_userLocation!, 15);
            } catch (_) {}
          });
        }
      }
    }
  }

  Future<List<LatLng>> _fetchRouteForWaypoints(List waypoints) async {
    // Use OSRM public demo server to get a driving route that follows roads.
    // Coordinates must be longitude,latitude and separated by ';'
    final coords = waypoints
        .map((w) => '${w.longitude},${w.latitude}')
        .join(';');
    final url = '${_osrmUrl}/$coords?overview=full&geometries=geojson';
    final dio = Dio();
    final res = await dio.get(url);
    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
        if (geometry != null && geometry['coordinates'] is List) {
          final coordsList = geometry['coordinates'] as List<dynamic>;
          return coordsList.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();
        }
      }
    }
    return [];
  }

  void _showRideDetails(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ride.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ride.description ?? 'No description'),
            const SizedBox(height: 8),
            Text('Start Time: ${ride.startTime}'),
            if (ride.visibility != null) Text('Visibility: ${ride.visibility}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    try {
      // Get fresh current location from device
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = newLocation;
          // Update the user marker in the markers list
          _updateUserMarker();
        });
        // Move map to current location
        _mapController.move(newLocation, 15);
      } else if (_userLocation != null) {
        // Fallback to cached location if getting new location fails
        _mapController.move(_userLocation!, 15);
      }
    } catch (e) {
      // If error, try to use cached location
      if (_userLocation != null) {
        _mapController.move(_userLocation!, 15);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  void _updateUserMarker() {
    if (_userLocation == null) return;

    // Remove existing user location marker and add updated one
    _markers = _markers.where((marker) {
      // Check if this is the user marker by comparing with user location
      return marker.child is! Icon ||
          (marker.child as Icon).icon != Icons.my_location;
    }).toList();

    // Add updated user location marker at the beginning
    _markers.insert(
      0,
      Marker(
        point: _userLocation!,
        width: 80,
        height: 80,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin
    super.build(context);

    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error Loading Map', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeMap();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Use dark map style when in dark mode
    final isDarkMode = theme.brightness == Brightness.dark;
    final mapStyle = isDarkMode ? 'streets-v2-dark' : 'streets-v2';

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? const LatLng(13.0827, 80.2707),
          initialZoom: 15,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: _mapTilerUrlTemplate
                .replaceAll('{style}', mapStyle)
                .replaceAll('{key}', _mapTilerApiKey),
            userAgentPackageName: 'com.example.crewride_app',
            maxZoom: 19,
            // Enable tile caching to reduce API calls
            tileProvider: NetworkTileProvider(),
            keepBuffer: 5, // Keep 5 tiles buffer around viewport
          ),
          if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _centerOnUserLocation,
            tooltip: 'My Location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          // Ride selector: show current ride title and prev/next buttons
          if (_rides.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _selectedRideIndex > 0
                        ? () => _showRideByIndex(_selectedRideIndex - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _rides[_selectedRideIndex].title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedRideIndex < _rides.length - 1
                        ? () => _showRideByIndex(_selectedRideIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'start_ride',
            onPressed: () async {
              // Open create ride screen and refresh rides on success
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateRideScreen()),
              );
              if (res == true) {
                setState(() {
                  _isLoading = true;
                });
                await _loadRidesAndCreateMarkers();
                setState(() {
                  _isLoading = false;
                });
              }
            },
            icon: const Icon(Icons.directions_bike),
            label: const Text('Create Ride'),
          ),
        ],
      ),
    );
  }
}
