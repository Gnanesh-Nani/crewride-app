import 'package:flutter/material.dart';

enum HomeTab { map, rides, communities, profile }

class CrewBottomNav extends StatelessWidget {
  const CrewBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color surfaceColor = theme.colorScheme.surface;
    final Color borderColor = theme.dividerColor;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color inactiveColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;

    final tabs = <({HomeTab id, IconData icon, String label})>[
      (id: HomeTab.map, icon: Icons.map_outlined, label: 'Map'),
      (id: HomeTab.rides, icon: Icons.route_outlined, label: 'Rides'),
      (id: HomeTab.communities, icon: Icons.groups_outlined, label: 'Crews'),
      (id: HomeTab.profile, icon: Icons.person_outline, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor.withOpacity(0.95),
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs
              .map(
                (tab) => _NavButton(
                  icon: tab.icon,
                  label: tab.label,
                  isActive: activeTab == tab.id,
                  accent: accent,
                  inactive: inactiveColor,
                  onTap: () => onTabSelected(tab.id),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accent,
    required this.inactive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color accent;
  final Color inactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isActive ? accent : inactive,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? accent : inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
