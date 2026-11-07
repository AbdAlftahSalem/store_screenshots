import 'package:flutter/widgets.dart';

/// Tiny in-app translations (a real app would use gen-l10n).
class S {
  S(this.ar);

  factory S.of(BuildContext context) =>
      S(Localizations.localeOf(context).languageCode == 'ar');

  final bool ar;

  String get goodMorning => ar ? 'صباح الخير،' : 'Good morning,';
  String get search =>
      ar ? 'دوّر على منتج، ماركة…' : 'Search products, brands…';
  String get saleTitle => ar ? 'تخفيضات الصيف' : 'Summer Sale';
  String get saleBody =>
      ar ? 'خصم لحد 40% على السماعات' : 'Up to 40% off audio';
  String get shopNow => ar ? 'تسوق هلأ' : 'Shop now';
  String get popular => ar ? 'الأكثر طلباً' : 'Popular';
  String get seeAll => ar ? 'عرض الكل' : 'See all';
  List<String> get categories => ar
      ? ['الكل', 'صوتيات', 'ساعات', 'أحذية', 'شنط']
      : ['All', 'Audio', 'Wearables', 'Shoes', 'Bags'];
  String get home => ar ? 'الرئيسية' : 'Home';
  String get explore => ar ? 'استكشف' : 'Explore';
  String get cart => ar ? 'السلة' : 'Cart';
  String get profile => ar ? 'حسابي' : 'Profile';
  String get reviews => ar ? 'تقييم' : 'reviews';
  String get color => ar ? 'اللون' : 'Color';
  String get description => ar ? 'الوصف' : 'Description';
  String get addToCart => ar ? 'أضف للسلة' : 'Add to cart';
  String get myCart => ar ? 'سلتي' : 'My Cart';
  String items(int n) => ar ? '$n منتجات' : '$n items';
  String get promo => ar ? 'كود الخصم' : 'Promo code';
  String get apply => ar ? 'تطبيق' : 'Apply';
  String get subtotal => ar ? 'المجموع' : 'Subtotal';
  String get shipping => ar ? 'التوصيل' : 'Shipping';
  String get free => ar ? 'مجاني' : 'Free';
  String get discount => ar ? 'الخصم' : 'Discount';
  String get total => ar ? 'الإجمالي' : 'Total';
  String get checkout => ar ? 'إتمام الشراء' : 'Checkout';
  String get trackOrder => ar ? 'تتبع الطلب' : 'Track order';
  String get arriving => ar ? 'بيوصل خلال' : 'Arriving in';
  String get yourCourier => ar ? 'المندوب' : 'Your courier';
  List<String> get steps => ar
      ? ['تم الطلب', 'تم التجهيز', 'بالطريق إليك', 'تم التوصيل']
      : ['Ordered', 'Packed', 'On the way', 'Delivered'];
  List<String> get stepTimes => ar
      ? ['10:02 ص', '10:40 ص', '11:15 ص', '—']
      : ['10:02 AM', '10:40 AM', '11:15 AM', '—'];
  String get order => ar ? 'طلب رقم' : 'Order';
  String price(double v) =>
      ar ? '${v.toStringAsFixed(2)} \$' : '\$${v.toStringAsFixed(2)}';
}
