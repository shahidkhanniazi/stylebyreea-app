import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  Timer? debounce;
  List<Product> results = [];
  bool loading = false;
  String query = '';
  static const trending = ['Polo', 'Jeans', 'Knit set', 'Tee', 'Trousers', 'Shorts'];

  @override
  void dispose() { debounce?.cancel(); ctrl.dispose(); super.dispose(); }

  void _changed(String q) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q, {bool save = false}) async {
    q = q.trim();
    setState(() { query = q; });
    if (q.length < 2) { setState(() => results = []); return; }
    setState(() => loading = true);
    try {
      final r = await StoreApi.instance.products(search: q, perPage: 30);
      if (mounted && q == query) setState(() => results = r.items);
      if (save && mounted) AppScope.read(context).addSearch(q);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  void _tapTerm(String t) {
    ctrl.text = t;
    ctrl.selection = TextSelection.collapsed(offset: t.length);
    _search(t, save: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: ctrl, autofocus: true, textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 16), cursorColor: SBR.gold2,
          decoration: const InputDecoration(
            hintText: 'Search tees, jeans, co-ords…', hintStyle: TextStyle(color: Colors.white54),
            filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          ),
          onChanged: _changed,
          onSubmitted: (q) => _search(q, save: true),
        ),
        actions: [
          if (ctrl.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.close), onPressed: () { ctrl.clear(); setState(() { results = []; query = ''; }); }),
        ],
      ),
      body: query.length < 2
          ? ListView(padding: const EdgeInsets.all(20), children: [
              if (s.recentSearches.isNotEmpty) ...[
                Row(children: [
                  Text('RECENT', style: SBR.eyebrow()),
                  const Spacer(),
                  TextButton(onPressed: s.clearSearches, child: const Text('Clear', style: TextStyle(color: SBR.muted))),
                ]),
                for (final r in s.recentSearches)
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.history, color: SBR.muted), title: Text(r), onTap: () => _tapTerm(r)),
                const SizedBox(height: 20),
              ],
              Text('TRENDING', style: SBR.eyebrow()),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in trending)
                  ActionChip(label: Text(t), onPressed: () => _tapTerm(t), backgroundColor: Colors.white, side: const BorderSide(color: SBR.line), shape: const StadiumBorder()),
              ]),
            ])
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Text(loading ? 'Searching…' : '${results.length} results for “$query”', style: const TextStyle(color: SBR.muted)),
              )),
              if (loading && results.isEmpty)
                const LoadingGrid()
              else if (results.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, title: 'Nothing found', text: 'Try a different word, like “polo” or “jeans”.'))
              else
                ProductSliverGrid(results),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ]),
    );
  }
}
