/// A product in the shop.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.rating,
    required this.reviews,
    this.oldPrice,
    this.description = '',
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double? oldPrice;
  final String image;
  final double rating;
  final int reviews;
  final String description;
}

/// A line in the cart.
class CartItem {
  const CartItem(this.product, this.quantity, this.variant);

  final Product product;
  final int quantity;
  final String variant;
}

/// The signed-in user.
class User {
  const User(this.name);

  final String name;
}

/// An order on its way.
class Order {
  const Order({required this.number, required this.eta, required this.courier, required this.step});

  final String number;
  final String eta;
  final String courier;

  /// 0 ordered, 1 packed, 2 on the way, 3 delivered.
  final int step;
}
