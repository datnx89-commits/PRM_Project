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
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _priceController;
  late final TextEditingController _peakPriceController;
  late final TextEditingController _descriptionController;

  String? _selectedTypeId;
  String _status = FieldStatus.active;
  bool _isSaving = false;

  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _nameController = TextEditingController(text: f?.fieldName ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    _districtController = TextEditingController(text: f?.district ?? '');
    _cityController = TextEditingController(text: f?.city ?? '');
    _priceController = TextEditingController(text: f != null ? f.pricePerHour.toStringAsFixed(0) : '');
    _peakPriceController = TextEditingController(text: f != null ? f.peakPricePerHour.toStringAsFixed(0) : '');
    _descriptionController = TextEditingController(text: f?.description ?? '');
    _selectedTypeId = f?.fieldTypeId;
    _status = f?.status ?? FieldStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _peakPriceController.dispose();
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

    final field = FieldModel(
      id: widget.field?.id ?? '',
      fieldName: _nameController.text.trim(),
      fieldTypeId: _selectedTypeId!,
      ownerId: widget.field?.ownerId ?? '',
      address: _addressController.text.trim(),
      district: _districtController.text.trim(),
      city: _cityController.text.trim(),
      pricePerHour: price,
      peakPricePerHour: peakPrice <= 0 ? price : peakPrice,
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sân', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sân' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Loại sân', border: OutlineInputBorder()),
                initialValue: _selectedTypeId,
                items: state.fieldTypes
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.typeName)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTypeId = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ (Số nhà, tên đường)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'Quận / Huyện', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập quận' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Thành phố', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập TP' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Giá thường /h (VND)', border: OutlineInputBorder()),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: FieldStatus.active, child: Text('Đang hoạt động (Active)')),
                    DropdownMenuItem(value: FieldStatus.closed, child: Text('Đóng sân (Closed)')),
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
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'Lưu thay đổi' : 'Tạo sân và sinh 16 khung giờ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
