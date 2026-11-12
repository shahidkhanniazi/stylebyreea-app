import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'order_success_screen.dart';
import 'webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  late final Address a = AppScope.read(context).address;
  late final Map<String, TextEditingController> c = {
    'first': TextEditingController(text: a.firstName), 'last': TextEditingController(text: a.lastName),
    'email': TextEditingController(text: a.email), 'phone': TextEditingController(text: a.phone),
    'addr1': TextEditingController(text: a.address1), 'addr2': TextEditingController(text: a.address2),
    'city': TextEditingController(text: a.city), 'postcode': TextEditingController(text: a.postcode),
    'note': TextEditingController(),
  };
  late String country = a.country.isEmpty ? 'GB' : a.country;
  String? payment;
  bool placing = false, addressSent = false;

  static const countries = {
    'GB': 'United Kingdom', 'IE': 'Ireland', 'PK': 'Pakistan', 'AE': 'United Arab Emirates', 'SA': 'Saudi Arabia',
    'US': 'United States', 'CA': 'Canada', 'FR': 'France', 'DE': 'Germany', 'ES': 'Spain', 'IT': 'Italy', 'NL': 'Netherlands',
  };

  @override
  void dispose() { for (final x in c.values) { x.dispose(); } super.dispose(); }

  Address _address() => Address(
        firstName: c['first']!.text.trim(), lastName: c['last']!.text.trim(), email: c['email']!.text.trim(),
        phone: c['phone']!.text.trim(), address1: c['addr1']!.text.trim(), address2: c['addr2']!.text.trim(),
        city: c['city']!.text.trim(), postcode: c['postcode']!.text.trim(), country: country,
      );

  Future<void> _updateShipping() async {
    if (c['postcode']!.text.trim().isEmpty) return;
    final s = AppScope.read(context);
    final err = await s.updateCustomer(_address());
    if (mounted) setState(() => addressSent = err == null);
  }

  Future<void> _place() async {
    final s = AppScope.read(context);
    if (!form.currentState!.validate()) {
      showSnack(context, 'Please complete the highlighted fields.');
      return;
    }
    final methods = s.cart.paymentMethods;
    final pm = payment ?? (methods.isNotEmpty ? methods.first : null);
    if (pm == null) {
      showSnack(context, 'No payment method is enabled on the store yet.');
      return;
    }
    setState(() => placing = true);
    final addr = _address();
    await s.saveAddress(addr);
    final total = '${s.cart.total}';
    final count = s.cart.count;
    try {
      await s.api.updateCustomer(addr);
      final r = await s.api.checkout(billing: addr, paymentMethod: pm, note: c['note']!.text.trim());
      await s.addOrder(SavedOrder(r.orderId, r.orderKey, addr.email, total, DateTime.now(), count, r.status));
      await s.afterOrderPlaced();
      if (!mounted) return;
      if (r.redirectUrl != null && !['cod', 'bacs', 'cheque'].contains(pm)) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WebViewScreen(url: r.redirectUrl!, title: 'Secure payment', closeOnOrderReceived: true)));
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: r.orderId, total: total, payment: pm)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not place the order. Please check your connection and try again.');
    }
    if (mounted) setState(() => placing = false);
  }

  InputDecoration _dec(String l) => InputDecoration(labelText: l);
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cart = s.cart;
    final methods = cart.paymentMethods;
    payment ??= methods.isNotEmpty ? methods.first : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
          _step('1', 'Contact'),
          TextFormField(controller: c['email'], decoration: _dec('Email address'), keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Enter a valid email' : null),
          const SizedBox(height: 12),
          TextFormField(controller: c['phone'], decoration: _dec('Phone'), keyboardType: TextInputType.phone, validator: _req),
          const SizedBox(height: 26),
          _step('2', 'Delivery address'),
          Row(children: [
            Expanded(child: TextFormField(controller: c['first'], decoration: _dec('First name'), validator: _req, textCapitalization: TextCapitalization.words)),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: c['last'], decoration: _dec('Last name'), validator: _req, textCapitalization: TextCapitalization.words)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: countries.containsKey(country) ? country : 'GB', decoration: _dec('Country'),
            items: [for (final e in countries.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) { setState(() => country = v ?? 'GB'); _updateShipping(); },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: c['addr1'], decoration: _dec('Street address'), validator: _req),
          const SizedBox(height: 12),
          TextFormField(controller: c['addr2'], decoration: _dec('Apartment, suite (optional)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: c['city'], decoration: _dec('Town / City'), validator: _req)),
            const SizedBox(width: 10),
            Expanded(child: Focus(
              onFocusChange: (f) { if (!f) _updateShipping(); },
              child: TextFormField(controller: c['postcode'], decoration: _dec('Postcode'), validator: _req, textCapitalization: TextCapitalization.characters),
            )),
          ]),
          if (cart.needsShipping) ...[
            const SizedBox(height: 26),
            _step('3', 'Delivery method'),
            if (cart.shippingRates.isEmpty)
              Text(addressSent ? 'No delivery options for this address.' : 'Enter your postcode to see delivery options.', style: const TextStyle(color: SBR.muted))
            else
              for (final r in cart.shippingRates)
                _option(r.selected, r.name, r.price.minor == 0 ? 'Free' : '${r.price}', () async {
                  final err = await s.selectShipping(r);
                  if (err != null && context.mounted) showSnack(context, err);
                }),
          ],
          const SizedBox(height: 26),
          _step(cart.needsShipping ? '4' : '3', 'Payment'),
          if (methods.isEmpty)
            const Text('No payment methods are enabled on the store.', style: TextStyle(color: Colors.red))
          else
            for (final m in methods) _option(payment == m, paymentLabel(m), '', () => setState(() => payment = m)),
          const SizedBox(height: 12),
          TextFormField(controller: c['note'], decoration: _dec('Order notes (optional)'), maxLines: 2),
          const SizedBox(height: 24),
          Container(
            color: SBR.ivory, padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order summary', style: SBR.serif(22)),
              const SizedBox(height: 10),
              for (final i in cart.items)
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                  Expanded(child: Text('${i.name}${i.variationLabels.isNotEmpty ? ' (${i.variationLabels.join(', ')})' : ''} × ${i.quantity}',
                      style: const TextStyle(fontSize: 13.5))),
                  Text('${i.linePrice}'),
                ])),
              const Divider(height: 24),
              _sum('Subtotal', '${cart.subtotal}'),
              if (cart.discount.minor > 0) _sum('Discount', '−${cart.discount}'),
              if (cart.needsShipping) _sum('Delivery', '${cart.shipping}'),
              const SizedBox(height: 6),
              _sum('Total', '${cart.total}', bold: true),
            ]),
          ),
          const SizedBox(height: 18),
          SbrButton('Place order · ${cart.total}', loading: placing, icon: Icons.lock_outline, onPressed: cart.items.isEmpty ? null : _place),
          const SizedBox(height: 10),
          const Text('By placing your order you agree to our Terms & Conditions and Privacy Policy.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: SBR.muted)),
        ]),
      ),
    );
  }

  Widget _step(String n, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: const BoxDecoration(color: SBR.ink, shape: BoxShape.circle),
              child: Text(n, style: const TextStyle(color: SBR.gold2, fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Text(t, style: SBR.serif(22)),
        ]),
      );

  Widget _option(bool sel, String title, String trailing, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(border: Border.all(color: sel ? SBR.ink : SBR.line, width: sel ? 1.5 : 1), color: sel ? SBR.ivory : Colors.white),
            child: Row(children: [
              Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off, color: sel ? SBR.ink : SBR.muted, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
              if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _sum(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400, fontSize: bold ? 16 : 14)),
          const Spacer(),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w500, fontSize: bold ? 17 : 14)),
        ]),
      );
}
