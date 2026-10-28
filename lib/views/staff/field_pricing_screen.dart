import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/field_model.dart';
import '../../data/models/field_pricing_rule_model.dart';
import '../../data/models/golden_day_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/providers.dart';

class FieldPricingScreen extends ConsumerStatefulWidget {
  final FieldModel field;

  const FieldPricingScreen({super.key, required this.field});

  @override
  ConsumerState<FieldPricingScreen> createState() => _FieldPricingScreenState();
}

class _FieldPricingScreenState extends ConsumerState<FieldPricingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isLoadingSlots = false;
  List<TimeSlotModel> _slots = [];

  bool _isLoadingRules = false;
  List<FieldPricingRuleModel> _rules = [];

  bool _isLoadingGoldenDays = false;
  List<GoldenDayModel> _goldenDays = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadSlots();
    _loadRules();
    _loadGoldenDays();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final repo = ref.read(timeSlotRepositoryProvider);
      final list = await repo.getTimeSlots(fieldId: widget.field.id);
      setState(() => _slots = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSlots = false);
  }

  Future<void> _loadRules() async {
    setState(() => _isLoadingRules = true);
    try {
      final repo = ref.read(pricingRepositoryProvider);
      final list = await repo.getRulesForField(widget.field.id);
      setState(() => _rules = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingRules = false);
  }

  Future<void> _loadGoldenDays() async {
    setState(() => _isLoadingGoldenDays = true);
    try {
      final repo = ref.read(pricingRepositoryProvider);
      final list = await repo.getGoldenDays(fieldId: widget.field.id);
      setState(() => _goldenDays = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingGoldenDays = false);
  }

  // --- THAO TÁC KHUNG GIỜ ---
  Future<void> _toggleSlot(TimeSlotModel slot) async {
    final repo = ref.read(pricingRepositoryProvider);
    final (ok, msg) = await repo.toggleSlotStatus(slot.id, !slot.isActive);
    if (ok) {
      _loadSlots();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // --- THAO TÁC QUY TẮC GIÁ ---
  Future<void> _openAddRuleDialog() async {
    final nameCtrl = TextEditingController(text: 'Khung giờ vàng tối');
    final startHourCtrl = TextEditingController(text: '17');
    final endHourCtrl = TextEditingController(text: '21');
    final multiplierCtrl = TextEditingController(text: '1.2');
    final fixedPriceCtrl = TextEditingController();
    final priorityCtrl = TextEditingController(text: '10');

    String dayType = PricingDayType.all;
    int? startMonth;
    int? endMonth;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Thêm quy tắc định giá'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên quy tắc *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: dayType,
                  decoration: const InputDecoration(labelText: 'Áp dụng cho ngày', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: PricingDayType.all, child: Text('Tất cả các ngày')),
                    DropdownMenuItem(value: PricingDayType.weekday, child: Text('Ngày thường (T2 - T6)')),
                    DropdownMenuItem(value: PricingDayType.weekend, child: Text('Cuối tuần (T7, CN)')),
                  ],
                  onChanged: (v) => setDState(() => dayType = v ?? PricingDayType.all),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startHourCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Từ giờ (0-23)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endHourCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Đến giờ (0-23)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: multiplierCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Hệ số giá (VD: 1.2 = tăng 20%, 0.8 = giảm 20%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fixedPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hoặc giá cố định VNĐ (nếu có)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priorityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Độ ưu tiên (Số càng cao càng ưu tiên áp dụng)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu quy tắc'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final sH = int.tryParse(startHourCtrl.text.trim()) ?? 0;
      final eH = int.tryParse(endHourCtrl.text.trim()) ?? 23;
      final mult = double.tryParse(multiplierCtrl.text.trim()) ?? 1.0;
      final fix = double.tryParse(fixedPriceCtrl.text.trim());
      final pri = int.tryParse(priorityCtrl.text.trim()) ?? 0;

      final rule = FieldPricingRuleModel(
        id: '',
        fieldId: widget.field.id,
        name: nameCtrl.text.trim(),
        dayType: dayType,
        startHour: sH,
        endHour: eH,
        startMonth: startMonth,
        endMonth: endMonth,
        priceMultiplier: mult,
        fixedPrice: (fix != null && fix > 0) ? fix : null,
        priority: pri,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(pricingRepositoryProvider);
      final (ok, msg) = await repo.createOrUpdateRule(rule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (ok) _loadRules();
      }
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa quy tắc định giá này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final repo = ref.read(pricingRepositoryProvider);
      final (success, msg) = await repo.deleteRule(ruleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (success) _loadRules();
      }
    }
  }

  // --- THAO TÁC NGÀY VÀNG ---
  Future<void> _openAddGoldenDayDialog() async {
    final nameCtrl = TextEditingController(text: 'Khuyến mãi sân vàng');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final priceMultCtrl = TextEditingController(text: '0.85');
    final pointMultCtrl = TextEditingController(text: '2.0');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Thêm ngày vàng của sân'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên sự kiện / ngày vàng', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('Ngày diễn ra: ${_dateFormat.format(selectedDate)}'),
                onPressed: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (p != null) setDState(() => selectedDate = p);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceMultCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hệ số giá (0.85 = giảm 15%)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pointMultCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hệ số tích điểm (VD: 2.0 = nhân đôi)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thêm ngày vàng'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final pMult = double.tryParse(priceMultCtrl.text.trim()) ?? 1.0;
      final ptMult = double.tryParse(pointMultCtrl.text.trim()) ?? 1.0;

      final gd = GoldenDayModel(
        id: '',
        name: nameCtrl.text.trim(),
        date: selectedDate,
        fieldId: widget.field.id,
        priceMultiplier: pMult,
        pointMultiplier: ptMult,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(pricingRepositoryProvider);
      final (ok, msg) = await repo.createOrUpdateGoldenDay(gd);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (ok) _loadGoldenDays();
      }
    }
  }

  Future<void> _deleteGoldenDay(String gdId) async {
    final repo = ref.read(pricingRepositoryProvider);
    final (ok, msg) = await repo.deleteGoldenDay(gdId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (ok) _loadGoldenDays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giá & Khung giờ - ${widget.field.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Khung giờ'),
            Tab(icon: Icon(Icons.rule), text: 'Quy tắc giá'),
            Tab(icon: Icon(Icons.stars), text: 'Ngày vàng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: KHUNG GIỜ
          _isLoadingSlots
              ? const Center(child: CircularProgressIndicator())
              : _slots.isEmpty
                  ? const Center(child: Text('Chưa có khung giờ nào cho sân này.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _slots.length,
                      itemBuilder: (ctx, index) {
                        final slot = _slots[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              slot.isActive ? Icons.check_circle : Icons.pause_circle_outline,
                              color: slot.isActive ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: slot.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text('Giá cơ bản: ${_currencyFormat.format(slot.price)}'),
                            trailing: Switch(
                              value: slot.isActive,
                              activeThumbColor: Colors.teal,
                              onChanged: (_) => _toggleSlot(slot),
                            ),
                          ),
                        );
                      },
                    ),

          // TAB 2: QUY TẮC GIÁ
          _isLoadingRules
              ? const Center(child: CircularProgressIndicator())
              : Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: _openAddRuleDialog,
                    backgroundColor: Colors.teal,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm quy tắc'),
                  ),
                  body: _rules.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Chưa có quy tắc giá linh hoạt.\nNhấn "Thêm quy tắc" để thiết lập giá theo giờ cao điểm/cuối tuần/mùa giải!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
                          itemCount: _rules.length,
                          itemBuilder: (ctx, index) {
                            final r = _rules[index];
                            final dayLabel = r.dayType == PricingDayType.weekend
                                ? 'Cuối tuần'
                                : r.dayType == PricingDayType.weekday
                                    ? 'Ngày thường'
                                    : 'Tất cả các ngày';

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          r.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _deleteRule(r.id),
                                        ),
                                      ],
                                    ),
                                    Text('Áp dụng: $dayLabel, từ ${r.startHour}:00 đến ${r.endHour}:00'),
                                    if (r.fixedPrice != null)
                                      Text(
                                        'Giá ấn định: ${_currencyFormat.format(r.fixedPrice)}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      )
                                    else
                                      Text(
                                        'Hệ số nhân: x${r.priceMultiplier} (${((r.priceMultiplier - 1) * 100).toStringAsFixed(0)}%)',
                                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                                      ),
                                    Text('Mức ưu tiên: ${r.priority}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

          // TAB 3: NGÀY VÀNG
          _isLoadingGoldenDays
              ? const Center(child: CircularProgressIndicator())
              : Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: _openAddGoldenDayDialog,
                    backgroundColor: Colors.amber.shade700,
                    icon: const Icon(Icons.stars),
                    label: const Text('Thêm ngày vàng'),
                  ),
                  body: _goldenDays.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Chưa có Ngày Vàng nào cho sân này.\nThêm ngày vàng để kích cầu giảm giá sân và nhân đôi điểm tích lũy!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
                          itemCount: _goldenDays.length,
                          itemBuilder: (ctx, index) {
                            final gd = _goldenDays[index];
                            return Card(
                              color: Colors.amber.shade50,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.stars, color: Colors.amber, size: 36),
                                title: Text(gd.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ngày: ${_dateFormat.format(gd.dateTime)}'),
                                    Text('Hệ số giá: x${gd.priceMultiplier} | Nhân điểm: x${gd.pointMultiplier}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteGoldenDay(gd.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
