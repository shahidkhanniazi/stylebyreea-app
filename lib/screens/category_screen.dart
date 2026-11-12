import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Product listing for a category (or all products when [category] is null).
class CategoryScreen extends StatefulWidget {
  final Category? category;
  final String? title;
  final String? search;
  const CategoryScreen({super.key, this.category, this.title, this.search});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final items = <Product>[];
  int page = 1, totalPages = 1, total = 0;
  bool loading = false;
  String? error;
  Category? sub; // selected sub-category
  String sort = 'date';
  final scroll = ScrollController();

  static const sorts = {
    'date': ('Newest', 'date', 'desc'),
    'price_asc': ('Price: low to high', 'price', 'asc'),
    'price_desc': ('Price: high to low', 'price', 'desc'),
    'title': ('Name A–Z', 'title', 'asc'),
    'popularity': ('Most popular', 'popularity', 'desc'),
  };

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 600) _load();
    });
  }

  @override
  void dispose() { scroll.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (loading) return;
    if (!reset && page > totalPages) return;
    if (reset) { page = 1; totalPages = 1; items.clear(); }
    setState(() { loading = true; error = null; });
    try {
      final s = sorts[sort]!;
      final r = await StoreApi.instance.products(
        page: page, perPage: 20, category: (sub ?? widget.category)?.id, search: widget.search, orderby: s.$2, order: s.$3,
      );
      items.addAll(r.items);
      totalPages = r.totalPages;
      total = r.total;
      page++;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Please check your internet connection.';
    }
    if (mounted) setState(() => loading = false);
  }

  void _pickSort() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(18), child: Text('Sort by', style: SBR.serif(24))),
          for (final e in sorts.entries)
            ListTile(
              title: Text(e.value.$1),
              trailing: sort == e.key ? const Icon(Icons.check, color: SBR.gold) : null,
              onTap: () { Navigator.pop(context); setState(() => sort = e.key); _load(reset: true); },
            ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cat = widget.category;
    final subs = cat == null ? <Category>[] : s.childrenOf(cat.id);
    final title = widget.title ?? cat?.name ?? (widget.search != null ? '“${widget.search}”' : 'Shop');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        color: SBR.gold,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(controller: scroll, slivers: [
          if (subs.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 62,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), children: [
                  _chip('All', sub == null, () { setState(() => sub = null); _load(reset: true); }),
                  for (final c in subs) _chip(c.name, sub?.id == c.id, () { setState(() => sub = c); _load(reset: true); }),
                ]),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
              child: Row(children: [
                Text(loading && items.isEmpty ? 'Loading…' : '$total products', style: const TextStyle(color: SBR.muted, fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickSort,
                  icon: const Icon(Icons.swap_vert, size: 18, color: SBR.ink),
                  label: Text(sorts[sort]!.$1, style: const TextStyle(color: SBR.ink, fontSize: 13)),
                ),
              ]),
            ),
          ),
          if (error != null && items.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: ErrorRetry(error!, () => _load(reset: true)))
          else if (items.isEmpty && loading)
            const LoadingGrid(count: 6)
          else if (items.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, title: 'No products found', text: 'Try another category or search.'))
          else
            ProductSliverGrid(items),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: loading && items.isNotEmpty
                  ? const CircularProgressIndicator(color: SBR.gold, strokeWidth: 1.5)
                  : const SizedBox.shrink()),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: active ? SBR.ink : Colors.white,
              border: Border.all(color: active ? SBR.ink : SBR.line),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, color: active ? Colors.white : SBR.ink)),
          ),
        ),
      );
}
