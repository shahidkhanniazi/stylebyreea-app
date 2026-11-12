import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'webview_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool refreshing = false;

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await AppScope.read(context).refreshOrders();
    if (mounted) setState(() => refreshing = false);
  }

  void _page(String title, String path) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebViewScreen(url: '${AppConfig.siteUrl}$path', title: title)));

  Future<void> _open(Uri u) async {
    if (!await launchUrl(u, mode: LaunchMode.externalApplication) && mounted) showSnack(context, 'Could not open link.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.address;
    final name = '${a.firstName} ${a.lastName}'.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        color: SBR.gold, onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          Container(
            color: SBR.ink, padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
            child: Row(children: [
              Container(width: 58, height: 58, alignment: Alignment.center, decoration: const BoxDecoration(gradient: SBR.goldGradient, shape: BoxShape.circle),
                  child: Text(name.isEmpty ? 'SBR' : name[0].toUpperCase(), style: SBR.serif(name.isEmpty ? 17 : 26))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.isEmpty ? 'Welcome' : 'Hello, ${a.firstName}', style: SBR.serif(26, c: Colors.white)),
                Text(a.email.isEmpty ? 'Your details are saved after your first order.' : a.email, style: const TextStyle(color: Color(0xFFCFC9BD), fontSize: 13)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 12, 8),
            child: Row(children: [
              Text('MY ORDERS', style: SBR.eyebrow()),
              const Spacer(),
              if (s.orders.isNotEmpty)
                refreshing
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: SBR.gold)))
                    : TextButton(onPressed: _refresh, child: const Text('Refresh status', style: TextStyle(color: SBR.muted))),
            ]),
          ),
          if (s.orders.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text('No orders yet.', style: TextStyle(color: SBR.muted)))
          else
            for (final o in s.orders) _OrderTile(o),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 4), child: Text('HELP & INFO', style: SBR.eyebrow())),
          _tile(Icons.local_shipping_outlined, 'Track an order', () => _page('Track Order', '/track-order/')),
          _tile(Icons.straighten, 'Size guide', () => _page('Size Guide', '/size-guide/')),
          _tile(Icons.replay_rounded, 'Shipping & returns', () => _page('Shipping & Returns', '/shipping-returns/')),
          _tile(Icons.help_outline, 'FAQ', () => _page('FAQ', '/faq/')),
          _tile(Icons.info_outline, 'About us', () => _page('About Us', '/about-us/')),
          _tile(Icons.mail_outline, 'Email us', () => _open(Uri.parse('mailto:${AppConfig.email}'))),
          if (AppConfig.whatsapp.isNotEmpty)
            _tile(Icons.chat_outlined, 'Chat on WhatsApp', () => _open(Uri.parse('https://wa.me/${AppConfig.whatsapp}'))),
          _tile(Icons.language, 'Visit website', () => _open(Uri.parse(AppConfig.siteUrl))),
          _tile(Icons.description_outlined, 'Terms & conditions', () => _page('Terms & Conditions', '/terms-conditions/')),
          _tile(Icons.privacy_tip_outlined, 'Privacy policy', () => _page('Privacy Policy', '/privacy-policy/')),
          const SizedBox(height: 24),
          Center(child: Image.asset('assets/logo.png', width: 120)),
          const SizedBox(height: 6),
          const Center(child: Text('Version 1.0.0', style: TextStyle(color: SBR.muted, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _tile(IconData i, String t, VoidCallback onTap) => ListTile(
        leading: Icon(i, color: SBR.gold), title: Text(t), trailing: const Icon(Icons.chevron_right, color: SBR.muted), onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      );
}

class _OrderTile extends StatelessWidget {
  final SavedOrder o;
  const _OrderTile(this.o);
  @override
  Widget build(BuildContext context) {
    final st = o.status.replaceAll('-', ' ');
    final itemsLabel = o.items == 1 ? '1 item' : '${o.items} items';
    final dateLabel = '${o.date.day}/${o.date.month}/${o.date.year}';
    final color = switch (o.status) {
      'completed' => const Color(0xFF2E6B30),
      'processing' => SBR.gold,
      'cancelled' || 'failed' || 'refunded' => const Color(0xFFB42323),
      _ => SBR.muted,
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: SBR.line)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order #${o.id}', style: SBR.serif(20)),
          Text('$dateLabel · $itemsLabel', style: const TextStyle(color: SBR.muted, fontSize: 13)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(o.total, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(4)),
            child: Text(st.isEmpty ? 'placed' : st, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }
}
