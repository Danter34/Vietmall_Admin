import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy thông tin người dùng
  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Lấy thông tin chi tiết của một người dùng
  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}