import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'models.dart';

/// Global app state: cart, wishlist, saved address and order history.
class AppState extends ChangeNotifier {
  final api = StoreApi.instance;
  Cart cart = Cart.empty();
  bool cartBusy = false;
  List<Category> categories = [];
  final Map<int, Product> wishlist = {};
  List<SavedOrder> orders = [];
  Address address = Address();
  final List<String> recentSearches = [];

  Future<void> init() async {
    await api.init();
    final p = await SharedPreferences.getInstance();
    try {
      final w = jsonDecode(p.getString('sbr_wishlist') ?? '[]') as List;
      for (final j in w) {
        final pr = Product.fromJson(j as Map<String, dynamic>);
        wishlist[pr.id] = pr;
      }
      orders = (jsonDecode(p.getString('sbr_orders') ?? '[]') as List).map((e) => SavedOrder.fromJson(e)).toList();
      final a = p.getString('sbr_address');
      if (a != null) address = Address.fromJson(jsonDecode(a));
      recentSearches.addAll(p.getStringList('sbr_searches') ?? []);
    } catch (_) {}
    notifyListeners();
    refreshCart();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      categories = await api.categories();
      notifyListeners();
    } catch (_) {}
  }

  List<Category> get topCategories => categories.where((c) => c.parent == 0 && c.count > 0).toList();
  List<Category> childrenOf(int id) => categories.where((c) => c.parent == id && c.count > 0).toList();
  Category? categoryBySlug(String slug) {
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  // ---------- Cart ----------
  Future<void> refreshCart() async {
    try {
      cart = await api.getCart();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> _cartOp(Future<Cart> Function() op) async {
    cartBusy = true;
    notifyListeners();
    try {
      cart = await op();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the store. Check your internet connection.';
    } finally {
      cartBusy = false;
      notifyListeners();
    }
  }

  Future<String?> addToCart(Product p, {Variation? variation, int qty = 1}) {
    if (variation != null) {
      // Send attributes using their taxonomy (e.g. pa_size) when known.
      final attrs = <String, String>{};
      variation.attributes.forEach((name, value) {
        final a = p.attributes.where((x) => x.name.toLowerCase() == name).toList();
        attrs[a.isNotEmpty && a.first.taxonomy.isNotEmpty ? a.first.taxonomy : name] = value;
      });
      return _cartOp(() => api.addItem(variation.id, qty, variation: attrs));
    }
    return _cartOp(() => api.addItem(p.id, qty));
  }

  Future<String?> setQty(CartItem i, int qty) => qty <= 0 ? _cartOp(() => api.removeItem(i.key)) : _cartOp(() => api.updateItem(i.key, qty));
  Future<String?> remove(CartItem i) => _cartOp(() => api.removeItem(i.key));
  Future<String?> applyCoupon(String code) => _cartOp(() => api.applyCoupon(code));
  Future<String?> removeCoupon(String code) => _cartOp(() => api.removeCoupon(code));
  Future<String?> updateCustomer(Address a) => _cartOp(() => api.updateCustomer(a));
  Future<String?> selectShipping(ShippingRate r) => _cartOp(() => api.selectShipping(r.packageId, r.rateId));

  // ---------- Wishlist ----------
  bool isWished(int id) => wishlist.containsKey(id);
  Future<void> toggleWish(Product p) async {
    if (wishlist.containsKey(p.id)) {
      wishlist.remove(p.id);
    } else {
      wishlist[p.id] = p;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sbr_wishlist', jsonEncode(wishlist.values.map((e) => e.toJson()).toList()));
  }

  // ---------- Address & orders ----------
  Future<void> saveAddress(Address a) async {
    address = a;
    final p = await SharedPreferences.getInstance();
    await p.setString('sbr_address', jsonEncode(a.toJson()));
  }

  Future<void> addOrder(SavedOrder o) async {
    orders.insert(0, o);
    notifyListeners();
    await _saveOrders();
  }

  Future<void> _saveOrders() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sbr_orders', jsonEncode(orders.map((e) => e.toJson()).toList()));
  }

  Future<void> refreshOrders() async {
    for (final o in orders) {
      try {
        o.status = await api.orderStatus(o);
      } catch (_) {}
    }
    notifyListeners();
    await _saveOrders();
  }

  Future<void> afterOrderPlaced() async {
    await api.resetCartSession();
    cart = Cart.empty();
    notifyListeners();
    await refreshCart();
  }

  Future<void> addSearch(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    if (recentSearches.length > 8) recentSearches.removeLast();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('sbr_searches', recentSearches);
    notifyListeners();
  }

  Future<void> clearSearches() async {
    recentSearches.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('sbr_searches');
    notifyListeners();
  }
}

/// Makes [AppState] available to the widget tree without extra packages.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
