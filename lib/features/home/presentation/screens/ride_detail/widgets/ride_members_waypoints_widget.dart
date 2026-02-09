import 'package:crewride_app/features/home/domain/models/ride.dart';
import 'package:flutter/material.dart';

class RideMembersWaypointsWidget extends StatelessWidget {
  final Ride ride;

  const RideMembersWaypointsWidget({super.key, required this.ride});

  List<Widget> _buildWaypointsList(List<Waypoint> waypoints) {
    final sortedWaypoints = List<Waypoint>.from(waypoints);
    sortedWaypoints.sort(
      (a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0),
    );

    return List.generate(sortedWaypoints.length, (index) {
      final waypoint = sortedWaypoints[index];
      final isStart = waypoint.type == 'start';
      final isDestination = waypoint.type == 'destination';
      final isLast = index == sortedWaypoints.length - 1;

      String getWaypointLabel() {
        if (isStart) return 'Start Point';
        if (isDestination) return 'Final Destination';
        return 'Stop';
      }

      Color dotColor() {
        if (isStart) return Colors.black;
        if (isDestination) return Colors.grey[300]!;
        return Colors.grey[300]!;
      }

      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor(),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 56,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getWaypointLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isStart
                            ? Colors.black
                            : isDestination
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${waypoint.latitude.toStringAsFixed(4)}° N, ${waypoint.longitude.toStringAsFixed(4)}° E',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontFamily: 'monospace',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Who's Riding Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups, size: 20, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        "RideMembers",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${ride.rideMembers.length} Members',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...ride.rideMembers.map((member) {
                      final isFirstMember = member == ride.rideMembers.first;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isFirstMember
                                          ? Colors.black
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child:
                                        member.avatarurl != null &&
                                            member.avatarurl!.isNotEmpty
                                        ? Image.network(
                                            member.avatarurl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                  ),
                                ),
                                if (isFirstMember)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 60,
                              child: Text(
                                member.fullname,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              color: Colors.grey[100],
                            ),
                            child: Icon(Icons.add, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Invite',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Route Waypoints Section
        if (ride.waypoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Route Waypoints',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.expand_more, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: _buildWaypointsList(ride.waypoints),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
