import 'package:flutter/material.dart';
import '../../../../domain/models/ride.dart';

/// Bottom ride info card showing ride summary with start button
class RideInfoCard extends StatefulWidget {
  final Ride ride;
  final int rideNumber;
  final int totalRides;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onStartRide;
  final VoidCallback onToggleCollapse;
  final bool hasPrevious;
  final bool hasNext;
  final bool isCollapsed;

  const RideInfoCard({
    super.key,
    required this.ride,
    required this.rideNumber,
    required this.totalRides,
    required this.onPrevious,
    required this.onNext,
    required this.onStartRide,
    required this.onToggleCollapse,
    this.hasPrevious = false,
    this.hasNext = false,
    this.isCollapsed = false,
  });

  @override
  State<RideInfoCard> createState() => _RideInfoCardState();
}

class _RideInfoCardState extends State<RideInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (!widget.isCollapsed) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(RideInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(DateTime startTime, DateTime endTime) {
    final difference = endTime.difference(startTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '$hours h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final durationText = _formatDuration(
      widget.ride.startTime,
      widget.ride.endTime,
    );
    final distance =
        (widget.ride.distanceMeters ?? 0) / 1609.34; // Convert to miles

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapse/Expand handle with chevron icon
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Center(
              child: RotationTransition(
                turns: Tween<double>(
                  begin: 0,
                  end: 0.5,
                ).animate(_animationController),
                child: Icon(
                  Icons.expand_more,
                  size: 28,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          // Animated content
          SizeTransition(
            sizeFactor: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Ride title and details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ride.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                durationText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${distance.toStringAsFixed(1)} mi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.ride.rideMembers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _buildRiderAvatars(widget.ride.rideMembers),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Riders count
                if (widget.ride.rideMembers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${widget.ride.rideMembers.length} RIDERS JOINED',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                // Schedule navigation
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: widget.hasPrevious
                            ? widget.onPrevious
                            : null,
                        splashRadius: 20,
                      ),
                      Text(
                        'RIDE ${widget.rideNumber} OF ${widget.totalRides}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: widget.hasNext ? widget.onNext : null,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Start ride button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onStartRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text(
                      'START RIDE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderAvatars(List<dynamic> rideMembers) {
    final displayCount = rideMembers.length > 3 ? 3 : rideMembers.length;
    final remaining = rideMembers.length > 3 ? rideMembers.length - 3 : 0;

    return Stack(
      children: [
        ...List.generate(displayCount, (index) {
          final offset = index * 24.0;
          final member = rideMembers[index];
          final avatarUrl = member['avatarurl'] ?? member['avatar_url'];

          return Positioned(
            left: offset,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: Colors.grey[300],
                child: avatarUrl == null
                    ? Text(
                        (member['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          );
        }),
        if (remaining > 0)
          Positioned(
            left: displayCount * 24.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[400],
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
