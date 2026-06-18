import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/add_show_screen.dart';
import '../screens/saved_shows_screen.dart';
import '../screens/profile_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 1; // Default to Map View

  /// Increment to signal the map to reload shows.
  int _mapRefreshCounter = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MessagesScreen(),
      MapScreen(refreshCounter: _mapRefreshCounter),
      AddShowScreen(onShowCreated: _onShowCreated),
      const SavedShowsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onShowCreated() {
    // Switch to map tab and trigger refresh
    setState(() {
      _currentIndex = 1;
      _mapRefreshCounter++;
    });
    // Rebuild the screens list with the new counter
    _screens[1] = MapScreen(refreshCounter: _mapRefreshCounter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.black, width: 0),
            ),
          ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black, width: 1.5),
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
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
