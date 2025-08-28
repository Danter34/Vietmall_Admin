import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==== THÊM HÀM THÔNG BÁO MỚI ====
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
      'data': data ?? {},
    });
  }

  // Stream đếm số thông báo chưa đọc
  Stream<int> getUnreadNotificationCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Đánh dấu tất cả thông báo chưa đọc là đã đọc
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final unreadDocs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      // Sử dụng try-catch để cập nhật từng tài liệu
      try {
        await doc.reference.update({'read': true});
      } catch (e) {
        // In lỗi ra để kiểm tra
        print('Lỗi khi cập nhật tài liệu ${doc.id}: $e');
      }
    }
  }
  // ==== KẾT THÚC THÊM HÀM THÔNG BÁO MỚI ====

  // ---- USERS ----
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers({String? searchQuery}) {
    // 1. Tạo một truy vấn cơ bản.
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    // 2. Kiểm tra nếu có chuỗi tìm kiếm.
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Nếu có, thêm điều kiện lọc và sắp xếp theo tên.
      query = query
          .where('fullName', isGreaterThanOrEqualTo: searchQuery)
          .where('fullName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .orderBy('fullName');
    } else {
      // Nếu không, sắp xếp mặc định theo thời gian tạo.
      query = query.orderBy('createdAt', descending: true);
    }

    // 3. Trả về stream của truy vấn.
    return query.snapshots();
  }

  Future<void> setUserActive(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).set(
        {'isActive': isActive}, SetOptions(merge: true));
  }

  Future<void> setUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).set(
        {'role': role}, SetOptions(merge: true));
  }

  // ---- PRODUCTS (POSTS) ----
  // Moderation status: 'pending' | 'approved' | 'rejected'
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProductsByStatus(
      String status) {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> approveProduct(String productId) async {
    // Lấy thông tin sản phẩm để gửi thông báo
    final productDoc = await _firestore.collection('products').doc(productId).get();
    final productData = productDoc.data();
    if (productData == null) return;
    final sellerId = productData['sellerId'] as String;
    final title = productData['title'] as String;

    // ✅ Update trong products
    await _firestore.collection('products').doc(productId).set({
      'status': 'approved',
      'isHidden': false, // cho hiện luôn khi duyệt
    }, SetOptions(merge: true));

    // ✅ Update trong feed_posts (nếu có)
    final feedPosts = await _firestore
        .collection('feed_posts')
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in feedPosts.docs) {
      await doc.reference.set({
        'status': 'approved',
        'isHidden': false,
      }, SetOptions(merge: true));
    }

    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO NGƯỜI BÁN VÀ ADMIN ====
    // Tạo thông báo cho người bán
    await createNotification(
      userId: sellerId,
      title: '✅ Tin đăng của bạn đã được duyệt!',
      body: 'Tin đăng "${title}" của bạn đã được phê duyệt và hiển thị.',
      type: 'product',
      data: {'productId': productId},
    );

    // Tạo thông báo cho Admin
    final adminId = _auth.currentUser!.uid;
    await createNotification(
      userId: adminId,
      title: '✅ Tin đăng đã được duyệt',
      body: 'Bạn đã thành công duyệt tin đăng "${title}".',
      type: 'admin_action',
      data: {'productId': productId},
    );
  }

  Future<void> rejectProduct(String productId, {String? reason}) async {
    // Lấy thông tin sản phẩm để gửi thông báo
    final productDoc = await _firestore.collection('products').doc(productId).get();
    final productData = productDoc.data();
    if (productData == null) return;
    final sellerId = productData['sellerId'] as String;
    final title = productData['title'] as String;

    // ❌ Update trong products
    await _firestore.collection('products').doc(productId).set({
      'status': 'rejected',
      if (reason != null) 'rejectedReason': reason,
    }, SetOptions(merge: true));

    // ❌ Update trong feed_posts (nếu có)
    final feedPosts = await _firestore
        .collection('feed_posts')
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in feedPosts.docs) {
      await doc.reference.set({
        'status': 'rejected',
        if (reason != null) 'rejectedReason': reason,
      }, SetOptions(merge: true));
    }

    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO NGƯỜI BÁN VÀ ADMIN ====
    // Tạo thông báo cho người bán
    await createNotification(
      userId: sellerId,
      title: '❌ Tin đăng của bạn đã bị từ chối!',
      body: 'Tin đăng "${title}" đã bị từ chối. Lý do: ${reason ?? 'Không có lý do cụ thể.'}',
      type: 'product',
      data: {'productId': productId},
    );

    // Tạo thông báo cho Admin
    final adminId = _auth.currentUser!.uid;
    await createNotification(
      userId: adminId,
      title: '❌ Tin đăng đã bị từ chối',
      body: 'Bạn đã từ chối tin đăng "${title}".',
      type: 'admin_action',
      data: {'productId': productId},
    );
  }

  // ---- ORDERS ----
  Stream<QuerySnapshot<Map<String, dynamic>>> streamOrders(
      {List<String>? statuses}) {
    var ref = _firestore.collection('orders').orderBy(
        'createdAt', descending: true).withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? {},
      toFirestore: (data, _) => data,
    );
    if (statuses != null && statuses.isNotEmpty) {
      return ref.where('status', whereIn: statuses).snapshots();
    }
    return ref.snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data();
    if (orderData == null) return;
    final userId = orderData['userId'] as String;

    await _firestore.collection('orders').doc(orderId).update(
        {'status': status});

    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO NGƯỜI MUA VÀ ADMIN ====
    // Tạo thông báo cho người mua
    await createNotification(
      userId: userId,
      title: '✅ Đơn hàng đã được xử lý!',
      body: 'Đơn hàng #${orderId} của bạn đã được cập nhật trạng thái: $status',
      type: 'order',
      data: {'orderId': orderId},
    );
  }

  // ---- BANNERS ----
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBanners() {
    return _firestore
        .collection('banners')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Tạo một banner mới trong Firestore.
  Future<void> createBanner({
    String? link1,
    String? link2,
    String? link3,
    String? link4,
    String? link5,
    bool isActive = true,
  }) async {
    final ref = _firestore.collection('banners').doc();
    await ref.set({
      'bannerId': ref.id,
      'link1': link1,
      'link2': link2,
      'link3': link3,
      'link4': link4,
      'link5': link5,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật thông tin của một banner đã có.
  Future<void> updateBanner({
    required String bannerId,
    String? link1,
    String? link2,
    String? link3,
    String? link4,
    String? link5,
    bool? isActive,
  }) async {
    final Map<String, dynamic> data = {};

    // Ghi chú: Chỉ thêm các trường có giá trị vào map để cập nhật,
    // tránh ghi đè dữ liệu không mong muốn.
    if (link1 != null) data['link1'] = link1;
    if (link2 != null) data['link2'] = link2;
    if (link3 != null) data['link3'] = link3;
    if (link4 != null) data['link4'] = link4;
    if (link5 != null) data['link5'] = link5;
    if (isActive != null) data['isActive'] = isActive;

    // Chỉ thực hiện update nếu có dữ liệu để thay đổi
    if (data.isNotEmpty) {
      await _firestore.collection('banners').doc(bannerId).update(data);
    }
    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO ADMIN ====
    final adminId = _auth.currentUser!.uid;
    await createNotification(
      userId: adminId,
      title: '🖼️ Cập nhật banner thành công',
      body: 'Bạn đã thay đổi thông tin banner thành công!',
      type: 'admin_action',
    );
  }

  /// Bật/tắt trạng thái hiển thị của một banner.
  Future<void> toggleBannerActive(String bannerId, bool newValue) async {
    await _firestore
        .collection('banners')
        .doc(bannerId)
        .update({'isActive': newValue});
  }

  /// Xóa một banner khỏi Firestore.
  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }
}