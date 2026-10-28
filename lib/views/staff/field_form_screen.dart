import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/field_model.dart';
import '../../viewmodels/field_manage_viewmodel.dart';

class FieldFormScreen extends ConsumerStatefulWidget {
  final FieldModel? field;

  const FieldFormScreen({super.key, this.field});

  @override
  ConsumerState<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _FieldFormScreenState extends ConsumerState<FieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _priceController;
  late final TextEditingController _peakPriceController;
  late final TextEditingController _cashbackController;
  late final TextEditingController _descriptionController;

  String? _selectedTypeId;
  String _status = FieldStatus.active;
  bool _acceptWalletPayment = true;
  bool _isSaving = false;

  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _nameController = TextEditingController(text: f?.fieldName ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    _wardController = TextEditingController(text: f?.ward.isNotEmpty == true ? f!.ward : '');
    _districtController = TextEditingController(text: f?.district.isNotEmpty == true ? f!.district : '');
    _cityController = TextEditingController(text: f?.city.isNotEmpty == true ? f!.city : (f?.province ?? 'Hà Nội'));
    _priceController = TextEditingController(text: f != null ? f.pricePerHour.toStringAsFixed(0) : '');
    _peakPriceController = TextEditingController(text: f != null ? f.peakPricePerHour.toStringAsFixed(0) : '');
    _cashbackController = TextEditingController(text: f != null ? f.cashbackPercent.toStringAsFixed(0) : '0');
    _descriptionController = TextEditingController(text: f?.description ?? '');
    _selectedTypeId = f?.fieldTypeId;
    _status = f?.status ?? FieldStatus.active;
    _acceptWalletPayment = f?.acceptWalletPayment ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _peakPriceController.dispose();
    _cashbackController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn loại sân')));
      return;
    }

    setState(() => _isSaving = true);
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final peakPrice = double.tryParse(_peakPriceController.text) ?? price;
    final cashback = double.tryParse(_cashbackController.text) ?? 0.0;

    final field = FieldModel(
      id: widget.field?.id ?? '',
      fieldName: _nameController.text.trim(),
      fieldTypeId: _selectedTypeId!,
      ownerId: widget.field?.ownerId ?? '',
      address: _addressController.text.trim(),
      ward: _wardController.text.trim(),
      province: _cityController.text.trim(),
      district: _districtController.text.trim(),
      city: _cityController.text.trim(),
      pricePerHour: price,
      peakPricePerHour: peakPrice <= 0 ? price : peakPrice,
      acceptWalletPayment: _acceptWalletPayment,
      cashbackPercent: cashback.toInt().clamp(0, 50),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      status: _status,
      createdAt: widget.field?.createdAt ?? DateTime.now(),
    );

    final (success, msg) = await ref
        .read(fieldManageViewModelProvider.notifier)
        .saveField(field, _isEditing);

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
    final state = ref.watch(fieldManageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Cập nhật sân' : 'Thêm sân mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sân *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sân' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Loại sân *', border: OutlineInputBorder()),
                initialValue: _selectedTypeId,
                items: state.fieldTypes
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.typeName)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTypeId = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết (Số nhà, ngõ/ngách, tên đường) *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wardController,
                      decoration: const InputDecoration(labelText: 'Phường / Xã', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'Quận / Huyện *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập quận/huyện' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Tỉnh / Thành phố *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tỉnh/thành phố' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Giá thường /h (VND) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập giá' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _peakPriceController,
                      decoration: const InputDecoration(labelText: 'Giá cao điểm /h', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.teal.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.teal.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nhận thanh toán bằng Ví điện tử', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Cho phép khách trừ tiền ví SportsBook khi đặt sân'),
                        value: _acceptWalletPayment,
                        activeThumbColor: Colors.teal,
                        onChanged: (val) => setState(() => _acceptWalletPayment = val),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cashbackController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tỷ lệ hoàn tiền ví (% Cashback cho khách, tối đa 50%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n != null && (n < 0 || n > 50)) {
                            return 'Hoàn tiền từ 0% đến 50%';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Trạng thái hoạt động', border: OutlineInputBorder()),
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: FieldStatus.active, child: Text('Đang hoạt động (Active)')),
                    DropdownMenuItem(value: FieldStatus.closed, child: Text('Đóng sân (Closed)')),
                    DropdownMenuItem(value: FieldStatus.maintenance, child: Text('Đang bảo trì (Maintenance)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Lưu thay đổi' : 'Tạo sân và sinh 16 khung giờ', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
