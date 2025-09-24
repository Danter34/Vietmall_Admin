import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vietmall_admin/common/app_colors.dart';
import 'package:vietmall_admin/services/auth_service.dart';
import 'package:vietmall_admin/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      List<String> ids = [currentUser.uid, widget.receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .set({
        'unread': {currentUser.uid: 0}
      }, SetOptions(merge: true));
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(
        widget.receiverId,
        widget.receiverName,
        text,
      );
      _messageController.clear();
    } catch (e) {
      // Hiện thông báo lỗi cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi tin nhắn thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text(widget.receiverName); // fallback khi chưa có dữ liệu
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final fullName = data?['fullName'] ?? widget.receiverName;

            return Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Xử lý khi có lỗi hoặc không có dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          return Center(child: Text("Lỗi tải tin nhắn: $err"));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("Hãy gửi tin nhắn đầu tiên của bạn! 😉"));
        }

        // Khi có dữ liệu, xây dựng ListView
        return ListView(
          reverse: true,
          padding: const EdgeInsets.all(8.0),
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final currentUser = FirebaseAuth.instance.currentUser;
    final String? currentUserId = currentUser?.uid;

    bool isCurrentUser = (currentUserId != null) && data['senderId'] == currentUserId;

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    var bubbleColor = isCurrentUser ? AppColors.primaryRed : AppColors.greyLight;
    var textColor = isCurrentUser ? Colors.white : Colors.black87;
    final String messageText = (data['message'] ?? '').toString();

    return Container(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(messageText, style: TextStyle(color: textColor)),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primaryRed),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}