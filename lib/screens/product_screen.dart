import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../main.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Product p = widget.product;
  final selected = <String, String>{}; // attribute name (lowercase) -> slug
  int qty = 1, img = 0;
  bool adding = false;
  List<Product> related = [];
  final pc = PageController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() { pc.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    try {
      final fresh = await StoreApi.instance.product(p.id);
      if (mounted) setState(() => p = fresh);
    } catch (_) {}
    if (p.categories.isNotEmpty) {
      try {
        final r = await StoreApi.instance.products(category: p.categories.last.id, perPage: 9, orderby: 'rand');
        if (mounted) setState(() => related = r.items.where((x) => x.id != p.id).take(8).toList());
      } catch (_) {}
    }
  }

  bool _available(ProductAttribute a, AttrTerm t) {
    // A term is available if some variation matches it together with the other current selections.
    final test = Map<String, String>.from(selected)..[a.name.toLowerCase()] = t.slug;
    return p.variations.any((v) {
      for (final e in test.entries) {
        final vv = v.attributes[e.key];
        if (vv != null && vv.isNotEmpty && vv != e.value) return false;
      }
      return true;
    });
  }

  Future<void> _add() async {
    final s = AppScope.read(context);
    Variation? v;
    if (p.isVariable) {
      final missing = p.variationAttributes.where((a) => !selected.containsKey(a.name.toLowerCase())).toList();
      if (missing.isNotEmpty) {
        showSnack(context, 'Please choose a ${missing.first.label.toLowerCase()}');
        return;
      }
      v = p.matchVariation(selected);
      if (v == null) { showSnack(context, 'This combination is not available.'); return; }
    }
    setState(() => adding = true);
    final err = await s.addToCart(p, variation: v, qty: qty);
    if (!mounted) return;
    setState(() => adding = false);
    if (err != null) {
      showSnack(context, err);
    } else {
      showSnack(context, 'Added to your bag', action: 'VIEW BAG', onAction: () => MainShell.goTab(context, 3));
    }
  }

  void _openGallery(int start) => Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
        opaque: false, barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _Gallery(images: p.images, start: start),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));

  void _sizeGuide() => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(),
        builder: (_) => const _SizeGuide(),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final w = MediaQuery.of(context).size.width;
    final wished = s.isWished(p.id);
    final images = p.images.isEmpty ? [ProductImage('', '', '')] : p.images;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, expandedHeight: w * 1.25, backgroundColor: Colors.white, foregroundColor: SBR.ink,
          leading: _circleBtn(Icons.arrow_back, () => Navigator.of(context).pop()),
          actions: [
            _circleBtn(wished ? Icons.favorite : Icons.favorite_border, () => s.toggleWish(p), color: wished ? SBR.gold : SBR.ink),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                controller: pc, itemCount: images.length, onPageChanged: (i) => setState(() => img = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openGallery(i),
                  child: Container(
                    color: SBR.ivory,
                    child: NetImage(images[i].src),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 18, left: 0, right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == img ? 22 : 7, height: 7,
                        decoration: BoxDecoration(color: i == img ? SBR.ink : Colors.black26, borderRadius: BorderRadius.circular(4))))),
                ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (images.length > 1) ...[
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal, itemCount: images.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => pc.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250), width: 60,
                        decoration: BoxDecoration(border: Border.all(color: i == img ? SBR.ink : SBR.line, width: i == img ? 1.5 : 1)),
                        child: NetImage(images[i].thumb),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              if (p.categoryLabel.isNotEmpty) Text(p.categoryLabel.toUpperCase(), style: SBR.eyebrow()),
              const SizedBox(height: 8),
              Text(p.name, style: SBR.serif(32, height: 1.08)),
              const SizedBox(height: 10),
              PriceText(p, size: 22),
              if (p.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(p.shortDescription, style: const TextStyle(color: SBR.ink2, height: 1.6, fontSize: 15)),
              ],
              const Divider(height: 40),
              for (final a in p.variationAttributes) ...[
                Row(children: [
                  Text(a.label.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w600)),
                  if (selected[a.name.toLowerCase()] != null) ...[
                    const SizedBox(width: 8),
                    Text(a.terms.firstWhere((t) => t.slug == selected[a.name.toLowerCase()], orElse: () => AttrTerm(0, '', '')).name,
                        style: const TextStyle(color: SBR.gold, fontSize: 14)),
                  ],
                  const Spacer(),
                  GestureDetector(onTap: _sizeGuide, child: const Text('Size guide', style: TextStyle(fontSize: 13, color: SBR.muted, decoration: TextDecoration.underline))),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in a.terms)
                    Builder(builder: (_) {
                      final key = a.name.toLowerCase();
                      final sel = selected[key] == t.slug;
                      final ok = _available(a, t);
                      return GestureDetector(
                        onTap: ok
                            ? () => setState(() {
                                  if (sel) {
                                    selected.remove(key);
                                  } else {
                                    selected[key] = t.slug;
                                  }
                                })
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          constraints: const BoxConstraints(minWidth: 54), height: 48, alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: sel ? SBR.ink : Colors.white, border: Border.all(color: sel ? SBR.ink : SBR.line)),
                          child: Text(t.name, style: TextStyle(fontWeight: FontWeight.w500, color: sel ? Colors.white : (ok ? SBR.ink : SBR.line),
                              decoration: ok ? null : TextDecoration.lineThrough)),
                        ),
                      );
                    }),
                ]),
                const SizedBox(height: 22),
              ],
              Row(children: [
                Container(
                  height: 54, decoration: BoxDecoration(border: Border.all(color: SBR.line)),
                  child: Row(children: [
                    IconButton(onPressed: qty > 1 ? () => setState(() => qty--) : null, icon: const Icon(Icons.remove, size: 18)),
                    SizedBox(width: 26, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
                    IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add, size: 18)),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(child: SbrButton(p.inStock ? 'Add to bag' : 'Out of stock', loading: adding, onPressed: p.inStock && p.purchasable ? _add : null)),
              ]),
              const SizedBox(height: 22),
              const _Perk(Icons.local_shipping_outlined, 'Free UK delivery on orders over £50'),
              const _Perk(Icons.replay_rounded, 'Free 14-day returns'),
              const _Perk(Icons.lock_outline, 'Secure checkout'),
              const SizedBox(height: 10),
              _Accordion('Description', p.description.isNotEmpty ? p.description : p.shortDescription, open: true),
              const _Accordion('Delivery & Returns',
                  'Standard UK delivery in 2–4 working days, free over £50. Return unworn items with tags within 14 days for a full refund.'),
              if (p.sku.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Text('SKU: ${p.sku}', style: const TextStyle(color: SBR.muted, fontSize: 12))),
            ]),
          ),
        ),
        if (related.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('You may also like', 'Related Products')),
          ProductSliverGrid(related),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }

  Widget _circleBtn(IconData i, VoidCallback onTap, {Color color = SBR.ink}) => Padding(
        padding: const EdgeInsets.all(7),
        child: Material(
          color: Colors.white, shape: const CircleBorder(), elevation: 1,
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(i, size: 20, color: color))),
        ),
      );
}

class _Perk extends StatelessWidget {
  final IconData i;
  final String t;
  const _Perk(this.i, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [Icon(i, color: SBR.gold, size: 20), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 14))]),
      );
}

class _Accordion extends StatefulWidget {
  final String title, body;
  final bool open;
  const _Accordion(this.title, this.body, {this.open = false});
  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion> {
  late bool open = widget.open;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: SBR.line))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => setState(() => open = !open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(children: [
                Expanded(child: Text(widget.title, style: SBR.serif(20))),
                AnimatedRotation(turns: open ? .125 : 0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.add, color: SBR.gold)),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
            child: open
                ? Padding(padding: const EdgeInsets.only(bottom: 18), child: Text(widget.body, style: const TextStyle(color: SBR.ink2, height: 1.65)))
                : const SizedBox(width: double.infinity),
          ),
        ]),
      );
}

class _Gallery extends StatefulWidget {
  final List<ProductImage> images;
  final int start;
  const _Gallery({required this.images, required this.start});
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late final pc = PageController(initialPage: widget.start);
  @override
  void dispose() { pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(
            controller: pc, itemCount: widget.images.length,
            itemBuilder: (_, i) => InteractiveViewer(minScale: 1, maxScale: 4, child: Center(child: NetImage(widget.images[i].src, fit: BoxFit.contain))),
          ),
          SafeArea(child: Align(alignment: Alignment.topRight, child: IconButton(
              onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white, size: 28)))),
        ]),
      );
}

class _SizeGuide extends StatelessWidget {
  const _SizeGuide();
  @override
  Widget build(BuildContext context) {
    Widget table(List<List<String>> rows) => Table(
          border: TableBorder.all(color: SBR.line),
          children: [
            for (var r = 0; r < rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: r == 0 ? SBR.ivory : Colors.white),
                children: [for (final c in rows[r]) Padding(padding: const EdgeInsets.all(8), child: Text(c, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)))],
              ),
          ],
        );
    return DraggableScrollableSheet(
      expand: false, initialChildSize: .7, maxChildSize: .92,
      builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(22), children: [
        Row(children: [Expanded(child: Text('Size Guide', style: SBR.serif(28))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        const SizedBox(height: 12),
        Text('Tops, Polos & Sets', style: SBR.serif(19)), const SizedBox(height: 8),
        table([['Size', 'XS', 'S', 'M', 'L', 'XL', 'XXL'], ['Chest (in)', '34', '36–38', '38–40', '40–42', '42–44', '44–46']]),
        const SizedBox(height: 22),
        Text("Women's Jeans & Shorts (UK)", style: SBR.serif(19)), const SizedBox(height: 8),
        table([['UK', '6', '8', '10', '12', '14'], ['Waist (in)', '24', '26', '28', '30', '32'], ['Hip (in)', '34', '36', '38', '40', '42']]),
        const SizedBox(height: 22),
        Text("Men's Trousers", style: SBR.serif(19)), const SizedBox(height: 8),
        table([['Waist', '30', '32', '34', '36'], ['cm', '76', '81', '86', '91']]),
        const SizedBox(height: 16),
        const Text('Between sizes? Choose the larger size for a relaxed fit.', style: TextStyle(color: SBR.muted)),
      ]),
    );
  }
}
