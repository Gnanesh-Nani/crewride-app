import 'package:flutter/material.dart';
import '../../../../domain/models/ride.dart';

/// Main widget for all map controls (FABs and ride selector)
class MapControls extends StatelessWidget {
  final List<Ride> rides;
  final int selectedRideIndex;
  final VoidCallback onLocationPressed;
  final VoidCallback onCreateRidePressed;
  final Function(int) onRideChanged;

  const MapControls({
    super.key,
    required this.rides,
    required this.selectedRideIndex,
    required this.onLocationPressed,
    required this.onCreateRidePressed,
    required this.onRideChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Ride selector chip (when rides exist)
          if (rides.isNotEmpty) ...{
            RideSelectorChip(
              rides: rides,
              selectedIndex: selectedRideIndex,
              onRideChanged: onRideChanged,
            ),
            const SizedBox(height: 16),
          },
          // Control buttons row
          _buildControlButtons(context),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // My Location button
        FloatingActionButton(
          heroTag: 'location',
          onPressed: onLocationPressed,
          tooltip: 'My Location',
          mini: true,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(width: 12),
        // Start Ride button (placeholder)
        FloatingActionButton(
          heroTag: 'start_ride_action',
          onPressed: () {
            if (rides.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create a ride first to start one'),
                ),
              );
              return;
            }
          },
          tooltip: 'Start Ride',
          child: const Icon(Icons.play_arrow),
        ),
        const SizedBox(width: 12),
        // Create Ride button (primary)
        FloatingActionButton(
          heroTag: 'create_ride',
          onPressed: onCreateRidePressed,
          tooltip: 'Create Ride',
          child: const Stack(
            alignment: Alignment.center,
            children: [Icon(Icons.directions_bike, size: 28)],
          ),
        ),
      ],
    );
  }
}

/// Chip widget for selecting between multiple rides
class RideSelectorChip extends StatelessWidget {
  final List<Ride> rides;
  final int selectedIndex;
  final Function(int) onRideChanged;

  const RideSelectorChip({
    super.key,
    required this.rides,
    required this.selectedIndex,
    required this.onRideChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
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
            onPressed: selectedIndex > 0
                ? () => onRideChanged(selectedIndex - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                rides[selectedIndex].title,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            onPressed: selectedIndex < rides.length - 1
                ? () => onRideChanged(selectedIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
