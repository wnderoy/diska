import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../screens/map_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/add_show_screen.dart';
import '../screens/saved_shows_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/auth_guard.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 1;
  int _mapRefreshCounter = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    AuthService.authState.addListener(_onAuthChange);
    _screens = [
      AuthGuard(builder: (_) => MessagesScreen()),
      const MapScreen(),
      AuthGuard(builder: (_) => AddShowScreen(onShowCreated: _onShowCreated)),
      const SavedShowsScreen(),
      AuthGuard(builder: (_) => const ProfileScreen()),
    ];
  }

  @override
  void dispose() {
    AuthService.authState.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() => setState(() {});

  void _onShowCreated() {
    setState(() {
      _currentIndex = 1;
      _mapRefreshCounter++;
    });
    _screens[1] = MapScreen(refreshCounter: _mapRefreshCounter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          color: AppColors.background,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = _currentIndex == 2;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary : AppColors.purple,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.message_outlined, 'Messages'),
              _navItem(1, Icons.map_outlined, 'Map'),
              _navItem(2, Icons.add_circle_outline, 'Add Show'),
              _navItem(3, Icons.star_border, 'Saved'),
              _navItem(4, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = _currentIndex == 2;
    final activeColor = isDark ? AppColors.lime : AppColors.lime;
    final inactiveColor = isDark
        ? AppColors.textOnPrimary.withValues(alpha: 0.5)
        : AppColors.textOnPrimary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colorful indicator on selected tab
            if (isSelected)
              Container(
                width: 24,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
            else
              const SizedBox(height: 6.5),
            Icon(icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
