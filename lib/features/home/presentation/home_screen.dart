import 'package:crewride_app/features/home/presentation/screens/rides/rides_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crewride_app/core/theme/theme_controller.dart';
import 'widgets/crew_bottom_nav.dart';
import 'screens/map_screen.dart';
import 'screens/crews_screen.dart';
import 'screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onLogout,
    this.onLoginSuccess,
    this.selectedRideId,
  });

  final VoidCallback? onLogout;
  final VoidCallback? onLoginSuccess;
  final String? selectedRideId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _activeTab = HomeTab.map;

  // Cache screens to avoid rebuilding and reloading data
  late final List<Widget> _screens = [
    MapScreen(selectedRideId: widget.selectedRideId),
    const RidesScreen(),
    const CrewsScreen(),
    ProfileScreen(
      onLogout: widget.onLogout,
      onLoginSuccess: widget.onLoginSuccess,
    ),
  ];

  @override
  void initState() {
    super.initState();
    themeController.addListener(_updateStatusBarStyle);
    // If a ride was selected, switch to map tab
    if (widget.selectedRideId != null) {
      _activeTab = HomeTab.map;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarStyle();
  }

  @override
  void dispose() {
    themeController.removeListener(_updateStatusBarStyle);
    super.dispose();
  }

  void _updateStatusBarStyle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update status bar style on every build to reflect theme changes
    _updateStatusBarStyle();
    return Scaffold(
      // Use SafeArea to prevent content from overlapping status bar
      body: SafeArea(
        child: IndexedStack(index: _activeTab.index, children: _screens),
      ),
      bottomNavigationBar: CrewBottomNav(
        activeTab: _activeTab,
        onTabSelected: (tab) => setState(() => _activeTab = tab),
      ),
    );
  }
}
