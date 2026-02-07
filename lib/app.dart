import 'package:flutter/material.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_screen.dart';
import 'core/storage/auth_storage.dart';
import 'core/theme/theme_controller.dart';
import 'features/ride/presentation/screens/create_ride_screen.dart';
import 'features/ride/presentation/screens/waypoint_selection_screen.dart';

class CrewRideApp extends StatefulWidget {
  const CrewRideApp({super.key});

  @override
  State<CrewRideApp> createState() => _CrewRideAppState();
}

class _CrewRideAppState extends State<CrewRideApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthStorage.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Crew Ride',
          theme: themeController.themeData,
          themeMode: themeController.mode,
          home: _isLoggedIn
              ? HomeScreen(onLogout: _handleLoggedOut)
              : LoginPage(onLoginSuccess: _handleLoggedIn),
          routes: {
            '/createRide': (context) => CreateRideScreen(),
            '/waypointSelection': (context) => WaypointSelectionScreen(),
          },
        );
      },
    );
  }

  void _handleLoggedIn() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLoggedOut() {
    setState(() {
      _isLoggedIn = false;
    });
  }
}
