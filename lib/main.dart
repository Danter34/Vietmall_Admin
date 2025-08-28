import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/posts/manage_posts_screen.dart';
import 'screens/banners/manage_banners_screen.dart';
import 'screens/orders/manage_orders_screen.dart';
import 'screens/accounts/manage_accounts_screen.dart';
import 'screens/Contact/manage_support_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VietMallAdminApp());
}

class VietMallAdminApp extends StatelessWidget {
  const VietMallAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIETMALL Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const LoginScreen(),
      routes: {
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        '/manage-posts': (_) => const ManagePostsScreen(),
        '/manage-orders': (_) => const ManageOrdersScreen(), // Thêm định tuyến cho ManageOrdersScreen
        '/manage-accounts': (_) => const ManageAccountsScreen(), // Thêm định tuyến cho ManageAccountsScreen
        '/manage-banners': (_) => const ManageBannersScreen(),
        '/manage-support': (context) => const ManageSupportScreen()
      },
    );
  }
}
