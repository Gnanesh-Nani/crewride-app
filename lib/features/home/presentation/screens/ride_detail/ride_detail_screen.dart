import 'package:crewride_app/features/home/data/ride_api.dart';
import 'package:crewride_app/features/home/domain/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import 'widgets/ride_map_widget.dart';
import 'widgets/ride_header_info_widget.dart';
import 'widgets/ride_members_waypoints_widget.dart';

class RideDetailScreen extends StatefulWidget {
  final String rideId;

  const RideDetailScreen({super.key, required this.rideId});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final RideApi _rideApi = RideApi();
  late Future<Ride> _rideFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _rideFuture = _loadRideDetails();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthStorage.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<Ride> _loadRideDetails() async {
    final response = await _rideApi.getRideById(widget.rideId);
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rideData = data['data'] as Map<String, dynamic>?;
        final rideJson = rideData?['ride'] as Map<String, dynamic>?;
        if (rideJson != null) {
          return Ride.fromJson(rideJson);
        }
      }
    }
    throw Exception('Failed to load ride details');
  }

  String _getTimeUntilStart(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.isNegative) {
      return 'Ride Started';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'in ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'in ${hours}h ${minutes}m';
    } else {
      return 'in ${minutes}m';
    }
  }

  bool _isRideTimeOver(DateTime endTime) {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }

  Widget _buildActionButton(Ride ride, BuildContext context) {
    final status = ride.rideStatus.toLowerCase();
    final isStarted = status == 'started';
    final isCreated = status == 'created';
    final isEnded = status == 'ended';
    final isCancelled = status == 'cancelled';
    final isJoined = ride.isJoinedByYou;
    final isCreator = _currentUserId == ride.creatorId;
    final startTimeHasPassed = ride.startTime.isBefore(DateTime.now());
    final now = DateTime.now();
    final isRideTime =
        now.isAfter(ride.startTime) && now.isBefore(ride.endTime);
    final isRideTimeOver = _isRideTimeOver(ride.endTime);

    // Don't show button for ended or cancelled rides
    if (isEnded || isCancelled) {
      return const SizedBox.shrink();
    }

    // Show "Admin forgot to start" message if ride end time has passed and not started
    if (isCreated && isRideTimeOver) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            // Handle missed schedule action if needed
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SCHEDULE MISSED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show "View On Map" if ride is started and user has joined
    if (isStarted && isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Redirecting to live map...')),
            );
            // TODO: Navigate to map screen
            // Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(rideId: ride.id)));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'VIEW ON MAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show "START RIDE" if creator and it's ride time
    if (isCreated && isCreator && isRideTime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            try {
              await _rideApi.startRide(ride.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Ride started!')));
              setState(() {
                _rideFuture = _loadRideDetails();
              });
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'START RIDE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show countdown for created rides (for members or before ride time for creator)
    if (isCreated) {
      // If user hasn't joined yet, show join button
      if (!isJoined && !startTimeHasPassed) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () async {
              try {
                final response = await _rideApi.acceptRideInvitation(ride.id);
                if (response.statusCode == 200 || response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined ride successfully!')),
                  );
                  setState(() {
                    _rideFuture = _loadRideDetails();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to join: ${response.statusMessage}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'JOIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show disabled join button if start time has passed
      if (!isJoined && startTimeHasPassed) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'RIDE STARTED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      }

      // Show countdown for joined members waiting for ride to start
      if (isJoined && !isRideTime) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                _getTimeUntilStart(ride.startTime),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ride Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
      ),
      body: FutureBuilder<Ride>(
        future: _rideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text('Failed to load ride details'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _rideFuture = _loadRideDetails();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final ride = snapshot.data!;
          final distance = (ride.distanceMeters ?? 0) / 1000;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map Section
                    RideMapWidget(waypoints: ride.waypoints),

                    // Header and Stats Section
                    RideHeaderInfoWidget(ride: ride, distance: distance),
                    const SizedBox(height: 16),

                    // Members and Waypoints Section
                    RideMembersWaypointsWidget(ride: ride),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              // Action Button - Fixed at bottom right
              Positioned(
                bottom: 32,
                right: 24,
                child: _buildActionButton(ride, context),
              ),
            ],
          );
        },
      ),
    );
  }
}
