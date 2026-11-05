import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'settings_backup_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(
        onNavigateToInventory: () => setState(() => _currentIndex = 2),
        onNavigateToInvoices: () => setState(() => _currentIndex = 1),
      ),
      const InvoicesScreen(),
      const InventoryScreen(),
      SettingsBackupScreen(
        onThemeToggle: widget.onThemeToggle,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          indicatorColor: isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.layoutDashboard, size: 20),
              selectedIcon: Icon(LucideIcons.layoutDashboard, size: 21, color: AppColors.primary),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.fileText, size: 20),
              selectedIcon: Icon(LucideIcons.fileText, size: 21, color: AppColors.primary),
              label: 'فاکتورها',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.package, size: 20),
              selectedIcon: Icon(LucideIcons.package, size: 21, color: AppColors.primary),
              label: 'انبار کالا',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.settings, size: 20),
              selectedIcon: Icon(LucideIcons.settings, size: 21, color: AppColors.primary),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}
