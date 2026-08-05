import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'accounts_screen.dart';
import 'transfer_screen.dart';
import 'cards_screen.dart';
import 'analytics_screen.dart';
import 'bills_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AccountsScreen(),
    const TransferScreen(),
    const CardsScreen(),
    const _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!AppState.instance.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More Options')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.insights, color: Color(0xFFD32F2F)),
            title: const Text('Analytics & Budget'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFFD32F2F)),
            title: const Text('Pay Bills'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillsScreen(
                  currentBalance:
                      AppState.instance.currentUser?.totalBalance ?? 0,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFFD32F2F)),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFFD32F2F)),
            title: const Text('My Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFFD32F2F)),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () async {
              AppState.instance.logout();
              await DataService.clearSession();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
