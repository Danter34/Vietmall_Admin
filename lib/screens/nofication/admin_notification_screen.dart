import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall_admin/services/admin_service.dart'; // Import AdminService

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({Key? key}) : super(key: key);

  @override
  _AdminNotificationScreenState createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final AdminService _adminService = AdminService();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Hàm để đánh dấu 1 thông báo là đã đọc
  Future<void> _markAsRead(DocumentReference docRef) {
    return docRef.update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Tự động đánh dấu tất cả thông báo là đã đọc khi thoát trang
        await _adminService.markAllAsRead();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Thông Báo',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF085DAA),
          actions: [
            TextButton(
              onPressed: () async {
                await _adminService.markAllAsRead();
              },
              child: const Text(
                'Đánh dấu tất cả đã đọc',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Bạn chưa có thông báo nào.'));
            }

            final notifications = snapshot.data!.docs;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final data = notification.data() as Map<String, dynamic>;
                final isRead = data['read'] ?? false;

                return Card(
                  color: isRead ? Colors.white : Colors.blue.withOpacity(0.1),
                  child: ListTile(
                    title: Text(
                      data['title'],
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(data['body']),
                    onTap: () {
                      _markAsRead(notification.reference);
                      // TODO: Điều hướng đến trang chi tiết nếu cần
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}