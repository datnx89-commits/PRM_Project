import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/data/repositories/wallet_repository.dart';

void main() {
  test('Cong tien co dau cong va kem noi dung', () {
    expect(
      WalletRepository.balanceChangeMessage(
        amount: 200000,
        balanceAfter: 215000,
        description: 'Nạp tiền vào ví',
      ),
      '+200000đ. Số dư: 215000đ. Nạp tiền vào ví',
    );
  });

  test('Tru tien giu dau am', () {
    expect(
      WalletRepository.balanceChangeMessage(
        amount: -50000,
        balanceAfter: 150000,
        description: 'Thanh toán booking',
      ),
      '-50000đ. Số dư: 150000đ. Thanh toán booking',
    );
  });

  test('Khong co noi dung thi bo phan cuoi', () {
    expect(
      WalletRepository.balanceChangeMessage(amount: 1000, balanceAfter: 1000),
      '+1000đ. Số dư: 1000đ.',
    );
  });
}
