import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primarySurface,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.layoutDashboard, size: 20),
              selectedIcon: Icon(LucideIcons.layoutDashboard, size: 20, color: AppColors.primary),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.fileText, size: 20),
              selectedIcon: Icon(LucideIcons.fileText, size: 20, color: AppColors.primary),
              label: 'فاکتورها',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.package, size: 20),
              selectedIcon: Icon(LucideIcons.package, size: 20, color: AppColors.primary),
              label: 'انبار کالا',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.settings, size: 20),
              selectedIcon: Icon(LucideIcons.settings, size: 20, color: AppColors.primary),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}
