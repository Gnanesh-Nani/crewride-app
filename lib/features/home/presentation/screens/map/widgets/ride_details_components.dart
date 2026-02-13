import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/ride.dart';

/// Displays ride title, status badge, and visibility indicator
class RideDetailsHeader extends StatelessWidget {
  final Ride ride;
  final ThemeData theme;

  const RideDetailsHeader({super.key, required this.ride, required this.theme});

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
    return Row(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}

/// Displays ride description in a styled container
class RideDescription extends StatelessWidget {
  final String description;
  final ThemeData theme;

  const RideDescription({
    super.key,
    required this.description,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: Text(description, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// Displays start and end times in a timeline format
class RideScheduleSection extends StatelessWidget {
  final Ride ride;
  final DateFormat formatter;
  final ThemeData theme;

  const RideScheduleSection({
    super.key,
    required this.ride,
    required this.formatter,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

/// Displays list of waypoints with type-based styling
class RideWaypointsSection extends StatelessWidget {
  final List<dynamic> waypoints;
  final ThemeData theme;

  const RideWaypointsSection({
    super.key,
    required this.waypoints,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waypoints (${waypoints.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: waypoints.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final wp = waypoints[index];
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
      ],
    );
  }
}

/// Displays ride metadata (creation date)
class RideMetaInfo extends StatelessWidget {
  final Ride ride;
  final DateFormat formatter;

  const RideMetaInfo({super.key, required this.ride, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Created',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            formatter.format(ride.createdAt),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Action buttons for ride operations (Start, Cancel, End)
class RideActionButtons extends StatelessWidget {
  final Ride ride;
  final String? currentUserId;
  final VoidCallback onStartRide;
  final VoidCallback onCancelRide;
  final VoidCallback onEndRide;

  const RideActionButtons({
    super.key,
    required this.ride,
    this.currentUserId,
    required this.onStartRide,
    required this.onCancelRide,
    required this.onEndRide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Start Ride button (only if creator and ride is created)
        if (currentUserId == ride.creatorId && ride.rideStatus == 'created')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartRide,
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
        if (currentUserId == ride.creatorId &&
            ride.rideStatus == 'created') ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancelRide,
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
        if (currentUserId == ride.creatorId && ride.rideStatus == 'started')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEndRide,
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
    );
  }
}
