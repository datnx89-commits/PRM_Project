import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/core/config/app_config.dart';
import 'package:sportsbook_36vn/views/customer/wallet_screen.dart';

void main() {
  test('Xep hang dung theo moc diem tron doi', () {
    expect(AppConfig.getMembershipTier(0).name, 'Đồng');
    expect(AppConfig.getMembershipTier(499).name, 'Đồng');
    expect(AppConfig.getMembershipTier(500).name, 'Bạc');
    expect(AppConfig.getMembershipTier(1999).name, 'Bạc');
    expect(AppConfig.getMembershipTier(2000).name, 'Vàng');
    expect(AppConfig.getMembershipTier(5000).name, 'Kim cương');
  });

  test('Hang ke tiep la hang ngay tren hang hien tai', () {
    expect(AppConfig.getNextMembershipTier(0)?.name, 'Bạc');
    expect(AppConfig.getNextMembershipTier(500)?.name, 'Vàng');
    expect(AppConfig.getNextMembershipTier(4999)?.name, 'Kim cương');
  });

  test('Hang cao nhat khong con hang ke tiep', () {
    expect(AppConfig.getNextMembershipTier(5000), isNull);
    expect(AppConfig.getNextMembershipTier(9000), isNull);
  });

  Future<void> pumpTable(WidgetTester tester, int points) async {
    tester.view.physicalSize = const Size(256, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MembershipTierTable(lifetimePoints: points)),
        ),
      ),
    );
  }

  testWidgets('Bang hang hien du 4 hang va so diem con thieu', (tester) async {
    await pumpTable(tester, 300);

    for (final name in ['Đồng', 'Bạc', 'Vàng', 'Kim cương']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Từ 500 điểm • Giảm 3%'), findsOneWidget);
    expect(find.text('Còn 200 điểm để lên hạng Bạc'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Hang cao nhat thi bao da o hang cao nhat', (tester) async {
    await pumpTable(tester, 5000);

    expect(find.text('Bạn đang ở hạng cao nhất'), findsOneWidget);
  });
}
