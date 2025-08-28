import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import 'package:badges/badges.dart' as badges; // 1. Import the badges library
import 'package:vietmall_admin/screens/nofication/admin_notification_screen.dart'; // 2. Import the admin notification screen
import 'package:vietmall_admin/services/admin_service.dart'; // 3. Import your AdminService

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminService _adminService = AdminService(); // 4. Create an instance of AdminService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF085DAA),
        elevation: 2,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // 5. Use a StreamBuilder to show the badge
          StreamBuilder<int>(
            stream: _adminService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return badges.Badge(
                showBadge: unreadCount > 0,
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                badgeContent: const SizedBox.shrink(), // A simple red dot
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () {
                    // 6. Navigate to the AdminNotificationScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(),
      body: GridView.extent(
        maxCrossAxisExtent: 280,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: const [
          _DashCard(
              icon: Icons.fact_check,
              title: 'Manage Posts',
              route: '/manage-posts'),
          _DashCard(
              icon: Icons.inventory_2,
              title: 'Manage Orders',
              route: '/manage-orders'),
          _DashCard(
              icon: Icons.people_alt,
              title: 'Manage Accounts',
              route: '/manage-accounts'),
          _DashCard(
              icon: Icons.image,
              title: 'Manage Banners',
              route: '/manage-banners'),
          _DashCard(
              icon: Icons.support_agent_outlined,
              title: 'Manage Contact',
              route: '/manage-support'),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  const _DashCard(
      {required this.icon, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.blue[800]),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              )
            ],
          ),
        ),
      ),
    );
  }
}