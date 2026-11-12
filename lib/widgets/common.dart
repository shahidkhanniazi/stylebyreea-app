import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../screens/product_screen.dart';

void showSnack(BuildContext context, String msg, {String? action, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
      action: action != null ? SnackBarAction(label: action, onPressed: onAction ?? () {}) : null,
    ));
}

/// Network image with a soft ivory placeholder and fade-in.
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width, height;
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Container(color: SBR.ivory, width: width, height: height);
    return Image.network(
      url, fit: fit, width: width, height: height,
      frameBuilder: (c, child, frame, sync) => sync ? child : AnimatedOpacity(
        opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 450), curve: Curves.easeOut, child: child),
      loadingBuilder: (c, child, prog) => prog == null ? child : Container(color: SBR.ivory, width: width, height: height),
      errorBuilder: (c, e, s) => Container(color: SBR.ivory, width: width, height: height,
          child: const Icon(Icons.image_not_supported_outlined, color: SBR.muted)),
    );
  }
}

enum BtnStyle { dark, gold, outline }

class SbrButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BtnStyle style;
  final bool loading;
  final IconData? icon;
  final bool expand;
  const SbrButton(this.label, {super.key, this.onPressed, this.style = BtnStyle.dark, this.loading = false, this.icon, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final fg = style == BtnStyle.outline ? SBR.ink : (style == BtnStyle.gold ? SBR.ink : Colors.white);
    final disabled = onPressed == null || loading;
    final child = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 10)],
            Text(label.toUpperCase(), style: TextStyle(color: fg, fontSize: 12.5, letterSpacing: 2.4, fontWeight: FontWeight.w500)),
          ]);
    return Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 54,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: style == BtnStyle.dark ? SBR.ink : (style == BtnStyle.outline ? Colors.transparent : null),
            gradient: style == BtnStyle.gold ? SBR.goldGradient : null,
            border: style == BtnStyle.outline ? Border.all(color: SBR.ink) : null,
          ),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            splashColor: const Color(0x40B8913A),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 26), child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

class PriceText extends StatelessWidget {
  final Product p;
  final double size;
  const PriceText(this.p, {super.key, this.size = 15});
  @override
  Widget build(BuildContext context) {
    final sale = p.onSale && p.regularPrice.minor > p.price.minor;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (sale) ...[
        Text('${p.regularPrice}', style: TextStyle(fontSize: size * .9, color: SBR.muted, decoration: TextDecoration.lineThrough)),
        const SizedBox(width: 8),
      ],
      Text('${p.price}', style: TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: sale ? SBR.gold : SBR.ink)),
    ]);
  }
}

class SectionHeader extends StatelessWidget {
  final String eyebrow, title;
  final VoidCallback? onMore;
  const SectionHeader(this.eyebrow, this.title, {super.key, this.onMore});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow.toUpperCase(), style: SBR.eyebrow()),
            const SizedBox(height: 6),
            Text(title, style: SBR.serif(30)),
          ])),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Container(
                padding: const EdgeInsets.only(bottom: 3),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SBR.ink))),
                child: const Text('VIEW ALL', style: TextStyle(fontSize: 11.5, letterSpacing: 2, fontWeight: FontWeight.w500)),
              ),
            ),
        ]),
      );
}

/// Fades & slides its child in once, optionally after a delay.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double dy;
  const Reveal({super.key, required this.child, this.delayMs = 0, this.dy = 24});
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> a = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () { if (mounted) c.forward(); });
  }
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: a,
        builder: (_, child) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, widget.dy * (1 - a.value)), child: child)),
        child: widget.child,
      );
}

class ProductCard extends StatelessWidget {
  final Product p;
  final int index;
  const ProductCard(this.p, {super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final wished = s.isWished(p.id);
    return Reveal(
      delayMs: (index % 4) * 70,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(fit: StackFit.expand, children: [
              Container(color: SBR.ivory, child: NetImage(p.image)),
              if (p.onSale) const Positioned(left: 8, top: 8, child: _Badge('SALE', dark: true)),
              Positioned(
                right: 4, top: 4,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => s.toggleWish(p),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(wished ? Icons.favorite : Icons.favorite_border, key: ValueKey(wished), color: wished ? SBR.gold : SBR.ink, size: 22),
                  ),
                ),
              ),
              if (!p.inStock)
                Positioned(left: 0, right: 0, bottom: 0, child: Container(color: Colors.white70, padding: const EdgeInsets.all(6),
                    child: const Text('OUT OF STOCK', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, letterSpacing: 2)))),
            ]),
          ),
          const SizedBox(height: 10),
          if (p.categoryLabel.isNotEmpty)
            Text(p.categoryLabel.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, letterSpacing: 1.8, color: SBR.muted)),
          const SizedBox(height: 3),
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: SBR.serif(17, height: 1.15)),
          const SizedBox(height: 4),
          PriceText(p, size: 14),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String t;
  final bool dark;
  const _Badge(this.t, {this.dark = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: dark ? SBR.ink : Colors.white,
        child: Text(t, style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600, color: dark ? SBR.gold2 : SBR.ink)),
      );
}

/// Two-column responsive product grid as a sliver.
class ProductSliverGrid extends StatelessWidget {
  final List<Product> products;
  const ProductSliverGrid(this.products, {super.key});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 900 ? 4 : (w > 600 ? 3 : 2);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 26, crossAxisSpacing: 12, childAspectRatio: .52),
        delegate: SliverChildBuilderDelegate((c, i) => ProductCard(products[i], index: i), childCount: products.length),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, text;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.text, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 84, height: 84, decoration: const BoxDecoration(color: SBR.ivory, shape: BoxShape.circle), child: Icon(icon, size: 36, color: SBR.gold)),
            const SizedBox(height: 20),
            Text(title, style: SBR.serif(26), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: SBR.muted)),
            if (action != null) ...[const SizedBox(height: 24), SbrButton(action!, onPressed: onAction, expand: false)],
          ]),
        ),
      );
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry(this.message, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => EmptyState(icon: Icons.wifi_off_rounded, title: 'Connection problem', text: message, action: 'Try again', onAction: onRetry);
}

/// Shimmering placeholder grid while products load.
class LoadingGrid extends StatefulWidget {
  final int count;
  const LoadingGrid({super.key, this.count = 4});
  @override
  State<LoadingGrid> createState() => _LoadingGridState();
}

class _LoadingGridState extends State<LoadingGrid> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 26, crossAxisSpacing: 12, childAspectRatio: .52),
          delegate: SliverChildBuilderDelegate((_, i) => FadeTransition(
                opacity: Tween(begin: .45, end: 1.0).animate(c),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AspectRatio(aspectRatio: 4 / 5, child: Container(color: SBR.cream)),
                  const SizedBox(height: 12),
                  Container(height: 12, width: 90, color: SBR.cream),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 130, color: SBR.cream),
                ]),
              ), childCount: widget.count),
        ),
      );
}
