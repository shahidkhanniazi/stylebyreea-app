import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'search_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> featured = [], latest = [], sets = [];
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final api = StoreApi.instance;
      final r = await Future.wait([
        api.products(featured: true, perPage: 8),
        api.products(perPage: 8, orderby: 'date'),
        api.products(search: 'set', perPage: 10),
      ]);
      featured = r[0].items;
      latest = r[1].items;
      sets = r[2].items;
      if (featured.isEmpty) featured = latest;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Please check your internet connection.';
    }
    if (mounted) setState(() => loading = false);
  }

  void _openCat(Category c) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c)));

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: RefreshIndicator(
        color: SBR.gold,
        onRefresh: () async { await _load(); await s.loadCategories(); },
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true, floating: true, backgroundColor: SBR.ink, toolbarHeight: 64,
            title: Image.asset('assets/logo.png', height: 44),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: Color(0xFFF3EDE2)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()))),
            ],
            bottom: const PreferredSize(preferredSize: Size.fromHeight(30), child: _Marquee()),
          ),
          if (error != null)
            SliverFillRemaining(hasScrollBody: false, child: ErrorRetry(error!, _load))
          else ...[
            SliverToBoxAdapter(child: _Hero(products: featured, loading: loading)),
            SliverToBoxAdapter(child: SectionHeader('Curated for you', 'Shop by Category')),
            SliverToBoxAdapter(child: _CategoryRail(onTap: _openCat)),
            SliverToBoxAdapter(child: SectionHeader('Just landed', 'New Arrivals', onMore: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryScreen(title: 'New Arrivals')));
            })),
            if (loading) const LoadingGrid() else ProductSliverGrid(latest.take(6).toList()),
            SliverToBoxAdapter(child: _Editorial(onTap: () { final c = s.categoryBySlug('women'); if (c != null) _openCat(c); })),
            if (sets.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader('Best sellers', 'Co-ord Sets', onMore: () { final c = s.categoryBySlug('coord-sets'); if (c != null) _openCat(c); })),
              SliverToBoxAdapter(child: _HorizontalProducts(sets)),
            ],
            SliverToBoxAdapter(child: _Split(onMen: () { final c = s.categoryBySlug('men'); if (c != null) _openCat(c); },
                onWomen: () { final c = s.categoryBySlug('women'); if (c != null) _openCat(c); }, products: latest)),
            const SliverToBoxAdapter(child: _Usp()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ]),
      ),
    );
  }
}

class _Marquee extends StatefulWidget {
  const _Marquee();
  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
  static const text = 'FREE UK DELIVERY OVER £50   ✦   NEW SEASON CO-ORDS JUST LANDED   ✦   EASY 14-DAY RETURNS   ✦   ';
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
        height: 30, color: const Color(0xFF1B1B1B), alignment: Alignment.centerLeft,
        child: ClipRect(
          child: LayoutBuilder(builder: (context, box) {
            const style = TextStyle(color: SBR.gold2, fontSize: 10.5, letterSpacing: 2.2);
            final tp = TextPainter(text: const TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
            final w = tp.width;
            return AnimatedBuilder(
              animation: c,
              builder: (_, __) => Transform.translate(
                offset: Offset(-w * c.value, 0),
                child: OverflowBox(
                  maxWidth: double.infinity, alignment: Alignment.centerLeft,
                  child: const Row(children: [Text(text, style: style), Text(text, style: style), Text(text, style: style)]),
                ),
              ),
            );
          }),
        ),
      );
}

class _Hero extends StatefulWidget {
  final List<Product> products;
  final bool loading;
  const _Hero({required this.products, required this.loading});
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final pc = PageController();
  int page = 0;
  Timer? t;
  static const slides = [
    ('NEW SEASON', 'The Art of\nEffortless Style'),
    ('THE DENIM EDIT', 'Made to move.\nMade to last.'),
    ('KNITWEAR', 'Co-ords for\nEvery Mood'),
  ];

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !pc.hasClients || widget.products.isEmpty) return;
      final int n = widget.products.length < 5 ? widget.products.length : 5;
      pc.animateToPage((page + 1) % n, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() { t?.cancel(); pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.width * 1.15;
    if (widget.loading || widget.products.isEmpty) return Container(height: h, color: SBR.cream);
    final items = widget.products.take(5).toList();
    return SizedBox(
      height: h,
      child: Stack(children: [
        PageView.builder(
          controller: pc, itemCount: items.length,
          onPageChanged: (i) => setState(() => page = i),
          itemBuilder: (_, i) {
            final p = items[i];
            final sl = slides[i % slides.length];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
              child: Stack(fit: StackFit.expand, children: [
                AnimatedBuilder(
                  animation: pc,
                  builder: (_, child) {
                    double off = 0;
                    if (pc.hasClients && pc.position.haveDimensions) off = (pc.page ?? 0) - i;
                    return Transform.scale(scale: 1 + off.abs() * .12, child: Transform.translate(offset: Offset(off * 60, 0), child: child));
                  },
                  child: NetImage(p.hoverImage),
                ),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x22000000), Color(0xCC000000)], stops: [.35, .6, 1]))),
                Positioned(
                  left: 22, right: 22, bottom: 54,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Column(key: ValueKey('$page-$i'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sl.$1, style: SBR.eyebrow(c: SBR.gold2)),
                      const SizedBox(height: 10),
                      Text(sl.$2, style: SBR.serif(40, c: Colors.white, height: 1.02)),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: const BoxDecoration(gradient: SBR.goldGradient),
                        child: const Text('SHOP NOW', style: TextStyle(fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
        Positioned(
          left: 22, bottom: 24,
          child: Row(children: List.generate(items.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 350), margin: const EdgeInsets.only(right: 8), height: 3,
                width: i == page ? 34 : 16, color: i == page ? Colors.white : Colors.white38))),
        ),
      ]),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final void Function(Category) onTap;
  const _CategoryRail({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    var cats = AppConfig.homeCategorySlugs.map(s.categoryBySlug).whereType<Category>().where((c) => c.count > 0).toList();
    if (cats.isEmpty) cats = s.categories.where((c) => c.count > 0).take(8).toList();
    if (cats.isEmpty) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: SBR.gold, strokeWidth: 1.5)));
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length, separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = cats[i];
          return Reveal(
            delayMs: i * 80,
            child: GestureDetector(
              onTap: () => onTap(c),
              child: SizedBox(
                width: 140,
                child: Stack(fit: StackFit.expand, children: [
                  NetImage(c.image ?? ''),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xAA000000)], stops: [.45, 1]))),
                  Positioned(left: 10, right: 10, bottom: 14, child: Column(children: [
                    Text(c.name, textAlign: TextAlign.center, style: SBR.serif(19, c: Colors.white)),
                    Text('${c.count} STYLES', style: const TextStyle(color: Colors.white70, fontSize: 9.5, letterSpacing: 2)),
                  ])),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Editorial extends StatelessWidget {
  final VoidCallback onTap;
  const _Editorial({required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 40),
        color: SBR.ink,
        padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THE DENIM EDIT', style: SBR.eyebrow()),
          const SizedBox(height: 12),
          Text('Made to move.', style: SBR.serif(36, c: Colors.white)),
          ShaderMask(
            shaderCallback: (r) => SBR.goldGradient.createShader(r),
            child: Text('Made to last.', style: SBR.serif(36, c: Colors.white, style: FontStyle.italic)),
          ),
          const SizedBox(height: 14),
          const Text('Sculpting skinnies, relaxed tapers and acid-wash sets — premium stretch denim that keeps its shape all day.',
              style: TextStyle(color: Color(0xFFCFC9BD), height: 1.6)),
          const SizedBox(height: 24),
          SbrButton('Explore women', style: BtnStyle.gold, expand: false, onPressed: onTap),
        ]),
      );
}

class _HorizontalProducts extends StatelessWidget {
  final List<Product> products;
  const _HorizontalProducts(this.products);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 330,
        child: ListView.separated(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length, separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 170, child: ProductCard(products[i], index: i)),
        ),
      );
}

class _Split extends StatelessWidget {
  final VoidCallback onMen, onWomen;
  final List<Product> products;
  const _Split({required this.onMen, required this.onWomen, required this.products});
  @override
  Widget build(BuildContext context) {
    String img(bool men) {
      for (final p in products) {
        final isMen = p.categories.any((c) => c.slug.startsWith('men'));
        final isWomen = p.categories.any((c) => c.slug.startsWith('women'));
        if ((men && isMen) || (!men && isWomen)) return p.hoverImage;
      }
      return products.isNotEmpty ? products.first.hoverImage : '';
    }
    Widget tile(String eyebrow, String title, String url, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: .72,
              child: Stack(fit: StackFit.expand, children: [
                NetImage(url),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)], stops: [.5, 1]))),
                Positioned(left: 14, bottom: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(eyebrow, style: SBR.eyebrow(c: SBR.gold2)),
                  Text(title, style: SBR.serif(28, c: Colors.white)),
                ])),
              ]),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(children: [
        tile('FOR HIM', 'Menswear', img(true), onMen),
        const SizedBox(width: 3),
        tile('FOR HER', 'Womenswear', img(false), onWomen),
      ]),
    );
  }
}

class _Usp extends StatelessWidget {
  const _Usp();
  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t, String s) => Expanded(child: Column(children: [
          Icon(i, color: SBR.gold, size: 26),
          const SizedBox(height: 8),
          Text(t, textAlign: TextAlign.center, style: SBR.serif(16)),
          Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: SBR.muted)),
        ]));
    return Container(
      margin: const EdgeInsets.only(top: 40), color: SBR.ivory, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        item(Icons.local_shipping_outlined, 'Free Delivery', 'Over £50'),
        item(Icons.replay_rounded, 'Easy Returns', '14 days'),
        item(Icons.lock_outline, 'Secure', 'Checkout'),
      ]),
    );
  }
}
