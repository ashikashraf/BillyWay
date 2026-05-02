import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'side_nav.dart';
import '../../../core/theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/sales');
        break;
      case 2:
        context.go('/purchase');
        break;
      case 3:
        context.go('/stock');
        break;
      case 4:
        context.go('/transfers');
        break;
      case 5:
        context.go('/reports');
        break;
      case 6:
        context.go('/parties');
        break;
      case 7:
        context.go('/items');
        break;
      case 8:
        context.go('/masters');
        break;
      case 9:
        context.go('/users');
        break;
      case 10:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      bottomNavigationBar: isSmallScreen
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Sales'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
                NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
              ],
            )
          : null,
      body: Row(
        children: [
          SideNav(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
