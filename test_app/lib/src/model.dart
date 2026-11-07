import 'package:flutter/widgets.dart';

class Txn {
  const Txn(this.title, this.subtitle, this.amount, this.icon, this.color);

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final int color;
}

class WalletCard {
  const WalletCard(
    this.holder,
    this.last4,
    this.expiry,
    this.balance,
    this.colors,
  );

  final String holder;
  final String last4;
  final String expiry;
  final double balance;
  final List<int> colors;
}

class Category {
  const Category(this.name, this.amount, this.color);

  final String name;
  final double amount;
  final int color;
}

/// Data source. The app ships an empty one; tests inject a fake.
abstract class WalletApi {
  String get userName;
  double get balance;
  List<double> get week;
  List<Txn> get transactions;
  List<WalletCard> get cards;
  List<Category> get spending;
}

class EmptyWalletApi implements WalletApi {
  @override
  String get userName => '';
  @override
  double get balance => 0;
  @override
  List<double> get week => const [0, 0, 0, 0, 0, 0, 0];
  @override
  List<Txn> get transactions => const [];
  @override
  List<WalletCard> get cards => const [];
  @override
  List<Category> get spending => const [];
}

/// App state (Provider + ChangeNotifier).
class WalletModel extends ChangeNotifier {
  WalletModel(this.api);

  final WalletApi api;
  bool hideBalance = false;

  void toggleBalance() {
    hideBalance = !hideBalance;
    notifyListeners();
  }
}
