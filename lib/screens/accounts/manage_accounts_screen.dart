// Trong file manage_accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự thay đổi của ô tìm kiếm để cập nhật trạng thái
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Accounts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF085DAA),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Sử dụng streamUsers với chuỗi tìm kiếm hiện tại
        stream: _adminService.streamUsers(searchQuery: _searchQuery),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final uid = docs[i].id;
              final name = d['fullName'] ?? 'User';
              final email = d['email'] ?? '';
              final role = d['role'] ?? 'user';
              final isActive = (d['isActive'] ?? true) as bool;

              return ListTile(
                leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
                title: Text(name),
                subtitle: Text('$email • vai trò: $role'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (v) => _adminService.setUserActive(uid, v),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => _adminService.setUserRole(uid, v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'user', child: Text('Đặt vai trò: user')),
                        PopupMenuItem(value: 'admin', child: Text('Đặt vai trò: admin')),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}