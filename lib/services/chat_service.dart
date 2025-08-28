import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getChatRoomsByAdmin(String adminId) {
    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: adminId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
  //xoa
  Future<void> deleteChatRoom(String chatRoomId) async {
    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    // Xóa tất cả các tin nhắn trong phòng chat
    final messagesSnapshot = await chatRoomRef.collection('messages').get();
    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Xóa phòng chat
    batch.delete(chatRoomRef);

    await batch.commit();
  }
  // Lấy stream các cuộc trò chuyện của người dùng hiện tại
  Stream<QuerySnapshot> getChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Lấy stream các tin nhắn trong một cuộc trò chuyện
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    List<String> ids = [currentUser.uid, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Gửi tin nhắn (ĐÃ SỬA LỖI THỨ TỰ)
  Future<void> sendMessage(String receiverId, String receiverName,
      String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || message
        .trim()
        .isEmpty) return;

    try {
      final String currentUserId = currentUser.uid;
      final String currentUserName = currentUser.displayName ?? 'Người dùng';
      final Timestamp timestamp = Timestamp.now();

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      DocumentReference chatRoom = _firestore.collection('chat_rooms').doc(
          chatRoomId);
      await chatRoom.set({
        'users': [currentUserId, receiverId],
        'userNames': {
          currentUserId: currentUserName,
          receiverId: receiverName,
        },
        'lastMessage': message,
        'lastMessageTimestamp': timestamp,
        'unread': {
          receiverId: FieldValue.increment(1), // tăng cho người nhận
          currentUserId: 0, // người gửi đã đọc rồi
        }
      }, SetOptions(merge: true));

      DocumentReference newMessage = chatRoom.collection('messages').doc();
      await newMessage.set({
        'senderId': currentUserId,
        'message': message,
        'timestamp': timestamp,
      });
    } catch (e) {
      // bạn có thể log cái e ở đây
      rethrow; // để caller bắt và hiển thị
    }
  }
}
