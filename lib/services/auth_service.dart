import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Phương thức đăng nhập cho admin
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 🔒 Kiểm tra vai trò (role) của người dùng
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists || doc['role'] != 'admin') {
          // Nếu không tồn tại hoặc không phải admin, đăng xuất ngay lập tức
          await _auth.signOut();
          return "Bạn không có quyền truy cập";
        }

        // 🔍 Kiểm tra trạng thái isActive
        if (!(doc['isActive'] ?? true)) {
          await _auth.signOut();
          return "Tài khoản của bạn đã bị khóa";
        }
      }

      return null; // Đăng nhập thành công
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Phương thức đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}