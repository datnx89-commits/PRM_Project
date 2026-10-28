import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/promotion_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/promotion_viewmodel.dart';

class PromotionFormScreen extends ConsumerStatefulWidget {
  final PromotionModel? promo;

  const PromotionFormScreen({super.key, this.promo});

  @override
  ConsumerState<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends ConsumerState<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountPercentController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _quantityController;

  late String _startDate;
  late String _endDate;
  bool _isSaving = false;

  bool get _isEditing => widget.promo != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _codeController = TextEditingController(text: p?.code ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _discountPercentController = TextEditingController(text: p != null ? p.discountPercent.toString() : '');
    _maxDiscountController = TextEditingController(text: p != null ? p.maxDiscount.toStringAsFixed(0) : '0');
    _quantityController = TextEditingController(text: p != null ? p.quantity.toString() : '100');

    final now = DateTime.now();
    _startDate = p?.startDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final future = now.add(const Duration(days: 30));
    _endDate = p?.endDate ?? '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountPercentController.dispose();
    _maxDiscountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final currentStr = isStart ? _startDate : _endDate;
    final currentDt = DateTime.tryParse(currentStr) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final str = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startDate = str;
        } else {
          _endDate = str;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final percent = int.tryParse(_discountPercentController.text) ?? 0;
    final maxDisc = double.tryParse(_maxDiscountController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 0;

    final currentUser = ref.read(authViewModelProvider).user;
    final isAdmin = currentUser?.role == 'Admin' || currentUser?.role == 'SuperAdmin';
    final ownerId = widget.promo != null ? widget.promo?.ownerId : (isAdmin ? null : currentUser?.id);

    final promo = PromotionModel(
      id: widget.promo?.id ?? '',
      code: _codeController.text.trim().toUpperCase(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      discountPercent: percent,
      maxDiscount: maxDisc,
      startDate: _startDate,
      endDate: _endDate,
      quantity: qty,
      isActive: widget.promo?.isActive ?? true,
      ownerId: ownerId,
    );

    final vm = ref.read(promotionViewModelProvider.notifier);
    final (success, msg) = _isEditing
        ? await vm.updatePromotion(promo)
        : await vm.createPromotion(promo);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authViewModelProvider).user;
    final isAdmin = currentUser?.role == 'Admin' || currentUser?.role == 'SuperAdmin';
    final isOwnerPromo = widget.promo != null ? widget.promo?.ownerId != null : !isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa khuyến mãi' : 'Tạo khuyến mãi mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isOwnerPromo ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOwnerPromo ? Colors.green.shade300 : Colors.blue.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOwnerPromo ? Icons.storefront : Icons.public,
                      color: isOwnerPromo ? Colors.green.shade700 : Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOwnerPromo
                            ? 'Phạm vi: Áp dụng riêng cho các sân bóng của bạn.'
                            : 'Phạm vi: Toàn hệ thống (khách áp dụng được cho mọi sân).',
                        style: TextStyle(
                          fontSize: 13,
                          color: isOwnerPromo ? Colors.green.shade900 : Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Mã khuyến mãi (VD: SUMMER26)', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountPercentController,
                      decoration: const InputDecoration(labelText: 'Phần trăm giảm (1-100)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 100) return 'Từ 1 đến 100';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxDiscountController,
                      decoration: const InputDecoration(labelText: 'Giảm tối đa (0 = kgh)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng mã phát hành', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Nhập số lượng >= 0' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text('Bắt đầu: ${Formatters.dateString(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text('Kết thúc: ${Formatters.dateString(_endDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'Cập nhật' : 'Tạo khuyến mãi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
