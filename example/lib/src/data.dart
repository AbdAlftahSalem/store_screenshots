import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

/// Where products come from. The real app calls an API; store screenshots
/// swap it for a fake (see test/store_shots_test.dart).
abstract interface class ProductsRepo {
  Future<List<Product>> all();
  Future<List<CartItem>> cart();
  Future<Order> activeOrder();
}

abstract interface class UserRepo {
  Future<User> me();
}

/// The "real" implementation. In this example it has no backend, which is
/// exactly the situation store_shots solves: the screens would be empty.
class ApiProductsRepo implements ProductsRepo {
  @override
  Future<List<Product>> all() async => const [];

  @override
  Future<List<CartItem>> cart() async => const [];

  @override
  Future<Order> activeOrder() => Future.error(StateError('No backend in the example'));
}

class ApiUserRepo implements UserRepo {
  @override
  Future<User> me() async => const User('');
}

final productsRepo = Provider<ProductsRepo>((ref) => ApiProductsRepo());
final userRepo = Provider<UserRepo>((ref) => ApiUserRepo());

final productsProvider = FutureProvider<List<Product>>((ref) => ref.watch(productsRepo).all());
final cartProvider = FutureProvider<List<CartItem>>((ref) => ref.watch(productsRepo).cart());
final orderProvider = FutureProvider<Order>((ref) => ref.watch(productsRepo).activeOrder());
final userProvider = FutureProvider<User>((ref) => ref.watch(userRepo).me());

final productProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final all = await ref.watch(productsProvider.future);
  for (final p in all) {
    if (p.id == id) return p;
  }
  return all.isEmpty ? null : all.first;
});
