import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class PageResult<T> {
  final List<T> items;
  final int totalPages;
  final int total;
  PageResult(this.items, this.totalPages, this.total);
}

class CheckoutResult {
  final int orderId;
  final String orderKey;
  final String status;
  final String? redirectUrl;
  CheckoutResult(this.orderId, this.orderKey, this.status, this.redirectUrl);
}

/// Client for the WooCommerce Store API (public, no API keys needed).
/// Cart sessions are kept with the `Cart-Token` header, saved on the device.
class StoreApi {
  StoreApi._();
  static final StoreApi instance = StoreApi._();

  final http.Client _http = http.Client();
  String? _cartToken;
  String? _nonce;
  static const _tokenKey = 'sbr_cart_token';

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _cartToken = p.getString(_tokenKey);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_cartToken != null) 'Cart-Token': _cartToken!,
        if (_nonce != null) 'Nonce': _nonce!,
      };

  Future<void> _capture(http.Response r) async {
    final t = r.headers['cart-token'];
    final n = r.headers['nonce'];
    if (n != null && n.isNotEmpty) _nonce = n;
    if (t != null && t.isNotEmpty && t != _cartToken) {
      _cartToken = t;
      final p = await SharedPreferences.getInstance();
      await p.setString(_tokenKey, t);
    }
  }

  Future<void> resetCartSession() async {
    _cartToken = null;
    _nonce = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
  }

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('${AppConfig.storeApi}$path').replace(queryParameters: q);

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw ApiException('Unexpected response from the store (${r.statusCode}).');
    }
    if (r.statusCode >= 400) {
      final msg = body is Map && body['message'] != null ? stripHtml('${body['message']}') : 'Something went wrong (${r.statusCode}).';
      throw ApiException(msg);
    }
    return body;
  }

  Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    final r = await _http.get(_u(path, q), headers: _headers).timeout(const Duration(seconds: 25));
    await _capture(r);
    return _decode(r);
  }

  Future<(dynamic, http.Response)> _getRaw(String path, [Map<String, String>? q]) async {
    final r = await _http.get(_u(path, q), headers: _headers).timeout(const Duration(seconds: 25));
    await _capture(r);
    return (_decode(r), r);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body, {bool retried = false}) async {
    if (_nonce == null && _cartToken == null) await getCart(); // obtain session first
    final r = await _http.post(_u(path), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 40));
    await _capture(r);
    // Expired session / nonce: refresh once and retry.
    if (!retried && (r.statusCode == 401 || r.statusCode == 403)) {
      await resetCartSession();
      await getCart();
      return _post(path, body, retried: true);
    }
    return _decode(r);
  }

  // ---------------- Catalogue ----------------
  Future<PageResult<Product>> products({
    int page = 1, int perPage = 20, int? category, String? search, String orderby = 'date', String order = 'desc',
    bool? featured, bool? onSale, List<int>? include,
  }) async {
    final q = <String, String>{'page': '$page', 'per_page': '$perPage', 'orderby': orderby, 'order': order};
    if (category != null) q['category'] = '$category';
    if (search != null && search.trim().isNotEmpty) q['search'] = search.trim();
    if (featured == true) q['featured'] = 'true';
    if (onSale == true) q['on_sale'] = 'true';
    if (include != null && include.isNotEmpty) q['include'] = include.join(',');
    final (data, res) = await _getRaw('/products', q);
    final items = (data as List).map((e) => Product.fromJson(e)).toList();
    return PageResult(items, int.tryParse(res.headers['x-wp-totalpages'] ?? '1') ?? 1, int.tryParse(res.headers['x-wp-total'] ?? '${items.length}') ?? items.length);
  }

  Future<Product> product(int id) async => Product.fromJson(await _get('/products/$id'));

  Future<List<Category>> categories() async {
    final data = await _get('/products/categories', {'per_page': '100'});
    return (data as List).map((e) => Category.fromJson(e)).where((c) => c.slug != 'uncategorized').toList();
  }

  // ---------------- Cart ----------------
  Future<Cart> getCart() async => Cart.fromJson(await _get('/cart'));

  Future<Cart> addItem(int id, int qty, {Map<String, String>? variation}) async {
    final body = <String, dynamic>{'id': id, 'quantity': qty};
    if (variation != null && variation.isNotEmpty) {
      body['variation'] = variation.entries.map((e) => {'attribute': e.key, 'value': e.value}).toList();
    }
    return Cart.fromJson(await _post('/cart/add-item', body));
  }

  Future<Cart> updateItem(String key, int qty) async => Cart.fromJson(await _post('/cart/update-item', {'key': key, 'quantity': qty}));
  Future<Cart> removeItem(String key) async => Cart.fromJson(await _post('/cart/remove-item', {'key': key}));
  Future<Cart> applyCoupon(String code) async => Cart.fromJson(await _post('/cart/apply-coupon', {'code': code}));
  Future<Cart> removeCoupon(String code) async => Cart.fromJson(await _post('/cart/remove-coupon', {'code': code}));

  Future<Cart> updateCustomer(Address billing) async => Cart.fromJson(await _post('/cart/update-customer', {
        'billing_address': billing.toJson(),
        'shipping_address': billing.toJson(billing: false),
      }));

  Future<Cart> selectShipping(String packageId, String rateId) async =>
      Cart.fromJson(await _post('/cart/select-shipping-rate', {'package_id': int.tryParse(packageId) ?? packageId, 'rate_id': rateId}));

  // ---------------- Checkout ----------------
  Future<CheckoutResult> checkout({required Address billing, required String paymentMethod, String note = ''}) async {
    final data = await _post('/checkout', {
      'billing_address': billing.toJson(),
      'shipping_address': billing.toJson(billing: false),
      'customer_note': note,
      'payment_method': paymentMethod,
      'payment_data': <dynamic>[],
    });
    final pr = data['payment_result'] as Map<String, dynamic>? ?? {};
    final redirect = '${pr['redirect_url'] ?? ''}';
    return CheckoutResult(
      (data['order_id'] as num).toInt(),
      '${data['order_key'] ?? ''}',
      '${data['status'] ?? ''}',
      redirect.isEmpty ? null : redirect,
    );
  }

  /// Order status for a guest order (needs the order key + billing email).
  Future<String> orderStatus(SavedOrder o) async {
    final data = await _get('/order/${o.id}', {'key': o.key, 'billing_email': o.email});
    return '${data['status'] ?? o.status}';
  }
}
