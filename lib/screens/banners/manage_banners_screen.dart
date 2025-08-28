import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  // Document tham chiếu cố định
  final bannerDocRef = FirebaseFirestore.instance.collection('banners').doc('main_banners');

  final _link1Ctrl = TextEditingController();
  final _link2Ctrl = TextEditingController();
  final _link3Ctrl = TextEditingController();
  final _link4Ctrl = TextEditingController();
  final _link5Ctrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _link1Ctrl.dispose();
    _link2Ctrl.dispose();
    _link3Ctrl.dispose();
    _link4Ctrl.dispose();
    _link5Ctrl.dispose();
    super.dispose();
  }

  // Hàm để lưu thay đổi
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await bannerDocRef.set({ // Dùng .set với merge:true hoặc .update
        'link1': _link1Ctrl.text.trim(),
        'link2': _link2Ctrl.text.trim(),
        'link3': _link3Ctrl.text.trim(),
        'link4': _link4Ctrl.text.trim(),
        'link5': _link5Ctrl.text.trim(),
      }, SetOptions(merge: true)); // merge:true để không ghi đè các trường khác nếu có

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thay đổi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
        'Manage Banners',
        style: TextStyle(color: Colors.white),
      ),
        backgroundColor: const Color(0xFF085DAA),),
      body: FutureBuilder<DocumentSnapshot>(
        // Luôn lấy dữ liệu từ document cố định
        future: bannerDocRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy document "main_banners"'));
          }

          // Điền dữ liệu đã có vào các ô TextField
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _link1Ctrl.text = data['link1'] ?? '';
          _link2Ctrl.text = data['link2'] ?? '';
          _link3Ctrl.text = data['link3'] ?? '';
          _link4Ctrl.text = data['link4'] ?? '';
          _link5Ctrl.text = data['link5'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _link1Ctrl, decoration: const InputDecoration(labelText: 'Link ảnh banner 1')),
                const SizedBox(height: 12),
                TextField(controller: _link2Ctrl, decoration: const InputDecoration(labelText: 'Link ảnh banner 2')),
                const SizedBox(height: 12),
                TextField(controller: _link3Ctrl, decoration: const InputDecoration(labelText: 'Link ảnh banner 3')),
                const SizedBox(height: 12),
                TextField(controller: _link4Ctrl, decoration: const InputDecoration(labelText: 'Link ảnh banner 4')),
                const SizedBox(height: 12),
                TextField(controller: _link5Ctrl, decoration: const InputDecoration(labelText: 'Link ảnh banner 5')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Lưu thay đổi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}