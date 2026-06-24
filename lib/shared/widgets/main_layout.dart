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
        context.go('/quotations');
        break;
      case 3:
        context.go('/purchase');
        break;
      case 4:
        context.go('/stock');
        break;
      case 5:
        context.go('/transfers');
        break;
      case 6:
        context.go('/reports');
        break;
      case 7:
        context.go('/parties');
        break;
      case 8:
        context.go('/items');
        break;
      case 9:
        context.go('/masters');
        break;
      case 10:
        context.go('/users');
        break;
      case 11:
        context.go('/settings');
        break;
      case 12:
        context.go('/estimates');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isSmallScreen) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 1,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          title: Text(
            'BillyWay ERP',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        drawer: Drawer(
          child: SideNav(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              _onItemTapped(index);
              Navigator.pop(context); // Close drawer after selection
            },
          ),
        ),
        body: Container(
          color: theme.scaffoldBackgroundColor,
          child: widget.child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          SideNav(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
          ),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
