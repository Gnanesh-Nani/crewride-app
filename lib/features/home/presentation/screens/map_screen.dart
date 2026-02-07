import 'package:flutter/material.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../data/ride_api.dart';
import '../../data/location_service.dart';
import '../../domain/models/ride.dart';
import 'package:crewride_app/features/ride/presentation/screens/create_ride_screen.dart';

class MapScreen extends StatefulWidget {
  final String? selectedRideId;

  const MapScreen({super.key, this.selectedRideId});

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
  String? _currentUserId;
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
      _loadAndExtractUserId(); // Load user ID from storage
    }
  }

  Future<void> _selectRideById(String rideId) async {
    // Find the ride with the matching ID
    final rideIndex = _rides.indexWhere((ride) => ride.id == rideId);
    if (rideIndex != -1) {
      await _showRideByIndex(rideIndex);
    }
  }

  Future<void> _loadAndExtractUserId() async {
    try {
      final userId = await AuthStorage.getCurrentUserId();
      if (userId != null && mounted) {
        setState(() {
          _currentUserId = userId;
        });
        print('Current user ID: $userId');
      }
    } catch (e) {
      print('Error loading user ID: $e');
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

      // If a specific ride was requested, select it
      if (widget.selectedRideId != null) {
        await _selectRideById(widget.selectedRideId!);
      }

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
          // Extract rides from data.data.rides
          final dataObject = data['data'] as Map<String, dynamic>?;
          final ridesList = dataObject?['rides'] as List<dynamic>? ?? [];

          // Convert ride objects to Ride model instances
          final list = ridesList
              .whereType<Map<String, dynamic>>()
              .map((item) => Ride.fromJson(item))
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

  Widget _buildUserLocationMarker() {
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

  void _createUserMarkerOnly() {
    final markers = <Marker>[];
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 80,
          height: 80,
          child: _buildUserLocationMarker(),
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
          child: _buildUserLocationMarker(),
        ),
      );
    }

    // Sort waypoints by orderIndex when available
    final waypoints = List.of(ride.waypoints);
    waypoints.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

    // Get routed path from the ride object
    List<LatLng> routePoints = [];

    // First, try to use the routePath from the ride object (GeoJSON format)
    if (ride.routePath != null) {
      try {
        final geometry = ride.routePath as Map<String, dynamic>;
        if (geometry['type'] == 'LineString' &&
            geometry['coordinates'] is List) {
          final coordsList = geometry['coordinates'] as List<dynamic>;
          routePoints = coordsList.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();
        }
      } catch (e) {
        print('Error parsing routePath: $e');
      }
    }

    // If routePath is not available, fall back to direct waypoint-to-waypoint lines
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
    final url = '$_osrmUrl/$coords?overview=full&geometries=geojson';
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
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('MMM dd, yyyy - HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(ride.rideStatus),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ride.rideStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusTextColor(ride.rideStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ride.visibility == 'public'
                        ? Colors.blue[100]
                        : Colors.purple[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ride.visibility == 'public' ? Icons.public : Icons.lock,
                        size: 14,
                        color: ride.visibility == 'public'
                            ? Colors.blue[800]
                            : Colors.purple[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ride.visibility.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ride.visibility == 'public'
                              ? Colors.blue[800]
                              : Colors.purple[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (ride.description.isNotEmpty) ...{
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ride.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            },

            // Schedule section
            Text(
              'Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            formatter.format(ride.startTime),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[300], height: 16),
                  Row(
                    children: [
                      Icon(Icons.flag, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            formatter.format(ride.endTime),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Waypoints section
            if (ride.waypoints.isNotEmpty) ...{
              Text(
                'Waypoints (${ride.waypoints.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ride.waypoints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final wp = ride.waypoints[index];
                  final type = wp.type?.toLowerCase() ?? 'stop';
                  Color typeColor;
                  IconData typeIcon;
                  String typeLabel;

                  switch (type) {
                    case 'start':
                      typeColor = Colors.green;
                      typeIcon = Icons.play_arrow;
                      typeLabel = 'Start';
                      break;
                    case 'destination':
                      typeColor = Colors.red;
                      typeIcon = Icons.flag;
                      typeLabel = 'Destination';
                      break;
                    default:
                      typeColor = Colors.orange;
                      typeIcon = Icons.location_on;
                      typeLabel = 'Waypoint';
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: typeColor.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Icon(typeIcon, color: typeColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            },

            // Meta info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        formatter.format(ride.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                // Start Ride button (only if creator and ride is created)
                if (_currentUserId == ride.creatorId &&
                    ride.rideStatus == 'created')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _startRide(ride.id, ride.title);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                // Cancel button (only if creator and ride is created)
                if (_currentUserId == ride.creatorId &&
                    ride.rideStatus == 'created') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _cancelRide(ride.id, ride.title);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // End Ride button (only if creator and ride is started)
                if (_currentUserId == ride.creatorId &&
                    ride.rideStatus == 'started')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _endRide(ride.id, ride.title);
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('End Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRide(String rideId, String rideName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting ride...'),
          duration: Duration(seconds: 1),
        ),
      );

      final response = await _rideApi.startRide(rideId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$rideName started successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh the ride list
          await _loadRidesAndCreateMarkers();
        }
      } else {
        final errorMessage = response.data is Map<String, dynamic>
            ? response.data['message'] ?? 'Failed to start ride'
            : 'Failed to start ride';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _cancelRide(String rideId, String rideName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancelling ride...'),
          duration: Duration(seconds: 1),
        ),
      );

      final response = await _rideApi.cancelRide(rideId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$rideName cancelled successfully!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh the ride list
          await _loadRidesAndCreateMarkers();
        }
      } else {
        final errorMessage = response.data is Map<String, dynamic>
            ? response.data['message'] ?? 'Failed to cancel ride'
            : 'Failed to cancel ride';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _endRide(String rideId, String rideName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ending ride...'),
          duration: Duration(seconds: 1),
        ),
      );

      final response = await _rideApi.endRide(rideId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$rideName ended successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh the ride list
          await _loadRidesAndCreateMarkers();
        }
      } else {
        final errorMessage = response.data is Map<String, dynamic>
            ? response.data['message'] ?? 'Failed to end ride'
            : 'Failed to end ride';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
      return marker.child is! Stack;
    }).toList();

    // Add updated user location marker at the beginning
    _markers.insert(
      0,
      Marker(
        point: _userLocation!,
        width: 80,
        height: 80,
        child: _buildUserLocationMarker(),
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.blue[100]!;
      case 'started':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      case 'ended':
        return Colors.grey[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.blue[800]!;
      case 'started':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      case 'ended':
        return Colors.grey[800]!;
      default:
        return Colors.grey[800]!;
    }
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Ride selector at top (optional when rides exist)
            if (_rides.isNotEmpty) ...{
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 20,
                      onPressed: _selectedRideIndex > 0
                          ? () => _showRideByIndex(_selectedRideIndex - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          _rides[_selectedRideIndex].title,
                          style: Theme.of(context).textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 20,
                      onPressed: _selectedRideIndex < _rides.length - 1
                          ? () => _showRideByIndex(_selectedRideIndex + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            },
            // Primary and secondary buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User location button on the left
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _centerOnUserLocation,
                  tooltip: 'My Location',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(width: 12),
                // Start Ride button (medium)
                FloatingActionButton(
                  heroTag: 'start_ride_action',
                  onPressed: () {
                    if (_rides.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Create a ride first to start one'),
                        ),
                      );
                      return;
                    }
                    // TODO: Implement start ride logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting ride...')),
                    );
                  },
                  tooltip: 'Start Ride',
                  child: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                // Create Ride button (primary) on the right
                FloatingActionButton(
                  heroTag: 'start_ride',
                  onPressed: () async {
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
                  tooltip: 'Create Ride',
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [Icon(Icons.directions_bike, size: 28)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
