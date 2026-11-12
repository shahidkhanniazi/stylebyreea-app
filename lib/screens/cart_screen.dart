import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../main.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final coupon = TextEditingController();

  @override
  void dispose() { coupon.dispose(); super.dispose(); }

  Future<void> _run(Future<String?> f) async {
    final err = await f;
    if (err != null && mounted) showSnack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cart = s.cart;
    return Scaffold(
      appBar: AppBar(title: Text(cart.count > 0 ? 'Your Bag (${cart.count})' : 'Your Bag')),
      body: RefreshIndicator(
        color: SBR.gold, onRefresh: s.refreshCart,
        child: cart.items.isEmpty
            ? ListView(children: [
                SizedBox(height: MediaQuery.of(context).size.height * .12),
                EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your bag is empty', text: 'Find something you love — new styles land every week.',
                    action: 'Start shopping', onAction: () => MainShell.goTab(context, 1)),
              ])
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                _FreeShip(cart),
                for (final i in cart.items) _CartRow(item: i, onQty: (q) => _run(s.setQty(i, q)), onRemove: () => _run(s.remove(i))),
                const SizedBox(height: 18),
                if (cart.coupons.isEmpty)
                  Row(children: [
                    Expanded(child: TextField(controller: coupon, decoration: const InputDecoration(labelText: 'Coupon code'))),
                    const SizedBox(width: 8),
                    SizedBox(width: 110, child: SbrButton('Apply', style: BtnStyle.outline, onPressed: () {
                      if (coupon.text.trim().isNotEmpty) _run(s.applyCoupon(coupon.text.trim()));
                    })),
                  ])
                else
                  Wrap(spacing: 8, children: [
                    for (final c in cart.coupons)
                      Chip(label: Text(c.toUpperCase()), onDeleted: () => _run(s.removeCoupon(c)), backgroundColor: SBR.ivory),
                  ]),
                const SizedBox(height: 22),
                Container(
                  color: SBR.ivory, padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _line('Subtotal', '${cart.subtotal}'),
                    if (cart.discount.minor > 0) _line('Discount', '−${cart.discount}'),
                    _line('Delivery', cart.needsShipping ? (cart.shippingRates.isEmpty ? 'Calculated at checkout' : '${cart.shipping}') : 'Free'),
                    const Divider(height: 26),
                    _line('Total', '${cart.total}', bold: true),
                  ]),
                ),
                const SizedBox(height: 16),
                SbrButton('Checkout', loading: s.cartBusy, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()))),
                const SizedBox(height: 10),
                SbrButton('Continue shopping', style: BtnStyle.outline, onPressed: () => MainShell.goTab(context, 1)),
              ]),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(a, style: TextStyle(fontSize: bold ? 17 : 14.5, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          const Spacer(),
          Text(b, style: TextStyle(fontSize: bold ? 18 : 14.5, fontWeight: bold ? FontWeight.w600 : FontWeight.w500)),
        ]),
      );
}

class _FreeShip extends StatelessWidget {
  final Cart cart;
  const _FreeShip(this.cart);
  @override
  Widget build(BuildContext context) {
    const goal = 50.0;
    final v = cart.subtotal.value;
    final pct = (v / goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8), padding: const EdgeInsets.all(14), color: SBR.ivory,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v >= goal ? 'You\'ve unlocked free delivery!' : 'Spend ${cart.subtotal.prefix}${(goal - v).toStringAsFixed(2)} more for free delivery',
            style: const TextStyle(fontSize: 13.5)),
        const SizedBox(height: 8),
        ClipRRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
            builder: (_, val, __) => Stack(children: [
              Container(height: 4, color: SBR.line),
              FractionallySizedBox(widthFactor: val, child: Container(height: 4, decoration: const BoxDecoration(gradient: SBR.goldGradient))),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final void Function(int) onQty;
  final VoidCallback onRemove;
  const _CartRow({required this.item, required this.onQty, required this.onRemove});
  @override
  Widget build(BuildContext context) => Reveal(
        dy: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SBR.line))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 84, height: 105, child: Container(color: SBR.ivory, child: NetImage(item.image))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: SBR.serif(18)),
              for (final v in item.variationLabels) Text(v, style: const TextStyle(color: SBR.muted, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${item.unitPrice}', style: const TextStyle(fontSize: 13.5)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  height: 36, decoration: BoxDecoration(border: Border.all(color: SBR.line)),
                  child: Row(children: [
                    InkWell(onTap: () => onQty(item.quantity - 1), child: const SizedBox(width: 34, child: Icon(Icons.remove, size: 16))),
                    SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                    InkWell(onTap: () => onQty(item.quantity + 1), child: const SizedBox(width: 34, child: Icon(Icons.add, size: 16))),
                  ]),
                ),
                const Spacer(),
                Text('${item.linePrice}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ])),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18, color: SBR.muted)),
          ]),
        ),
      );
}
