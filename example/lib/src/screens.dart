import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data.dart';
import 'models.dart';
import 'strings.dart';

TextStyle _t(BuildContext c, double size, [FontWeight w = FontWeight.w400, Color? color]) =>
    TextStyle(fontSize: size, fontWeight: w, color: color ?? Theme.of(c).colorScheme.onSurface, height: 1.25);

Color _muted(BuildContext c) => Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.55);
bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _card(BuildContext c) => _dark(c) ? const Color(0xFF17171F) : Colors.white;
Color _tile(BuildContext c) => _dark(c) ? const Color(0xFF20202A) : const Color(0xFFF1F1F4);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final products = ref.watch(productsProvider).value ?? const [];
    final user = ref.watch(userProvider).value;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withValues(alpha: 0.14),
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name.characters.first : '?',
                    style: _t(context, 20, FontWeight.w700, primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.goodMorning, style: _t(context, 13, FontWeight.w400, _muted(context))),
                      Text(user?.name ?? '', style: _t(context, 19, FontWeight.w700)),
                    ],
                  ),
                ),
                _RoundIcon(icon: Icons.notifications_none_rounded, badge: true),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: _muted(context)),
                        const SizedBox(width: 10),
                        Text(s.search, style: _t(context, 14, FontWeight.w400, _muted(context))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PromoBanner(product: products.isEmpty ? null : products.first),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final selected = i == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? primary : _card(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.categories[i],
                      style: _t(c, 14, FontWeight.w600, selected ? Colors.white : null),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text(s.popular, style: _t(context, 18, FontWeight.w700))),
                Text(s.seeAll, style: _t(context, 13, FontWeight.w600, primary)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(products.length, 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (c, i) => _ProductCard(product: products[i]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        height: 68,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: s.home),
          NavigationDestination(icon: const Icon(Icons.explore_outlined), label: s.explore),
          NavigationDestination(
            icon: const Badge(label: Text('3'), child: Icon(Icons.shopping_bag_outlined)),
            label: s.cart,
          ),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), label: s.profile),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.badge = false});

  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
        if (badge)
          const PositionedDirectional(
            top: 11,
            end: 12,
            child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF4D67)),
          ),
      ],
    ),
  );
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.product});

  final Product? product;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF5B4CF0), Color(0xFF9A5CF5)]),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -30,
            top: -30,
            child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withValues(alpha: 0.08)),
          ),
          if (product != null)
            PositionedDirectional(
              end: 8,
              top: 10,
              bottom: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(product!.image, width: 130, height: 130, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 150, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.saleTitle, style: _t(context, 20, FontWeight.w800, Colors.white)),
                const SizedBox(height: 4),
                Text(s.saleBody, style: _t(context, 13, FontWeight.w400, Colors.white.withValues(alpha: 0.85))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(s.shopNow, style: _t(context, 13, FontWeight.w700, const Color(0xFF5B4CF0))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(product.image, fit: BoxFit.cover),
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(context, 14, FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB020)),
              const SizedBox(width: 2),
              Text('${product.rating}', style: _t(context, 12, FontWeight.w500, _muted(context))),
              const Spacer(),
              Text(s.price(product.price), style: _t(context, 14, FontWeight.w800, primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final p = ref.watch(productProvider(id)).value;
    final primary = Theme.of(context).colorScheme.primary;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              AspectRatio(aspectRatio: 0.95, child: Image.asset(p.image, fit: BoxFit.cover)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _RoundIcon(icon: Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded),
                      const Spacer(),
                      const _RoundIcon(icon: Icons.favorite_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: _t(context, 24, FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(Icons.star_rounded, size: 18, color: i < p.rating.round() ? const Color(0xFFFFB020) : Colors.grey),
                      const SizedBox(width: 6),
                      Text('${p.rating} · ${p.reviews} ${s.reviews}', style: _t(context, 13, FontWeight.w500, _muted(context))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(s.price(p.price), style: _t(context, 28, FontWeight.w800, primary)),
                      const SizedBox(width: 10),
                      if (p.oldPrice != null)
                        Text(
                          s.price(p.oldPrice!),
                          style: _t(context, 16, FontWeight.w500, _muted(context)).copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(s.color, style: _t(context, 15, FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final (i, c) in const [
                        Color(0xFFD8C7AE),
                        Color(0xFF2B2B33),
                        Color(0xFF8FA7C8),
                        Color(0xFFE8A0A8),
                      ].indexed)
                        Container(
                          margin: const EdgeInsetsDirectional.only(end: 12),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: i == 0 ? primary : Colors.transparent, width: 2),
                          ),
                          child: CircleAvatar(radius: 14, backgroundColor: c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(s.description, style: _t(context, 15, FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(p.description, style: _t(context, 14, FontWeight.w400, _muted(context)).copyWith(height: 1.55)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const IconButton(onPressed: null, icon: Icon(Icons.remove_rounded)),
                    Text('1', style: _t(context, 17, FontWeight.w700)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('add_to_cart'),
                    onPressed: () {},
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    icon: const Icon(Icons.shopping_bag_rounded),
                    label: Text(s.addToCart, style: _t(context, 16, FontWeight.w700, Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final items = ref.watch(cartProvider).value ?? const [];
    final primary = Theme.of(context).colorScheme.primary;
    final subtotal = items.fold<double>(0, (a, i) => a + i.product.price * i.quantity);
    const discount = 10.0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          children: [
            Text(s.myCart, style: _t(context, 18, FontWeight.w700)),
            Text(s.items(items.length), style: _t(context, 12, FontWeight.w400, _muted(context))),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(item.product.image, width: 78, height: 78, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: _t(context, 15, FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(item.variant, style: _t(context, 12, FontWeight.w400, _muted(context))),
                        const SizedBox(height: 6),
                        Text(s.price(item.product.price), style: _t(context, 15, FontWeight.w800, primary)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: _tile(context), borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_rounded, size: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item.quantity}', style: _t(context, 14, FontWeight.w700)),
                        ),
                        const Icon(Icons.add_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Container(
            height: 56,
            padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: _muted(context), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('SUMMER10', style: _t(context, 14, FontWeight.w600))),
                FilledButton.tonal(onPressed: () {}, child: Text(s.apply)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _row(context, s.subtotal, s.price(subtotal)),
                _row(context, s.shipping, s.free, color: const Color(0xFF16A34A)),
                _row(context, s.discount, '-${s.price(discount)}'),
                const Divider(height: 22),
                _row(context, s.total, s.price(subtotal - discount), big: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 58,
            child: FilledButton(
              key: const ValueKey('checkout'),
              onPressed: () {},
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.checkout, style: _t(context, 17, FontWeight.w700, Colors.white)),
                  const SizedBox(width: 10),
                  Text('·  ${s.price(subtotal - discount)}', style: _t(context, 17, FontWeight.w500, Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext c, String a, String b, {bool big = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(a, style: _t(c, big ? 17 : 14, big ? FontWeight.w700 : FontWeight.w400, big ? null : _muted(c)))),
        Text(b, style: _t(c, big ? 20 : 14, big ? FontWeight.w800 : FontWeight.w600, color)),
      ],
    ),
  );
}

class TrackOrderScreen extends ConsumerWidget {
  const TrackOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final order = ref.watch(orderProvider).value;
    final primary = Theme.of(context).colorScheme.primary;
    if (order == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(s.trackOrder, style: _t(context, 18, FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(height: 250, child: CustomPaint(painter: _MapPainter(primary, _dark(context)))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.order} #${order.number}', style: _t(context, 13, FontWeight.w500, _muted(context))),
                          const SizedBox(height: 2),
                          Text('${s.arriving} ${order.eta}', style: _t(context, 19, FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.local_shipping_rounded, color: primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < 4; i++) _Step(label: s.steps[i], time: s.stepTimes[i], done: i <= order.step, current: i == order.step, last: i == 3),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFE2C7),
                  child: Text(order.courier.characters.first, style: _t(context, 18, FontWeight.w700, const Color(0xFF9A4A00))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.yourCourier, style: _t(context, 12, FontWeight.w400, _muted(context))),
                      Text(order.courier, style: _t(context, 16, FontWeight.w700)),
                    ],
                  ),
                ),
                _RoundIcon(icon: Icons.chat_bubble_outline_rounded),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  child: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.time, required this.done, required this.current, required this.last});

  final String label;
  final String time;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? primary : Colors.transparent,
                  border: Border.all(color: done ? primary : Colors.grey.shade400, width: 2),
                  boxShadow: current ? [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 3)] : null,
                ),
                child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: done ? primary : Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(label, style: _t(context, 15, current ? FontWeight.w800 : FontWeight.w500, done ? null : _muted(context))),
            ),
          ),
          Text(time, style: _t(context, 12, FontWeight.w500, _muted(context))),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.accent, this.dark);

  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = dark ? const Color(0xFF1B1D26) : const Color(0xFFE9EEF3));
    final park = Paint()..color = dark ? const Color(0xFF1F3327) : const Color(0xFFCFE8D5);
    canvas.drawRRect(RRect.fromLTRBR(w * 0.62, h * 0.08, w * 0.95, h * 0.42, const Radius.circular(18)), park);
    canvas.drawRRect(RRect.fromLTRBR(w * 0.05, h * 0.62, w * 0.3, h * 0.95, const Radius.circular(18)), park);
    final water = Paint()..color = dark ? const Color(0xFF1C2A3F) : const Color(0xFFCBE1F7);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.25)
        ..quadraticBezierTo(w * 0.2, h * 0.18, w * 0.35, 0)
        ..lineTo(0, 0)
        ..close(),
      water,
    );
    final road = Paint()
      ..color = dark ? const Color(0xFF2C2F3B) : Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    for (final y in [0.3, 0.55, 0.82]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * (y + 0.04)), road);
    }
    for (final x in [0.18, 0.45, 0.72]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * (x + 0.05), h), road);
    }
    final route = Path()
      ..moveTo(w * 0.2, h * 0.86)
      ..lineTo(w * 0.47, h * 0.58)
      ..lineTo(w * 0.73, h * 0.6)
      ..lineTo(w * 0.76, h * 0.28);
    canvas.drawPath(route, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent);
    canvas.drawCircle(Offset(w * 0.2, h * 0.86), 9, Paint()..color = accent);
    canvas.drawCircle(Offset(w * 0.2, h * 0.86), 4, Paint()..color = Colors.white);
    final pin = Offset(w * 0.76, h * 0.28);
    canvas.drawCircle(pin, 22, Paint()..color = accent.withValues(alpha: 0.2));
    canvas.drawCircle(pin, 12, Paint()..color = const Color(0xFFFF4D67));
    canvas.drawCircle(pin, 5, Paint()..color = Colors.white);
    final truck = Offset(w * 0.6, h * 0.59);
    canvas.drawCircle(truck, 16, Paint()..color = Colors.white);
    canvas.drawCircle(truck, 12, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
