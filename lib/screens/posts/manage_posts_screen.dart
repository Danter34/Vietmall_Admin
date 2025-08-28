import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import 'post_detail_dialog.dart';

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminService();
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Posts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF085DAA),
        bottom: TabBar(
          controller: _tab,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Đã Duyệt'),
            Tab(text: 'Từ Chối'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.streamProductsByStatus(status),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(child: Text('No $status posts'));
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final id = docs[i].id;
            return ListTile(
              leading: (d['imageUrls'] is List &&
                  (d['imageUrls'] as List).isNotEmpty)
                  ? CircleAvatar(
                  backgroundImage:
                  NetworkImage((d['imageUrls'] as List).first))
                  : const CircleAvatar(
                  child: Icon(Icons.image_not_supported)),
              title: Text(d['title'] ?? ''),
              subtitle: Text(
                  '${d['price'] ?? 0} • ${d['categoryName'] ?? ''} • by ${d['sellerName'] ?? ''}'),
              trailing: Text(status),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) =>
                      PostDetailDialog(productId: id, data: d),
                );
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: docs.length,
        );
      },
    );
  }
}
