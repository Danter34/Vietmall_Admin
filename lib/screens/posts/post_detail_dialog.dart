import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class PostDetailDialog extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;
  const PostDetailDialog({super.key, required this.productId, required this.data});

  @override
  State<PostDetailDialog> createState() => _PostDetailDialogState();
}

class _PostDetailDialogState extends State<PostDetailDialog> {
  final _service = AdminService();
  final _rejectCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _rejectCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    try {
      setState(() => _busy = true);
      await _service.approveProduct(widget.productId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Approve failed: $e")),
        );
      }
    }
  }

  Future<void> _reject() async {
    try {
      setState(() => _busy = true);
      final reason = _rejectCtrl.text.trim();
      await _service.rejectProduct(widget.productId, reason: reason.isEmpty ? null : reason);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reject failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final status = d['status'];

    return AlertDialog(
      title: Text(d['title'] ?? 'Post'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d['imageUrls'] is List && (d['imageUrls'] as List).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  (d['imageUrls'] as List).first,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text('Price: ${d['price'] ?? 0}'),
            Text('Category: ${d['categoryName'] ?? ''}'),
            Text('Seller: ${d['sellerName'] ?? ''}'),
            const SizedBox(height: 8),
            Text(d['description'] ?? ''),
            const SizedBox(height: 12),
            if (status != 'rejected') // Chỉ hiển thị nếu không phải trạng thái rejected
              TextField(
                controller: _rejectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reject reason (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            if (status == 'rejected' && d['rejectReason'] != null)
              Text('Reject Reason: ${d['rejectReason']}')
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (status != 'rejected') // Hiển thị nút Reject nếu trạng thái không phải là rejected
          TextButton(
            onPressed: _busy ? null : _reject,
            child: _busy ? const CircularProgressIndicator() : const Text('Reject'),
          ),
        if (status != 'approved') // Hiển thị nút Approve nếu trạng thái không phải là approved
          FilledButton(
            onPressed: _busy ? null : _approve,
            child: _busy ? const CircularProgressIndicator() : const Text('Approve'),
          ),
      ],
    );
  }
}