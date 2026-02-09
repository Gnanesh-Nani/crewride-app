import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crewride_app/features/home/domain/models/ride.dart';
import '../../ride_detail/ride_detail_screen.dart';

class UpcomingRidesSectionWidget extends StatelessWidget {
  final List<Ride> upcomingRides;
  final String? currentUserId;

  const UpcomingRidesSectionWidget({
    required this.upcomingRides,
    required this.currentUserId,
    super.key,
  });

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

  bool _isRideTime(Ride ride) {
    final now = DateTime.now();
    return now.isAfter(ride.startTime) && now.isBefore(ride.endTime);
  }

  bool _isAdminForgot(Ride ride) {
    final now = DateTime.now();
    return now.isAfter(ride.endTime);
  }

  Widget _buildStatusWidget(Ride ride, BuildContext context) {
    final isCreator = currentUserId == ride.creatorId;
    final isRideTime = _isRideTime(ride);
    final isAdminForgot = _isAdminForgot(ride);

    // Admin forgot to start the ride
    if (isAdminForgot) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Schedule Missed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Creator at ride time - show START RIDE button
    if (isCreator && isRideTime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'START RIDE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Show countdown timer
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getTimeUntilStart(ride.startTime),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Upcoming Rides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingRides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = upcomingRides[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RideDetailScreen(rideId: ride.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.surface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatStartTime(ride.startTime).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusWidget(ride, context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
