import 'package:crewride_app/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'widgets/crew_bottom_nav.dart';

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key, this.onLogout, this.onLoginSuccess});

  final VoidCallback? onLogout;
  final VoidCallback? onLoginSuccess;

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  HomeTab _activeTab = HomeTab.map;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrewRide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onLogout: widget.onLogout,
                    onLoginSuccess: widget.onLoginSuccess,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CrewBottomNav(
        activeTab: _activeTab,
        onTabSelected: (tab) => setState(() => _activeTab = tab),
      ),
    );
  }

  Widget _buildBody() {
    switch (_activeTab) {
      case HomeTab.map:
        return Stack(
          children: [
            Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Map View',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add google_maps_flutter dependency',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'myLocation',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      // TODO: Center map on user's location
                    },
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'startRide',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      _showStartRideDialog();
                    },
                    child: const Icon(Icons.directions_bike),
                  ),
                ],
              ),
            ),
          ],
        );
      case HomeTab.rides:
        return _buildPlaceholder(
          title: 'Rides',
          subtitle: 'Track and join rides from here soon.',
          icon: Icons.route_outlined,
        );
      case HomeTab.communities:
        return _buildPlaceholder(
          title: 'Crews',
          subtitle: 'Community features are on the way.',
          icon: Icons.groups_outlined,
        );
      case HomeTab.profile:
        return _buildPlaceholder(
          title: 'Profile',
          subtitle: 'Manage your rider profile here.',
          icon: Icons.person_outline,
        );
    }
  }

  Widget _buildPlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showStartRideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Group Ride'),
        content: const Text('Would you like to start a new group ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to start ride screen
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
