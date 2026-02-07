import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/ride_api.dart';
import '../../domain/models/ride.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import '../home_screen.dart';
import 'ride_detail_screen.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  final RideApi _rideApi = RideApi();
  late Future<Map<String, dynamic>> _ridesFuture;
  String? _currentUserId;
  bool _isSearchExpanded = false;
  late TextEditingController _searchController;
  List<Ride> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Ride status constants
  static const String STATUS_CREATED = 'created';
  static const String STATUS_STARTED = 'started';
  static const String STATUS_ENDED = 'ended';
  static const String STATUS_CANCELLED = 'cancelled';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadCurrentUserId();
    _ridesFuture = _loadRides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthStorage.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<List<Ride>> _searchRides(String searchText) async {
    if (searchText.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return [];
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _rideApi.searchRides(searchText);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // New format: data is directly an array
          final ridesList = data['data'] as List<dynamic>? ?? [];

          final rides = ridesList.whereType<Map<String, dynamic>>().map((e) {
            final now = DateTime.now();
            // Provide defaults for missing fields
            return Ride.fromJson({
              ...e,
              'startTime': e['startTime'] ?? now.toIso8601String(),
              'endTime':
                  e['endTime'] ??
                  now.add(const Duration(hours: 1)).toIso8601String(),
              'createdAt': e['createdAt'] ?? now.toIso8601String(),
              'rideStatus': e['rideStatus'] ?? 'created',
              'creatorId': e['creatorId'] ?? '',
              'visibility': e['visibility'] ?? 'public',
              'rideMemberStatus': e['rideMemberStatus'] ?? 'PENDING',
            });
          }).toList();

          setState(() {
            _searchResults = rides;
            _hasSearched = true;
            _isSearching = false;
          });

          return rides;
        }
      }
    } catch (e) {
      print('Error searching rides: $e');
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }

    setState(() {
      _isSearching = false;
      _hasSearched = true;
    });
    return [];
  }

  Future<Map<String, dynamic>> _loadRides() async {
    final response = await _rideApi.getMyRides();
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Extract rides and summary from data.data
        final dataObject = data['data'] as Map<String, dynamic>?;
        final ridesList = dataObject?['rides'] as List<dynamic>? ?? [];
        final summary = dataObject?['summary'] as Map<String, dynamic>? ?? {};

        final rides = ridesList
            .whereType<Map<String, dynamic>>()
            .map((e) => Ride.fromJson(e))
            .toList();

        return {'rides': rides, 'summary': summary};
      }
    }
    throw Exception('Failed to load rides');
  }

  Map<String, List<Ride>> _groupRidesByStatus(List<Ride> rides) {
    final grouped = {
      'active': <Ride>[],
      'upcoming': <Ride>[],
      'ended': <Ride>[],
      'cancelled': <Ride>[],
    };

    for (final ride in rides) {
      if (ride.rideStatus == STATUS_STARTED) {
        grouped['active']!.add(ride);
      } else if (ride.rideStatus == STATUS_CREATED) {
        grouped['upcoming']!.add(ride);
      } else if (ride.rideStatus == STATUS_ENDED) {
        grouped['ended']!.add(ride);
      } else if (ride.rideStatus == STATUS_CANCELLED) {
        grouped['cancelled']!.add(ride);
      }
    }

    return grouped;
  }

  String _formatStartTime(DateTime startTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);

    final timeFormat = DateFormat('h:mm a');
    final time = timeFormat.format(startTime);

    if (startDate == today) {
      return 'Today at $time';
    } else if (startDate == tomorrow) {
      return 'Tomorrow at $time';
    } else {
      final dateFormat = DateFormat('MMM d');
      return '${dateFormat.format(startTime)} at $time';
    }
  }

  String _getTimeUntilStart(DateTime startTime) {
    final now = DateTime.now();
    final duration = startTime.difference(now);

    if (duration.isNegative) {
      return 'Ride has started';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return 'Wait ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Wait ${hours}h ${minutes}m';
    } else {
      return 'Wait ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _ridesFuture = _loadRides();
        });
        await _ridesFuture;
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: _ridesFuture,
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
                  const Text('Failed to load rides'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _ridesFuture = _loadRides();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final rides = (data['rides'] as List<Ride>?) ?? [];
          final summary = (data['summary'] as Map<String, dynamic>?) ?? {};

          // Convert distances from meters to kilometers
          final totalDistance =
              ((summary['totalRidedDistance'] as num?)?.toDouble() ?? 0) / 1000;
          final ridesCount =
              (summary['completedRidesCount'] as num?)?.toInt() ?? 0;
          final avgDistance =
              ((summary['averageDistance'] as num?)?.toDouble() ?? 0) / 1000;

          final groupedRides = _groupRidesByStatus(rides);
          final activeRides = groupedRides['active'] ?? [];
          final upcomingRides = groupedRides['upcoming'] ?? [];
          final endedRides = groupedRides['ended'] ?? [];
          final cancelledRides = groupedRides['cancelled'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rides',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your riding history',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                          if (!_isSearchExpanded) {
                            _searchController.clear();
                            _searchResults = [];
                            _hasSearched = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar (Conditional)
              if (_isSearchExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchRides(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search rides by title or description...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = false;
                            _searchController.clear();
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.surface
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              if (_isSearchExpanded) const SizedBox(height: 16),

              // Search Results or Regular Content
              if (_hasSearched)
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rides found',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Display search results
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = _searchResults[index];
                        return _buildSearchResultCard(ride);
                      },
                    ),
                  )
              else ...[
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.directions_bike,
                          value: '${totalDistance.toStringAsFixed(1)}',
                          label: 'Total km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today,
                          value: '$ridesCount',
                          label: 'Rides',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.trending_up,
                          value: '${avgDistance.toStringAsFixed(1)}',
                          label: 'Avg km',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Active Rides (STARTED)
                if (activeRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Active Rides',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeRides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = activeRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Upcoming Rides (CREATED)
                if (upcomingRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Upcoming Rides',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingRides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = upcomingRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Ended Rides
                // Ended Rides
                if (endedRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Ended Rides',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: endedRides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = endedRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Cancelled Rides
                if (cancelledRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Cancelled Rides',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cancelledRides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = cancelledRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (activeRides.isEmpty &&
                    upcomingRides.isEmpty &&
                    endedRides.isEmpty &&
                    cancelledRides.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No rides yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResultCard(Ride ride) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RideDetailScreen(rideId: ride.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ride.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[600]
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final distance = (ride.distanceMeters ?? 0) / 1000; // Convert to km
    final isStarted = ride.rideStatus == STATUS_STARTED;
    final isEnded = ride.rideStatus == STATUS_ENDED;
    final isCreated = ride.rideStatus == STATUS_CREATED;
    final isCancelled = ride.rideStatus == STATUS_CANCELLED;
    final isCreator = _currentUserId == ride.creatorId;

    // Choose icon based on ride status
    IconData getIconForStatus() {
      if (isStarted) return Icons.directions_run; // Active/ongoing
      if (isCreated) return Icons.schedule; // Upcoming
      if (isEnded) return Icons.check_circle; // Completed
      if (isCancelled) return Icons.cancel; // Cancelled
      return Icons.directions_bike; // Default
    }

    Color getIconBackgroundColor() {
      if (isStarted) return Colors.green.withOpacity(0.1);
      if (isCreated) return Colors.orange.withOpacity(0.1);
      if (isEnded) return Colors.blue.withOpacity(0.1);
      if (isCancelled) return Colors.red.withOpacity(0.1);
      return Colors.blue.withOpacity(0.1);
    }

    Color getIconColor() {
      if (isStarted) return Colors.green;
      if (isCreated) return Colors.orange;
      if (isEnded) return Colors.blue;
      if (isCancelled) return Colors.red;
      return Colors.blue;
    }

    // Format duration for ended rides
    String getFormattedDuration() {
      final durationMinutes = ride.endTime.difference(ride.startTime).inMinutes;
      if (durationMinutes < 1440) {
        // Less than 24 hours
        return '${durationMinutes}min';
      } else {
        final durationHours = (durationMinutes / 60).toStringAsFixed(1);
        return '${durationHours}hr';
      }
    }

    // Check if current time is between start and end time (ride should have started)
    bool _isRideShouldHaveStarted() {
      final now = DateTime.now();
      return now.isAfter(ride.startTime) && now.isBefore(ride.endTime);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RideDetailScreen(rideId: ride.id),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getIconBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(getIconForStatus(), color: getIconColor(), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCreated)
                    Text(
                      _formatStartTime(ride.startTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      '0 riders · ${distance.toStringAsFixed(1)} km distance',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isStarted)
              ride.rideMemberStatus == 'STARTED'
                  ? GestureDetector(
                      onTap: () {
                        // Navigate to home screen with the ride selected on map
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeScreen(selectedRideId: ride.id),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'View on Map',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
            else if (isCreated && isCreator)
              _isRideShouldHaveStarted()
                  ? GestureDetector(
                      onTap: () async {
                        try {
                          await _rideApi.startRide(ride.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ride started!')),
                          );
                          setState(() {
                            _ridesFuture = _loadRides();
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Start Ride',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        final timeWait = _getTimeUntilStart(ride.startTime);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(timeWait)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTimeUntilStart(ride.startTime),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
            else if (isEnded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getFormattedDuration(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
