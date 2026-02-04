import 'package:flutter/material.dart';
import 'package:crewride_app/core/network/dio_client.dart';
import 'package:crewride_app/features/auth/presentation/login_page.dart';
import 'package:crewride_app/core/storage/auth_storage.dart';
import 'package:crewride_app/core/theme/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onLogout, this.onLoginSuccess});

  final VoidCallback? onLogout;
  final VoidCallback? onLoginSuccess;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = themeController.mode == ThemeMode.dark;
    themeController.addListener(_syncTheme);
  }

  @override
  void dispose() {
    themeController.removeListener(_syncTheme);
    super.dispose();
  }

  void _syncTheme() {
    setState(() {
      _isDark = themeController.mode == ThemeMode.dark;
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
          SwitchListTile.adaptive(
            value: _isDark,
            onChanged: (val) {
              setState(() => _isDark = val);
              themeController.setMode(val ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Switch between light and dark themes'),
          ),
          const Divider(height: 1),
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
