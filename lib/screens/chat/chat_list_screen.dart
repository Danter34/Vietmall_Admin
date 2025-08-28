import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall_admin/common/app_colors.dart';
import 'package:vietmall_admin/screens/chat/chat_room_screen.dart';
import 'package:vietmall_admin/services/auth_service.dart';
import 'package:vietmall_admin/services/chat_service.dart';
import 'package:vietmall_admin/services/database_service.dart';
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin nhắn"),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Đã có lỗi xảy ra."));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Bạn chưa có cuộc trò chuyện nào."));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) =>
                      _buildChatListItem(snapshot.data!.docs[index]),
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildChatListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final currentUserId = _authService.currentUser!.uid;

    List<String> userIds = List<String>.from(data['users']);
    String otherUserId = userIds.firstWhere((id) => id != currentUserId);
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
            return const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.greyLight,
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final avatarUrl = userData?['avatarUrl'] as String?;

          return CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.greyLight,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          );
        },
      ),
      title: Row(
        children: [
          Text(
            otherUserName,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formattedTime,
            style: const TextStyle(color: AppColors.greyDark, fontSize: 12),
          ),
        ],
      ),
      subtitle: Text(
        data['lastMessage'],
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () async {
        // khi mở phòng → reset unread
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(doc.id)
            .set({
          'unread': {currentUserId: 0}
        }, SetOptions(merge: true));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatRoomScreen(
                  receiverId: otherUserId,
                  receiverName: otherUserName,
                ),
          ),
        );
      },
    );
  }
}