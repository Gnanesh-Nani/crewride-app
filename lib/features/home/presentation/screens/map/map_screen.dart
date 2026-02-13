import 'package:flutter/material.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../data/ride_api.dart';
import '../../../data/location_service.dart';
import '../../../domain/models/ride.dart';
import 'widgets/index.dart';

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
  String? _currentUserId;
  bool _isLoading = true;
  String? _error;
  bool _hasInitialized = false;
  bool _isCardCollapsed = false;

  late final String _mapTilerApiKey = dotenv.env['MAP_TILER_API_KEY'] ?? '';
  late final String _mapTilerUrlTemplate =
      dotenv.env['MAPTILER_URL_TEMPLATE'] ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeMap();
      _loadAndExtractUserId();
    }
  }

  Future<void> _selectRideById(String rideId) async {
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
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!mounted) return;

      if (!isEnabled) {
        setState(() {
          _error = 'Location services disabled. Please enable them.';
          _isLoading = false;
        });
        return;
      }

      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (position != null) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }

      await _loadRidesAndCreateMarkers();
      if (!mounted) return;

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
          final dataObject = data['data'] as Map<String, dynamic>?;
          final ridesList = dataObject?['rides'] as List<dynamic>? ?? [];

          final list = ridesList
              .whereType<Map<String, dynamic>>()
              .map((item) => Ride.fromJson(item))
              .toList();

          setState(() {
            _rides = list;
          });

          if (_rides.isNotEmpty) {
            _selectedRideIndex = 0;
            await _showRideByIndex(_selectedRideIndex);
          } else {
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
      markers.add(createUserLocationMarker(_userLocation!));
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
      markers.add(createUserLocationMarker(_userLocation!));
    }

    // Sort waypoints
    final waypoints = List.of(ride.waypoints);
    waypoints.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

    // Get route points
    List<LatLng> routePoints = [];

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

    if (routePoints.isEmpty) {
      for (final wp in waypoints) {
        routePoints.add(LatLng(wp.latitude, wp.longitude));
      }
    }

    // Add waypoint markers
    for (final wp in waypoints) {
      final point = LatLng(wp.latitude, wp.longitude);
      markers.add(
        buildWaypointMarker(
          point: point,
          type: wp.type,
          onTap: () => _showRideDetails(ride),
        ),
      );
    }

    // Add polyline
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

  void _showRideDetails(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RideDetailsSheet(
        ride: ride,
        currentUserId: _currentUserId,
        onStartRide: () async {
          Navigator.pop(context);
          await _startRide(ride.id, ride.title);
        },
        onCancelRide: () async {
          Navigator.pop(context);
          await _cancelRide(ride.id, ride.title);
        },
        onEndRide: () async {
          Navigator.pop(context);
          await _endRide(ride.id, ride.title);
        },
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
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = newLocation;
          _updateUserMarker();
        });
        _mapController.move(newLocation, 15);
      } else if (_userLocation != null) {
        _mapController.move(_userLocation!, 15);
      }
    } catch (e) {
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

    _markers = _markers.where((marker) {
      return marker.child is! Stack;
    }).toList();

    _markers.insert(0, createUserLocationMarker(_userLocation!));
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      body: Stack(
        children: [
          // Map display
          MapDisplay(
            mapController: _mapController,
            userLocation: _userLocation,
            markers: _markers,
            polylines: _polylines,
            mapTilerUrlTemplate: _mapTilerUrlTemplate,
            mapTilerApiKey: _mapTilerApiKey,
          ),
          // Search bar overlay (top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: RideSearchBar(
                onSearch: (query) {
                  // TODO: Implement search filtering
                },
              ),
            ),
          ),
          // Map controls (floating) - moves with card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _isCardCollapsed ? 70 : 280,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                // Layers button
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  onPressed: () {
                    // TODO: Show map layers options
                  },
                  tooltip: 'Map Layers',
                  child: Icon(Icons.layers, color: theme.colorScheme.primary),
                ),
                // Location button
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  onPressed: _centerOnUserLocation,
                  tooltip: 'My Location',
                  child: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _rides.isNotEmpty
          ? RideInfoCard(
              ride: _rides[_selectedRideIndex],
              rideNumber: _selectedRideIndex + 1,
              totalRides: _rides.length,
              hasPrevious: _selectedRideIndex > 0,
              hasNext: _selectedRideIndex < _rides.length - 1,
              isCollapsed: _isCardCollapsed,
              onPrevious: _selectedRideIndex > 0
                  ? () => _showRideByIndex(_selectedRideIndex - 1)
                  : () {},
              onNext: _selectedRideIndex < _rides.length - 1
                  ? () => _showRideByIndex(_selectedRideIndex + 1)
                  : () {},
              onToggleCollapse: () {
                setState(() {
                  _isCardCollapsed = !_isCardCollapsed;
                });
              },
              onStartRide: () async {
                final ride = _rides[_selectedRideIndex];
                await _startRide(ride.id, ride.title);
              },
            )
          : null,
    );
  }
}
