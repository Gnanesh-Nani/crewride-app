import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/ride.dart';
import 'ride_details_components.dart';

/// Bottom sheet widget for displaying comprehensive ride details
class RideDetailsSheet extends StatelessWidget {
  final Ride ride;
  final String? currentUserId;
  final VoidCallback onStartRide;
  final VoidCallback onCancelRide;
  final VoidCallback onEndRide;

  const RideDetailsSheet({
    super.key,
    required this.ride,
    this.currentUserId,
    required this.onStartRide,
    required this.onCancelRide,
    required this.onEndRide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('MMM dd, yyyy - HH:mm');

    return SingleChildScrollView(
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
          RideDetailsHeader(ride: ride, theme: theme),
          const SizedBox(height: 16),

          // Description
          if (ride.description.isNotEmpty) ...{
            RideDescription(description: ride.description, theme: theme),
            const SizedBox(height: 16),
          },

          // Schedule section
          RideScheduleSection(ride: ride, formatter: formatter, theme: theme),
          const SizedBox(height: 16),

          // Waypoints section
          if (ride.waypoints.isNotEmpty) ...{
            RideWaypointsSection(waypoints: ride.waypoints, theme: theme),
            const SizedBox(height: 16),
          },

          // Meta info
          RideMetaInfo(ride: ride, formatter: formatter),
          const SizedBox(height: 20),

          // Action buttons
          RideActionButtons(
            ride: ride,
            currentUserId: currentUserId,
            onStartRide: onStartRide,
            onCancelRide: onCancelRide,
            onEndRide: onEndRide,
          ),
        ],
      ),
    );
  }
}
