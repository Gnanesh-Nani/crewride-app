import 'package:flutter/material.dart';
import 'widgets/crew_bottom_nav.dart';
import 'screens/map_screen.dart';
import 'screens/rides_screen.dart';
import 'screens/crews_screen.dart';
import 'screens/profile_screen.dart';
import '../../settings/presentation/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLogout, this.onLoginSuccess});

  final VoidCallback? onLogout;
  final VoidCallback? onLoginSuccess;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _activeTab = HomeTab.map;

  // Cache screens to avoid rebuilding and reloading data
  final List<Widget> _screens = const [
    MapScreen(),
    RidesScreen(),
    CrewsScreen(),
    ProfileScreen(),
  ];

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
      // Use IndexedStack to keep all screens alive and avoid reloading
      body: IndexedStack(index: _activeTab.index, children: _screens),
      bottomNavigationBar: CrewBottomNav(
        activeTab: _activeTab,
        onTabSelected: (tab) => setState(() => _activeTab = tab),
      ),
    );
  }
}
