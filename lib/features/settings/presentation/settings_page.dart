import 'package:flutter/material.dart';
import 'package:crewride_app/core/network/dio_client.dart';
import 'package:crewride_app/features/auth/presentation/login_page.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import 'package:crewride_app/core/theme/theme_controller.dart';
import 'package:crewride_app/core/theme/app_themes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onLogout, this.onLoginSuccess});

  final VoidCallback? onLogout;
  final VoidCallback? onLoginSuccess;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = themeController.currentTheme;
    themeController.addListener(_syncTheme);
  }

  @override
  void dispose() {
    themeController.removeListener(_syncTheme);
    super.dispose();
  }

  void _syncTheme() {
    setState(() {
      _selectedTheme = themeController.currentTheme;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    await DioClient.clearCookies();
    await AuthStorage.clearUserData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logged out'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.grey.shade900,
      ),
    );

    widget.onLogout?.call();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLoginSuccess: widget.onLoginSuccess,
          onLogout: widget.onLogout,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Theme Selection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey,
                  ),
                ),
                DropdownButton<AppTheme>(
                  value: _selectedTheme,
                  items: AppTheme.values.map((theme) {
                    return DropdownMenuItem<AppTheme>(
                      value: theme,
                      child: Text(theme.label),
                    );
                  }).toList(),
                  onChanged: (theme) async {
                    if (theme != null) {
                      await themeController.setTheme(theme);
                    }
                  },
                  underline: Container(),
                  isDense: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
