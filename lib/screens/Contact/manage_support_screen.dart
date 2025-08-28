// lib/screens/admin/manage_support_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall_admin/common/app_colors.dart';
import 'package:vietmall_admin/common/constants.dart';
import 'package:vietmall_admin/screens/chat/chat_room_screen.dart';
import 'package:vietmall_admin/services/auth_service.dart';
import 'package:vietmall_admin/services/chat_service.dart';
import 'package:vietmall_admin/services/database_service.dart';

class ManageSupportScreen extends StatefulWidget {
  const ManageSupportScreen({super.key});

  @override
  State<ManageSupportScreen> createState() => _ManageSupportScreenState();
}

class _ManageSupportScreenState extends State<ManageSupportScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // The function to show the delete confirmation dialog is now here, in the State class.
  Future<void> _showDeleteConfirmation(BuildContext context, String chatRoomId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Call the delete function from the ChatService instance
                await _chatService.deleteChatRoom(chatRoomId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa cuộc trò chuyện')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
        'Manage Contact',
        style: TextStyle(color: Colors.white),
      ),
        backgroundColor: const Color(0xFF085DAA),),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRoomsByAdmin(adminSupportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Đã có lỗi xảy ra."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có yêu cầu hỗ trợ nào."));
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) =>
                _buildSupportListItem(snapshot.data!.docs[index]),
            separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
      ),
    );
  }

  Widget _buildSupportListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final currentUserId = _authService.currentUser!.uid;

    List<String> userIds = List<String>.from(data['users']);
    String otherUserId = userIds.firstWhere((id) => id != adminSupportId);
    String otherUserName = data['userNames'][otherUserId] ?? 'Người dùng';

    Timestamp timestamp = data['lastMessageTimestamp'];
    String formattedTime = DateFormat('HH:mm').format(timestamp.toDate());

    int unreadCount = 0;
    if (data['unread'] != null) {
      unreadCount = (data['unread'][currentUserId] ?? 0) as int;
    }

    return ListTile(
      tileColor: unreadCount > 0 ? Colors.blue.withOpacity(0.1) : null,
      leading: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getUserProfile(otherUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircleAvatar(radius: 28, backgroundColor: AppColors.greyLight);
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final avatarUrl = userData?['avatarUrl'] as String?;
          return CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.greyLight,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(
                Icons.person, color: Colors.white) : null,
          );
        },
      ),
      title: Row(
        children: [
          Text(otherUserName, style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight
                  .normal)),
          const SizedBox(width: 8),
          Text(formattedTime,
              style: const TextStyle(color: AppColors.greyDark, fontSize: 12)),
        ],
      ),
      subtitle: Text(
          data['lastMessage'], maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight
                  .normal)),
      onTap: () async {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(doc.id)
            .set({'unread': {currentUserId: 0}}, SetOptions(merge: true));
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
            ChatRoomScreen(
              receiverId: otherUserId,
              receiverName: otherUserName,
            ),
        ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteConfirmation(context, doc.id),
      ),
    );
  }
}