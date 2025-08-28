import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import 'package:intl/intl.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  static const List<String> activeStatuses = [
    'Đang xử lý',
    'Đang vận chuyển',
    'Đang giao hàng',
  ];
  static const List<String> historyStatuses = [
    'Đã giao',
    'Đã hủy',
  ];
  static const List<String> allStatuses = [
    'Đang xử lý',
    'Đang vận chuyển',
    'Đang giao hàng',
    'Đã giao',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Orders',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF085DAA),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Đang hoạt động"),
            Tab(text: "Lịch sử"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(statuses: activeStatuses),
          _buildOrderList(statuses: historyStatuses),
        ],
      ),
    );
  }

  Widget _buildOrderList({required List<String> statuses}) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _adminService.streamOrders(statuses: statuses),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('Không có đơn hàng nào.'));
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final id = docs[i].id;
            final itemsCount = (d['items'] as List? ?? []).length;
            String currentStatus = d['status'] ?? 'Đang xử lý';
            return ListTile(
              onTap: () {
                // Điều hướng đến màn hình chi tiết đơn hàng
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: id),
                  ),
                );
              },
              title: Text('Đơn hàng #${id.substring(0, 6)}...'),
              subtitle: Text(
                  'Khách: ${d['userId']} • $itemsCount sản phẩm\nTổng tiền: ${formatter.format(d['totalPrice'])}'),
              trailing: DropdownButton<String>(
                value: allStatuses.contains(currentStatus)
                    ? currentStatus
                    : 'Đang xử lý',
                onChanged: (v) {
                  if (v != null) {
                    _adminService.updateOrderStatus(id, v);
                  }
                },
                items: allStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: docs.length,
        );
      },
    );
  }
}

// Thêm màn hình chi tiết đơn hàng cho admin (dùng lại code của client)
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final service = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn hàng #${orderId.substring(0, 6)}..."),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = data['items'] as List;
          final address = data['shippingAddress'] as Map<String, dynamic>;
          String currentStatus = data['status'] ?? 'Đang xử lý';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Trạng thái:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _ManageOrdersScreenState.allStatuses.contains(currentStatus)
                        ? currentStatus
                        : 'Đang xử lý',
                    onChanged: (v) {
                      if (v != null) {
                        service.updateOrderStatus(orderId, v);
                        // Cập nhật giao diện ngay lập tức
                        (context as Element).markNeedsBuild();
                      }
                    },
                    items: _ManageOrdersScreenState.allStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text("Địa chỉ giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(address['name'] ?? ''),
              Text(address['phone'] ?? ''),
              Text(address['address'] ?? ''),
              const Divider(height: 32),
              const Text("Sản phẩm đã đặt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...items.map((item) {
                return ListTile(
                  leading: SizedBox(width: 50, height: 50, child: Image.network(item['imageUrl'])),
                  title: Text(item['title']),
                  subtitle: Text("${formatter.format(item['price'])} x ${item['quantity']}"),
                );
              }).toList(),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng tiền:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(formatter.format(data['totalPrice']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}