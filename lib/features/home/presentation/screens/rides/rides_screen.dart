import 'package:flutter/material.dart';
import 'package:crewride_app/features/home/data/ride_api.dart';
import 'package:crewride_app/features/home/domain/models/ride.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import '../ride_detail/ride_detail_screen.dart';
import 'widgets/rides_header_widget.dart';
import 'widgets/rides_stats_card_widget.dart';
import 'widgets/active_rides_section_widget.dart';
import 'widgets/upcoming_rides_section_widget.dart';
import 'widgets/ended_rides_section_widget.dart';
import 'widgets/cancelled_rides_section_widget.dart';

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
          final ridesList = data['data'] as List<dynamic>? ?? [];

          final rides = ridesList.whereType<Map<String, dynamic>>().map((e) {
            final now = DateTime.now();
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
              RidesHeaderWidget(
                onSearchTap: () {
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
              const SizedBox(height: 16),

              // Search Bar
              if (_isSearchExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search rides...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _hasSearched = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _searchRides(value);
                    },
                  ),
                ),
              if (_isSearchExpanded) const SizedBox(height: 16),

              // Search Results or Regular Content
              if (_hasSearched)
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text('No rides found'),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _searchResults
                          .map(
                            (ride) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RideDetailScreen(rideId: ride.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context).colorScheme.surface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade700
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ride.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ride.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
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
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
              else ...[
                // Gradient Stats Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RidesStatsCardWidget(
                    totalDistance: totalDistance,
                    ridesCount: ridesCount,
                    avgDistance: avgDistance,
                  ),
                ),
                const SizedBox(height: 28),

                // Active Rides
                if (activeRides.isNotEmpty) ...[
                  ActiveRidesSectionWidget(
                    activeRides: activeRides,
                    currentUserId: _currentUserId,
                  ),
                  const SizedBox(height: 28),
                ],

                // Upcoming Rides
                if (upcomingRides.isNotEmpty) ...[
                  UpcomingRidesSectionWidget(
                    upcomingRides: upcomingRides,
                    currentUserId: _currentUserId,
                  ),
                  const SizedBox(height: 28),
                ],

                // Ended Rides
                if (endedRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EndedRidesSectionWidget(endedRides: endedRides),
                  ),
                  const SizedBox(height: 28),
                ],

                // Cancelled Rides
                if (cancelledRides.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CancelledRidesSectionWidget(
                      cancelledRides: cancelledRides,
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
                        'No rides yet. Start exploring!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
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
}
