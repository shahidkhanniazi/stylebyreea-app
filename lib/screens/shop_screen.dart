import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'search_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tops = s.topCategories;
    void open(Category? c, {String? title}) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: c, title: title)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())))],
      ),
      body: tops.isEmpty
          ? RefreshIndicator(
              color: SBR.gold, onRefresh: s.loadCategories,
              child: ListView(children: const [SizedBox(height: 200), Center(child: CircularProgressIndicator(color: SBR.gold, strokeWidth: 1.5))]))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 30), children: [
              _AllTile(onTap: () => open(null, title: 'All Products')),
              const SizedBox(height: 14),
              for (var i = 0; i < tops.length; i++)
                Reveal(delayMs: i * 90, child: _CatBlock(cat: tops[i], children: s.childrenOf(tops[i].id), open: open)),
            ]),
    );
  }
}

class _AllTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AllTile({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(gradient: SBR.goldGradient),
          child: Row(children: [
            Expanded(child: Text('Shop all products', style: SBR.serif(24))),
            const Icon(Icons.arrow_forward),
          ]),
        ),
      );
}

class _CatBlock extends StatelessWidget {
  final Category cat;
  final List<Category> children;
  final void Function(Category?, {String? title}) open;
  const _CatBlock({required this.cat, required this.children, required this.open});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(border: Border.all(color: SBR.line)),
        child: Column(children: [
          GestureDetector(
            onTap: () => open(cat),
            child: SizedBox(
              height: 170,
              child: Stack(fit: StackFit.expand, children: [
                NetImage(cat.image ?? ''),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xB3000000), Colors.transparent], stops: [0, .8]))),
                Positioned(left: 20, top: 0, bottom: 0, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat.name, style: SBR.serif(34, c: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${cat.count} STYLES', style: SBR.eyebrow(c: SBR.gold2)),
                ])),
              ]),
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in children)
                  ActionChip(
                    label: Text('${c.name}  ·  ${c.count}'),
                    onPressed: () => open(c, title: '${cat.name} · ${c.name}'),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: SBR.line),
                    shape: const StadiumBorder(),
                  ),
              ]),
            ),
        ]),
      );
}
