import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/data/models/field_model.dart';
import 'package:sportsbook_36vn/data/models/field_type_model.dart';
import 'package:sportsbook_36vn/viewmodels/field_manage_viewmodel.dart';
import 'package:sportsbook_36vn/views/staff/field_form_screen.dart';

class FakeFieldManageViewModel extends StateNotifier<FieldManageState>
    implements FieldManageViewModel {
  FakeFieldManageViewModel()
      : super(FieldManageState(fieldTypes: [FieldTypeModel(id: 't1', typeName: 'Bóng đá')]));

  FieldModel? saved;
  bool? savedAsEditing;

  @override
  Future<(bool, String)> saveField(FieldModel field, bool isEditing) async {
    saved = field;
    savedAsEditing = isEditing;
    return (true, 'OK');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFieldManageViewModel vm;

  Future<void> pumpForm(WidgetTester tester, {FieldModel? field}) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    vm = FakeFieldManageViewModel();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fieldManageViewModelProvider.overrideWith((ref) => vm)],
        child: MaterialApp(home: FieldFormScreen(field: field)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder input(String label) =>
      find.widgetWithText(TextFormField, label);

  Future<void> fillRequired(WidgetTester tester, {String price = '200000', String peak = ''}) async {
    await tester.enterText(input('Tên sân *'), 'Sân Test');
    await tester.enterText(input('Địa chỉ chi tiết (Số nhà, ngõ/ngách, tên đường) *'), '1 Trần Duy Hưng');
    await tester.enterText(input('Quận / Huyện *'), 'Cầu Giấy');
    await tester.enterText(input('Giá thường /h (VND) *'), price);
    await tester.enterText(input('Giá cao điểm /h'), peak);
    await tester.tap(find.text('Loại sân *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bóng đá').last);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets('Bo trong thi bao loi cac o bat buoc va khong luu', (tester) async {
    await pumpForm(tester);
    await submit(tester);
    expect(find.text('Vui lòng nhập tên sân'), findsOneWidget);
    expect(find.text('Vui lòng nhập địa chỉ'), findsOneWidget);
    expect(find.text('Nhập quận/huyện'), findsOneWidget);
    expect(find.text('Nhập giá hợp lệ (> 0)'), findsOneWidget);
    expect(vm.saved, isNull);
  });

  for (final bad in ['abc', '0', '-5']) {
    testWidgets('Gia thuong "$bad" bi tu choi', (tester) async {
      await pumpForm(tester);
      await fillRequired(tester, price: bad);
      await submit(tester);
      expect(find.text('Nhập giá hợp lệ (> 0)'), findsOneWidget);
      expect(vm.saved, isNull);
    });
  }

  testWidgets('Gia cao diem nhap chu bi tu choi', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, peak: 'abc');
    await submit(tester);
    expect(find.text('Giá không hợp lệ'), findsOneWidget);
    expect(vm.saved, isNull);
  });

  testWidgets('Cashback ngoai 0-50 bi tu choi', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester);
    await tester.enterText(input('Tỷ lệ hoàn tiền ví (% Cashback cho khách, tối đa 50%)'), '60');
    await submit(tester);
    expect(find.text('Hoàn tiền từ 0% đến 50%'), findsOneWidget);
    expect(vm.saved, isNull);
  });

  testWidgets('Chua chon loai san thi bao loi', (tester) async {
    await pumpForm(tester);
    await tester.enterText(input('Tên sân *'), 'Sân Test');
    await tester.enterText(input('Địa chỉ chi tiết (Số nhà, ngõ/ngách, tên đường) *'), '1 TDH');
    await tester.enterText(input('Quận / Huyện *'), 'Cầu Giấy');
    await tester.enterText(input('Giá thường /h (VND) *'), '200000');
    await submit(tester);
    expect(find.text('Vui lòng chọn loại sân'), findsOneWidget);
    expect(vm.saved, isNull);
  });

  testWidgets('Hop le thi luu dung gia', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, price: '200000', peak: '300000');
    await submit(tester);
    expect(vm.saved?.pricePerHour, 200000);
    expect(vm.saved?.peakPricePerHour, 300000);
    expect(vm.savedAsEditing, false);
  });

  testWidgets('Bo trong gia cao diem thi lay bang gia thuong', (tester) async {
    await pumpForm(tester);
    await fillRequired(tester, price: '200000');
    await submit(tester);
    expect(vm.saved?.peakPricePerHour, 200000);
  });

  testWidgets('Che do Sua dien san du lieu, co o trang thai va luu dung', (tester) async {
    await pumpForm(
      tester,
      field: FieldModel(
        id: 'f1',
        fieldName: 'Sân Cũ',
        fieldTypeId: 't1',
        ownerId: 'o1',
        address: 'Địa chỉ cũ',
        district: 'Quận 1',
        city: 'TP.HCM',
        pricePerHour: 100000,
        peakPricePerHour: 150000,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    expect(find.text('Cập nhật sân'), findsOneWidget);
    expect(find.text('Sân Cũ'), findsOneWidget);
    expect(find.text('Trạng thái hoạt động'), findsOneWidget);
    await tester.enterText(input('Giá thường /h (VND) *'), '250000');
    await submit(tester);
    expect(vm.savedAsEditing, true);
    expect(vm.saved?.id, 'f1');
    expect(vm.saved?.ownerId, 'o1');
    expect(vm.saved?.pricePerHour, 250000);
    expect(vm.saved?.peakPricePerHour, 150000);
  });
}
