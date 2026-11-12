import 'package:flutter/material.dart';
import '../state.dart';
import '../widgets/common.dart';
import '../main.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.wishlist.values.toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border, title: 'Your wishlist is empty',
              text: 'Tap the heart on any product to save it here.', action: 'Start shopping',
              onAction: () => MainShell.goTab(context, 1))
          : CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ProductSliverGrid(items),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ]),
    );
  }
}
