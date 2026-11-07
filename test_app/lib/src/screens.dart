import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

bool _ar(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';
String _tr(BuildContext c, String en, String ar) => _ar(c) ? ar : en;
String money(BuildContext c, double v, {bool sign = false}) {
  final s = v
      .abs()
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final pre = sign ? (v < 0 ? '-' : '+') : '';
  return _ar(c) ? '\u200E$pre$s \$\u200E' : '$pre\$$s';
}

Color _surface(BuildContext c) => Theme.of(c).colorScheme.surface;
Color _muted(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.55);
TextStyle _t(
  BuildContext c,
  double s, [
  FontWeight w = FontWeight.w500,
  Color? color,
]) => TextStyle(
  fontSize: s,
  fontWeight: w,
  color: color ?? Theme.of(c).colorScheme.onSurface,
  height: 1.2,
);

const _green = Color(0xFF0F9D7A);

class _Shell extends StatelessWidget {
  const _Shell({required this.index, required this.child, this.title});

  final int index;
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null
        ? null
        : AppBar(
            title: Text(title!, style: _t(context, 20, FontWeight.w800)),
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
    body: SafeArea(bottom: false, top: title == null, child: child),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.space_dashboard_rounded),
          label: _tr(context, 'Home', 'الرئيسية'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_rounded),
          label: _tr(context, 'Activity', 'العمليات'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.credit_card_rounded),
          label: _tr(context, 'Cards', 'البطاقات'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.pie_chart_rounded),
          label: _tr(context, 'Insights', 'التحليلات'),
        ),
      ],
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<WalletModel>();
    final api = m.api;
    final wide = MediaQuery.sizeOf(context).width > 700;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _green.withValues(alpha: 0.15),
              child: Text(
                api.userName.isEmpty ? '?' : api.userName.characters.first,
                style: _t(context, 18, FontWeight.w800, _green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr(context, 'Welcome back', 'أهلاً من جديد'),
                    style: _t(context, 13, FontWeight.w400, _muted(context)),
                  ),
                  Text(api.userName, style: _t(context, 19, FontWeight.w800)),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _BalanceCard(balance: api.balance, hidden: m.hideBalance),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Action(
              Icons.arrow_upward_rounded,
              _tr(context, 'Send', 'إرسال'),
              key: const ValueKey('send'),
            ),
            _Action(
              Icons.arrow_downward_rounded,
              _tr(context, 'Request', 'طلب'),
            ),
            _Action(Icons.add_rounded, _tr(context, 'Top up', 'شحن')),
            _Action(Icons.qr_code_scanner_rounded, _tr(context, 'Scan', 'مسح')),
          ],
        ),
      ],
    );
    final chart = _Panel(
      title: _tr(context, 'This week', 'هالأسبوع'),
      trailing: money(context, api.week.fold(0.0, (a, b) => a + b)),
      child: SizedBox(height: 150, child: _BarChart(values: api.week)),
    );
    final recent = _Panel(
      title: _tr(context, 'Recent activity', 'آخر العمليات'),
      trailing: _tr(context, 'See all', 'الكل'),
      child: Column(
        children: [for (final t in api.transactions.take(4)) _TxnTile(t)],
      ),
    );
    return _Shell(
      index: 0,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: wide
            ? [
                header,
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 16),
                    Expanded(child: recent),
                  ],
                ),
              ]
            : [
                header,
                const SizedBox(height: 18),
                chart,
                const SizedBox(height: 14),
                recent,
              ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.hidden});

  final double balance;
  final bool hidden;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F9D7A), Color(0xFF0B6E8F)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _tr(context, 'Total balance', 'الرصيد الكلي'),
              style: _t(context, 14, FontWeight.w500, Colors.white70),
            ),
            const Spacer(),
            const Icon(
              Icons.visibility_outlined,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hidden ? '••••••' : money(context, balance),
          style: _t(context, 36, FontWeight.w800, Colors.white),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _tr(context, '+12.4% this month', '+12.4% هالشهر'),
            style: _t(context, 12, FontWeight.w700, Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: _surface(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: _green, size: 26),
      ),
      const SizedBox(height: 6),
      Text(label, style: _t(context, 13, FontWeight.w600)),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface(context),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: _t(context, 16, FontWeight.w800)),
            ),
            if (trailing != null)
              Text(trailing!, style: _t(context, 13, FontWeight.w700, _green)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _TxnTile extends StatelessWidget {
  const _TxnTile(this.t);

  final Txn t;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Color(t.color).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(t.icon, color: Color(t.color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: _t(context, 15, FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                t.subtitle,
                style: _t(context, 12, FontWeight.w400, _muted(context)),
              ),
            ],
          ),
        ),
        Text(
          money(context, t.amount, sign: true),
          style: _t(context, 15, FontWeight.w800, t.amount > 0 ? _green : null),
        ),
      ],
    ),
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final days = _ar(context)
        ? ['سب', 'أح', 'إث', 'ثل', 'أر', 'خم', 'جم']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxV = values.fold(1.0, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 110 * values[i] / maxV,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: i == 4 ? _green : _green.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[i],
                  style: _t(context, 12, FontWeight.w600, _muted(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<WalletModel>().api;
    final chips = _ar(context)
        ? ['الكل', 'دخل', 'مصاريف', 'تحويلات']
        : ['All', 'Income', 'Spending', 'Transfers'];
    return _Shell(
      index: 1,
      title: _tr(context, 'Activity', 'العمليات'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _surface(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: _muted(context)),
                const SizedBox(width: 8),
                Text(
                  _tr(context, 'Search transactions', 'دوّر بالعمليات'),
                  style: _t(context, 14, FontWeight.w400, _muted(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < chips.length; i++)
                ChoiceChip(
                  label: Text(chips[i]),
                  selected: i == 0,
                  onSelected: (_) {},
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _tr(context, 'Today', 'اليوم'),
            style: _t(context, 13, FontWeight.w700, _muted(context)),
          ),
          for (final t in api.transactions.take(4)) _TxnTile(t),
          const SizedBox(height: 10),
          Text(
            _tr(context, 'Yesterday', 'مبارح'),
            style: _t(context, 13, FontWeight.w700, _muted(context)),
          ),
          for (final t in api.transactions.skip(4)) _TxnTile(t),
        ],
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<WalletModel>().api;
    return _Shell(
      index: 2,
      title: _tr(context, 'My cards', 'بطاقاتي'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          for (final c in api.cards) ...[
            _BankCard(c),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          _Panel(
            title: _tr(context, 'Card settings', 'إعدادات البطاقة'),
            child: Column(
              children: [
                _Switch(
                  Icons.lock_outline_rounded,
                  _tr(context, 'Freeze card', 'تجميد البطاقة'),
                  false,
                ),
                _Switch(
                  Icons.language_rounded,
                  _tr(context, 'Online payments', 'الدفع أونلاين'),
                  true,
                  key: const ValueKey('online'),
                ),
                _Switch(
                  Icons.contactless_rounded,
                  _tr(context, 'Contactless', 'الدفع بدون لمس'),
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch(this.icon, this.label, this.value, {super.key});

  final IconData icon;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: _muted(context)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: _t(context, 15, FontWeight.w600))),
        Switch(value: value, onChanged: (_) {}),
      ],
    ),
  );
}

class _BankCard extends StatelessWidget {
  const _BankCard(this.c);

  final WalletCard c;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.6,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [for (final x in c.colors) Color(x)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9C46A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.contactless_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const Spacer(),
            Text(
              '••••  ••••  ••••  ${c.last4}',
              style: _t(
                context,
                20,
                FontWeight.w700,
                Colors.white,
              ).copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  c.holder,
                  style: _t(context, 14, FontWeight.w600, Colors.white),
                ),
                const Spacer(),
                Text(
                  c.expiry,
                  style: _t(context, 14, FontWeight.w600, Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<WalletModel>().api;
    final total = api.spending.fold(0.0, (a, c) => a + c.amount);
    return _Shell(
      index: 3,
      title: _tr(context, 'Insights', 'التحليلات'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Panel(
            title: _tr(context, 'Spending in October', 'مصاريف أكتوبر'),
            child: SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(210, 210),
                    painter: _Donut(api.spending),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        money(context, total),
                        style: _t(context, 26, FontWeight.w800),
                      ),
                      Text(
                        _tr(context, 'spent', 'مصروف'),
                        style: _t(
                          context,
                          13,
                          FontWeight.w500,
                          _muted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final c in api.spending)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 7, backgroundColor: Color(c.color)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.name,
                      style: _t(context, 15, FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${(c.amount / total * 100).round()}%',
                    style: _t(context, 13, FontWeight.w600, _muted(context)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    money(context, c.amount),
                    style: _t(context, 15, FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Donut extends CustomPainter {
  _Donut(this.parts);

  final List<Category> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final total = parts.fold(0.0, (a, c) => a + c.amount);
    if (total == 0) return;
    var start = -math.pi / 2;
    final rect = Offset.zero & size;
    for (final p in parts) {
      final sweep = p.amount / total * math.pi * 2;
      canvas.drawArc(
        rect.deflate(14),
        start + 0.04,
        sweep - 0.08,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.round
          ..color = Color(p.color),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
