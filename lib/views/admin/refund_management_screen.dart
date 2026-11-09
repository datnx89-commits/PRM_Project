import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/refund_request_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../shared/app_drawer.dart';

class RefundManagementScreen extends ConsumerStatefulWidget {
  const RefundManagementScreen({super.key});

  @override
  ConsumerState<RefundManagementScreen> createState() =>
      _RefundManagementScreenState();
}

class _RefundManagementScreenState
    extends ConsumerState<RefundManagementScreen> {
  String _selectedStatus = RefundStatus.pending;
  bool _isLoading = false;
  int _loadRequestId = 0;
  List<RefundRequestModel> _refunds = [];
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Future<void> _loadRefunds() async {
    final requestId = ++_loadRequestId;
    final selectedStatus = _selectedStatus;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(refundRepositoryProvider);
      final list = await repo.getRefundRequests(
        status: selectedStatus == 'ALL' ? null : selectedStatus,
      );
      if (mounted && requestId == _loadRequestId) {
        setState(() => _refunds = list);
      }
    } catch (e) {
      if (mounted && requestId == _loadRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách hoàn tiền: $e')),
        );
      }
    } finally {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmTransfer(RefundRequestModel req) async {
    final noteController = TextEditingController();
    bool creditToWallet = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Xác nhận đã chuyển khoản'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking: #${req.bookingId.length > 8 ? req.bookingId.substring(0, 8) : req.bookingId}'),
                const SizedBox(height: 4),
                Text(
                  'Số tiền: ${_currencyFormat.format(req.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text('Ngân hàng: ${_orMissing(req.bankName)}'),
                Text('Số TK: ${_orMissing(req.bankAccountNumber)}'),
                Text('Chủ TK: ${_orMissing(req.bankAccountHolder)}'),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch / Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: creditToWallet,
                  activeColor: Colors.teal,
                  title: const Text('Cộng tiền vào Ví SportsBook của khách', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cộng số dư ví để khách kiểm tra ngay ở Dashboard / Ví', style: TextStyle(fontSize: 11)),
                  onChanged: (v) => setModalState(() => creditToWallet = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Xác nhận đã chuyển'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final user = ref.read(authViewModelProvider).user;
      final repo = ref.read(refundRepositoryProvider);
      try {
        final (success, msg) = await repo.markTransferred(
          refundRequestId: req.id,
          processedById: user?.id ?? 'admin',
          note: noteController.text.trim(),
          creditToWallet: creditToWallet,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
          );
          if (success) _loadRefunds();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể cập nhật yêu cầu hoàn tiền. Vui lòng thử lại.')),
          );
        }
      }
    }
  }

  bool _hasBankInfo(RefundRequestModel req) =>
      (req.bankAccountNumber ?? '').trim().isNotEmpty;

  String _orMissing(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Chưa cung cấp' : v;

  Future<void> _refundToWallet(RefundRequestModel req) async {
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn tiền vào Ví SportsBook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking: #${req.bookingId.length > 8 ? req.bookingId.substring(0, 8) : req.bookingId}'),
            Text('Khách hàng: ${req.userName ?? req.userId}'),
            const SizedBox(height: 4),
            Text(
              'Cộng vào ví: ${_currencyFormat.format(req.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiền được cộng ngay vào ví của khách, khách nhận thông báo realtime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cộng vào ví'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final user = ref.read(authViewModelProvider).user;
      final repo = ref.read(refundRepositoryProvider);
      try {
        final (success, msg) = await repo.refundToWallet(
          refundRequestId: req.id,
          processedById: user?.id ?? 'admin',
          note: noteController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
          );
          if (success) _loadRefunds();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể hoàn tiền vào ví. Vui lòng thử lại.')),
          );
        }
      }
    }
  }

  Future<void> _rejectRefund(RefundRequestModel req) async {
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu hoàn tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking: #${req.bookingId.length > 8 ? req.bookingId.substring(0, 8) : req.bookingId}'),
            const SizedBox(height: 4),
            Text(
              'Số tiền: ${_currencyFormat.format(req.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (bắt buộc)',
                hintText: 'Nhập lý do gửi đến khách hàng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final user = ref.read(authViewModelProvider).user;
      final repo = ref.read(refundRepositoryProvider);
      try {
        final (success, msg) = await repo.rejectRefund(
          refundRequestId: req.id,
          processedById: user?.id ?? 'admin',
          note: noteController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.red),
          );
          if (success) _loadRefunds();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể cập nhật yêu cầu hoàn tiền. Vui lòng thử lại.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hoàn tiền STK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRefunds,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: RefundStatus.pending, label: Text('Chờ chuyển')),
                      ButtonSegment(value: RefundStatus.completed, label: Text('Đã xong')),
                      ButtonSegment(value: RefundStatus.rejected, label: Text('Từ chối')),
                      ButtonSegment(value: 'ALL', label: Text('Tất cả')),
                    ],
                    selected: {_selectedStatus},
                    onSelectionChanged: (val) {
                      setState(() => _selectedStatus = val.first);
                      _loadRefunds();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _refunds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không có yêu cầu hoàn tiền nào',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRefunds,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _refunds.length,
                          itemBuilder: (ctx, index) {
                            final req = _refunds[index];
                            final isRejected = req.status == RefundStatus.rejected;
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: req.isCompleted
                                      ? Colors.green.shade200
                                      : (isRejected ? Colors.red.shade200 : Colors.orange.shade200),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Đơn: #${req.bookingId.length > 8 ? req.bookingId.substring(0, 8) : req.bookingId}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Chip(
                                          label: Text(
                                            req.statusText,
                                            style: TextStyle(
                                              color: req.isCompleted
                                                  ? Colors.green.shade800
                                                  : (isRejected ? Colors.red.shade800 : Colors.orange.shade800),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: req.isCompleted
                                              ? Colors.green.shade50
                                              : (isRejected ? Colors.red.shade50 : Colors.orange.shade50),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Số tiền hoàn: ${_currencyFormat.format(req.amount)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    const Text('Thông tin chuyển khoản:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 6),
                                        Text('Ngân hàng: ${_orMissing(req.bankName)}'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.numbers, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Số TK: ${_orMissing(req.bankAccountNumber)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 6),
                                        Text('Chủ TK: ${_orMissing(req.bankAccountHolder)}'),
                                      ],
                                    ),
                                    if (req.reason.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Lý do: ${req.reason}',
                                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ngày yêu cầu: ${_dateFormat.format(req.createdAt)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    if (req.processedAt != null) ...[
                                      Text(
                                        'Đã xử lý lúc: ${_dateFormat.format(req.processedAt!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: req.isCompleted ? Colors.green.shade600 : Colors.red.shade600,
                                        ),
                                      ),
                                      if (req.processedNote != null && req.processedNote!.isNotEmpty)
                                        Text(
                                          isRejected
                                              ? 'Lý do từ chối: ${req.processedNote}'
                                              : 'Ghi chú/Mã GD: ${req.processedNote}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isRejected ? Colors.red.shade700 : Colors.grey.shade700,
                                            fontWeight: isRejected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                    if (req.isPending) ...[
                                      if (!_hasBankInfo(req)) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Khách chưa nhập STK: hãy hoàn vào ví, hoặc nhắc khách cập nhật STK trong màn Ví.',
                                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _rejectRefund(req),
                                            icon: const Icon(Icons.close, size: 18),
                                            label: const Text('Từ chối'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => _refundToWallet(req),
                                            icon: const Icon(Icons.account_balance_wallet, size: 18),
                                            label: const Text('Hoàn vào ví'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _hasBankInfo(req) ? () => _confirmTransfer(req) : null,
                                            icon: const Icon(Icons.check_circle_outline, size: 18),
                                            label: const Text('Xác nhận đã chuyển'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
