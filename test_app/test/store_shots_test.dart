import 'package:flutter/material.dart';
import 'package:store_shots/store_shots.dart';
import 'package:wallet_test_app/main.dart';
import 'package:wallet_test_app/src/model.dart';

/// Provider-based app: the "override" is simply the fake API object.
void main() => storeShots<WalletApi>(
  config: 'store_shots.yaml',
  overrides: (locale) => [FakeWalletApi(locale)],
  app: (apis) => WalletApp(api: apis.single),
);

class FakeWalletApi implements WalletApi {
  FakeWalletApi(this.locale);

  final String locale;
  bool get ar => locale == 'ar';
  String t(String en, String a) => ar ? a : en;

  @override
  String get userName => t('Lina Haddad', 'لينا حداد');

  @override
  double get balance => 12480.75;

  @override
  List<double> get week => const [42, 88, 35, 120, 160, 74, 52];

  @override
  List<Txn> get transactions => [
    Txn(t('Salary', 'الراتب'), t('Acme Corp · 09:00', 'شركة أكمي · 09:00'), 4200, Icons.work_rounded, 0xFF0F9D7A),
    Txn(t('Groceries', 'سوبرماركت'), t('Fresh Market · 12:40', 'السوق الطازج · 12:40'), -86.30, Icons.shopping_basket_rounded, 0xFFF59E0B),
    Txn(t('Coffee', 'قهوة'), t('Bean There · 08:15', 'كوفي بين · 08:15'), -4.50, Icons.local_cafe_rounded, 0xFF8B5E3C),
    Txn(t('Transfer to Omar', 'تحويل لعمر'), t('Split dinner · 21:05', 'عشا مشترك · 21:05'), -35, Icons.swap_horiz_rounded, 0xFF6366F1),
    Txn(t('Gym membership', 'اشتراك النادي'), t('Monthly · 07:30', 'شهري · 07:30'), -29.99, Icons.fitness_center_rounded, 0xFFEF4444),
    Txn(t('Refund', 'استرجاع'), t('Online store · 16:20', 'متجر إلكتروني · 16:20'), 54.20, Icons.replay_rounded, 0xFF0EA5E9),
    Txn(t('Electricity', 'الكهرباء'), t('Utility bill · 10:10', 'فاتورة · 10:10'), -61.75, Icons.bolt_rounded, 0xFFEAB308),
  ];

  @override
  List<WalletCard> get cards => const [
    WalletCard('LINA HADDAD', '4821', '09/29', 8240.10, [0xFF111827, 0xFF374151]),
    WalletCard('LINA HADDAD', '7310', '03/28', 4240.65, [0xFF0F9D7A, 0xFF0B6E8F]),
  ];

  @override
  List<Category> get spending => [
    Category(t('Food & drinks', 'أكل وشرب'), 420, 0xFFF59E0B),
    Category(t('Shopping', 'تسوق'), 310, 0xFF6366F1),
    Category(t('Transport', 'مواصلات'), 145, 0xFF0EA5E9),
    Category(t('Bills', 'فواتير'), 220, 0xFFEF4444),
  ];
}
