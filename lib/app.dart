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

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1C64F2),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        secondary: Color(0xFF6B7280),
      ),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1C64F2),
        onPrimary: Colors.white,
        surface: Color(0xFF0F172A),
        onSurface: Colors.white,
        secondary: Color(0xFF94A3B8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C64F2),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200.withOpacity(0.4)),
          ),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crew Ride',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.mode,
      home: _isLoggedIn
          ? HomeScreen(onLogout: _handleLoggedOut)
          : LoginPage(onLoginSuccess: _handleLoggedIn),
      routes: {
        '/createRide': (context) => CreateRideScreen(),
        '/waypointSelection': (context) => WaypointSelectionScreen(),
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
