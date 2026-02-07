import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/ride_api.dart';
import '../../domain/models/ride.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';

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

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'started':
        return Colors.green;
      case 'created':
        return Colors.orange;
      case 'ended':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          final isCreator = _currentUserId == ride.creatorId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with Title and Status
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.title,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      ride.rideStatus,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatStatus(ride.rideStatus),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(ride.rideStatus),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Creator',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ride.description.isNotEmpty)
                        Text(
                          ride.description,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Route Information
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: '${distance.toStringAsFixed(2)} km',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.schedule,
                        label: 'Duration',
                        value: _formatDuration(ride.startTime, ride.endTime),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Time Information
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeRow(
                        icon: Icons.play_circle,
                        label: 'Start Time',
                        time: ride.startTime,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeRow(
                        icon: Icons.stop_circle,
                        label: 'End Time',
                        time: ride.endTime,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeRow(
                        icon: Icons.calendar_today,
                        label: 'Created At',
                        time: ride.createdAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Additional Details
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(label: 'Ride ID', value: ride.id),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        label: 'Visibility',
                        value:
                            ride.visibility[0].toUpperCase() +
                            ride.visibility.substring(1),
                      ),
                      if (ride.crewId != null)
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              label: 'Crew ID',
                              value: ride.crewId!,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                if (!isCreator)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _rideApi.acceptRideInvitation(widget.rideId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Joined the ride!')),
                          );
                          setState(() {
                            _rideFuture = _loadRideDetails();
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Join Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required DateTime time,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(time),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
