import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import 'state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  final state = AppState();
  runApp(AppScope(state: state, child: SbrApp(state: state)));
}

class SbrApp extends StatelessWidget {
  final AppState state;
  const SbrApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: SBR.theme(),
        home: SplashGate(state: state),
      );
}

/// Animated splash while the store session starts.
class SplashGate extends StatefulWidget {
  final AppState state;
  const SplashGate({super.key, required this.state});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([widget.state.init(), Future.delayed(const Duration(milliseconds: 1600))]).then((_) {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  void dispose() { c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: ready
          ? const MainShell()
          : Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: SBR.ink,
              body: Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: c, curve: Curves.easeOut),
                  child: ScaleTransition(
                    scale: Tween(begin: .88, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/logo.png', width: 220),
                      const SizedBox(height: 28),
                      const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 1.6, color: SBR.gold)),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  static void goTab(BuildContext context, int i) => context.findAncestorStateOfType<_MainShellState>()?.go(i);
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void go(int i) {
    if (i == index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => index = i);
  }

  Widget _tab(int i, Widget root) => Offstage(
        offstage: index != i,
        child: TickerMode(
          enabled: index == i,
          child: Navigator(key: _navKeys[i], onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKeys[index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (index != 0) {
          setState(() => index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(children: [
          _tab(0, const HomeScreen()),
          _tab(1, const ShopScreen()),
          _tab(2, const WishlistScreen()),
          _tab(3, const CartScreen()),
          _tab(4, const AccountScreen()),
        ]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: SBR.line))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(children: [
                _item(0, Icons.home_outlined, Icons.home, 'Home'),
                _item(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Shop'),
                _item(2, Icons.favorite_border, Icons.favorite, 'Wishlist', badge: s.wishlist.length),
                _item(3, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Bag', badge: s.cart.count),
                _item(4, Icons.person_outline, Icons.person, 'Account'),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData active, String label, {int badge = 0}) {
    final sel = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => go(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(duration: const Duration(milliseconds: 300), height: 2, width: sel ? 22 : 0, color: SBR.gold, margin: const EdgeInsets.only(bottom: 6)),
          Stack(clipBehavior: Clip.none, children: [
            AnimatedScale(scale: sel ? 1.1 : 1, duration: const Duration(milliseconds: 250), child: Icon(sel ? active : icon, color: sel ? SBR.ink : SBR.muted, size: 24)),
            if (badge > 0)
              Positioned(
                right: -8, top: -4,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(badge), tween: Tween(begin: 1.6, end: 1), duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 17),
                    decoration: BoxDecoration(color: SBR.gold, borderRadius: BorderRadius.circular(9)),
                    child: Text('$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10.5, letterSpacing: .6, color: sel ? SBR.ink : SBR.muted, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
