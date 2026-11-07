import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:store_screenshots/store_screenshots.dart';
import 'package:store_shots_example/main.dart';
import 'package:store_shots_example/src/data.dart';
import 'package:store_shots_example/src/models.dart';

void main() => storeShots<Override>(
  // Fake, locale-aware data instead of the real API.
  overrides: (locale) => [
    productsRepo.overrideWithValue(FakeProductsRepo(locale)),
    userRepo.overrideWithValue(FakeUserRepo(locale == 'ar' ? 'أحمد' : 'Sarah')),
  ],
  app: (overrides) =>
      ProviderScope(overrides: overrides, child: const ShopApp()),
);

class FakeUserRepo implements UserRepo {
  FakeUserRepo(this.name);

  final String name;

  @override
  Future<User> me() async => User(name);
}

class FakeProductsRepo implements ProductsRepo {
  FakeProductsRepo(this.locale);

  final String locale;

  bool get ar => locale == 'ar';

  Product _p(
    String id,
    String en,
    String arName,
    double price,
    double rating,
    int reviews, {
    double? old,
    String descEn = '',
    String descAr = '',
  }) => Product(
    id: id,
    name: ar ? arName : en,
    category: '',
    price: price,
    oldPrice: old,
    image: 'assets/products/$id.jpg',
    rating: rating,
    reviews: reviews,
    description: ar ? descAr : descEn,
  );

  @override
  Future<List<Product>> all() async => [
    _p(
      'headphones',
      'Wireless Headphones',
      'سماعة لاسلكية',
      89.00,
      4.8,
      2140,
      old: 129.00,
      descEn:
          'Soft memory-foam cushions, 40-hour battery and active noise cancelling that lets the music do the talking.',
      descAr:
          'وسائد ناعمة، بطارية بتدوم 40 ساعة، وعزل للضوضاء بخليك تسمع الموسيقى وبس.',
    ),
    _p('watch', 'Smart Watch S2', 'ساعة ذكية S2', 129.00, 4.7, 980),
    _p('sneakers', 'Air Runner', 'حذاء رياضي', 74.50, 4.6, 1320),
    _p('backpack', 'Canvas Backpack', 'شنطة ظهر', 58.00, 4.9, 640),
    _p('sunglasses', 'Tortoise Shades', 'نظارة شمسية', 39.99, 4.5, 410),
    _p('camera', 'Retro Camera', 'كاميرا كلاسيك', 349.00, 4.9, 275),
    _p('speaker', 'Pebble Speaker', 'سماعة بلوتوث', 45.00, 4.4, 860),
    _p('perfume', 'Amber Noir', 'عطر عنبر', 64.00, 4.8, 530),
  ];

  @override
  Future<List<CartItem>> cart() async {
    final p = await all();
    return [
      CartItem(p[0], 1, ar ? 'بيج رملي' : 'Sand beige'),
      CartItem(p[1], 1, ar ? 'أسود · 44 ملم' : 'Black · 44 mm'),
      CartItem(p[2], 2, ar ? 'مقاس 42' : 'Size 42'),
    ];
  }

  @override
  Future<Order> activeOrder() async => Order(
    number: '48213',
    eta: ar ? '25 دقيقة' : '25 min',
    courier: ar ? 'محمد' : 'Daniel',
    step: 2,
  );
}
