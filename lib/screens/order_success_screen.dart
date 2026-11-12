import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../main.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int orderId;
  final String total;
  final String payment;
  const OrderSuccessScreen({super.key, required this.orderId, required this.total, required this.payment});
  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  @override
  void dispose() { c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Order placed')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: c, curve: Curves.elasticOut),
                child: Container(width: 110, height: 110, decoration: const BoxDecoration(gradient: SBR.goldGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 60, color: SBR.ink)),
              ),
              const SizedBox(height: 28),
              Reveal(delayMs: 300, child: Text('Thank you!', style: SBR.serif(40))),
              const SizedBox(height: 10),
              Reveal(delayMs: 420, child: Text('Your order #${widget.orderId} has been received.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
              const SizedBox(height: 24),
              Reveal(
                delayMs: 540,
                child: Container(
                  color: SBR.ivory, padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    _row('Order number', '#${widget.orderId}'),
                    _row('Total', widget.total),
                    _row('Payment', paymentLabel(widget.payment)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const Text('A confirmation email is on its way. You can follow your order in Account → My orders.',
                  textAlign: TextAlign.center, style: TextStyle(color: SBR.muted)),
              const SizedBox(height: 28),
              SbrButton('Continue shopping', onPressed: () {
                MainShell.goTab(context, 0);
                Navigator.of(context).popUntil((r) => r.isFirst);
              }),
              const SizedBox(height: 10),
              SbrButton('View my orders', style: BtnStyle.outline, onPressed: () {
                MainShell.goTab(context, 4);
                Navigator.of(context).popUntil((r) => r.isFirst);
              }),
            ]),
          ),
        ),
      );

  Widget _row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Text(a, style: const TextStyle(color: SBR.muted)), const Spacer(), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );
}
