import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/views/staff/field_pricing_screen.dart';

void main() {
  String? validate({
    String name = 'Gio vang',
    String start = '17',
    String end = '21',
    String multiplier = '1.2',
    String fixed = '',
  }) =>
      validatePricingRule(
        name: name,
        startHour: start,
        endHour: end,
        multiplier: multiplier,
        fixedPrice: fixed,
      );

  test('Du lieu hop le', () {
    expect(validate(), isNull);
    expect(validate(multiplier: '', fixed: '250000'), isNull);
  });

  test('Ten trong', () {
    expect(validate(name: '   '), 'Vui lòng nhập tên quy tắc.');
  });

  test('Gio ngoai 0-23 hoac khong phai so', () {
    expect(validate(end: '25'), 'Giờ phải là số từ 0 đến 23.');
    expect(validate(start: '-1'), 'Giờ phải là số từ 0 đến 23.');
    expect(validate(start: 'abc'), 'Giờ phải là số từ 0 đến 23.');
  });

  test('Gio bat dau phai nho hon gio ket thuc', () {
    expect(validate(start: '21', end: '17'), 'Giờ bắt đầu phải nhỏ hơn giờ kết thúc.');
    expect(validate(start: '17', end: '17'), 'Giờ bắt đầu phải nhỏ hơn giờ kết thúc.');
  });

  test('He so va gia co dinh khong hop le', () {
    expect(validate(multiplier: '0'), 'Hệ số giá phải là số lớn hơn 0.');
    expect(validate(multiplier: 'abc'), 'Hệ số giá phải là số lớn hơn 0.');
    expect(validate(fixed: '-1000'), 'Giá cố định phải là số lớn hơn 0.');
  });
}
