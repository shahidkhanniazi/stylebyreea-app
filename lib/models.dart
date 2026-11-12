import 'config.dart';

String stripHtml(String s) {
  var t = s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const ents = {
    '&amp;': '&', '&nbsp;': ' ', '&quot;': '"', '&#039;': "'", '&#8217;': '’', '&#8216;': '‘',
    '&ndash;': '–', '&mdash;': '—', '&#8211;': '–', '&#8212;': '—', '&pound;': '£', '&lt;': '<', '&gt;': '>',
    '&ldquo;': '“', '&rdquo;': '”', '&hellip;': '…',
  };
  ents.forEach((k, v) => t = t.replaceAll(k, v));
  return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

class Money {
  final int minor; // e.g. 200
  final int unit; // e.g. 2
  final String prefix;
  final String suffix;
  const Money(this.minor, {this.unit = 2, this.prefix = '£', this.suffix = ''});

  factory Money.fromPrices(Map<String, dynamic>? p, [String key = 'price']) {
    if (p == null) return const Money(0);
    return Money(
      int.tryParse('${p[key] ?? 0}') ?? 0,
      unit: (p['currency_minor_unit'] as num?)?.toInt() ?? 2,
      prefix: (p['currency_prefix'] ?? p['currency_symbol'] ?? '£').toString(),
      suffix: (p['currency_suffix'] ?? '').toString(),
    );
  }

  double get value => minor / _pow10(unit);
  static int _pow10(int n) { var r = 1; for (var i = 0; i < n; i++) { r *= 10; } return r; }

  @override
  String toString() => '$prefix${value.toStringAsFixed(unit)}$suffix';
}

class ProductImage {
  final String src;
  final String thumb;
  final String alt;
  ProductImage(this.src, this.thumb, this.alt);
  factory ProductImage.fromJson(Map<String, dynamic> j) =>
      ProductImage(j['src'] ?? '', (j['thumbnail'] ?? j['src'] ?? '').toString(), (j['alt'] ?? '').toString());
}

class AttrTerm {
  final int id;
  final String name;
  final String slug;
  AttrTerm(this.id, this.name, this.slug);
}

class ProductAttribute {
  final String name; // label, e.g. "size"
  final String taxonomy; // e.g. "pa_size"
  final bool hasVariations;
  final List<AttrTerm> terms;
  ProductAttribute(this.name, this.taxonomy, this.hasVariations, this.terms);

  factory ProductAttribute.fromJson(Map<String, dynamic> j) {
    final terms = ((j['terms'] as List?) ?? [])
        .map((t) => AttrTerm((t['id'] as num?)?.toInt() ?? 0, stripHtml('${t['name']}'), '${t['slug']}'))
        .toList();
    terms.sort((a, b) => sizeRank(a.slug).compareTo(sizeRank(b.slug)));
    return ProductAttribute(stripHtml('${j['name'] ?? ''}'), '${j['taxonomy'] ?? ''}', j['has_variations'] == true, terms);
  }

  String get label => name.isEmpty ? 'Option' : name[0].toUpperCase() + name.substring(1);
}

int sizeRank(String slug) {
  final i = AppConfig.sizeOrder.indexOf(slug.toLowerCase());
  return i < 0 ? 999 : i;
}

class Variation {
  final int id;
  final Map<String, String> attributes; // attribute name (lowercase) -> term slug
  Variation(this.id, this.attributes);
  factory Variation.fromJson(Map<String, dynamic> j) => Variation(
        (j['id'] as num).toInt(),
        {
          for (final a in (j['attributes'] as List? ?? []))
            '${a['name']}'.toLowerCase(): '${a['value']}'
        },
      );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final int count;
  final String? image;
  Category(this.id, this.name, this.slug, this.parent, this.count, this.image);
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        (j['id'] as num).toInt(),
        stripHtml('${j['name']}'),
        '${j['slug']}',
        (j['parent'] as num?)?.toInt() ?? 0,
        (j['count'] as num?)?.toInt() ?? 0,
        (j['image'] is Map) ? j['image']['src'] as String? : null,
      );
}

class Product {
  final int id;
  final String name;
  final String type;
  final String sku;
  final String permalink;
  final String shortDescription;
  final String description;
  final Money price;
  final Money regularPrice;
  final bool onSale;
  final bool inStock;
  final bool purchasable;
  final List<ProductImage> images;
  final List<Category> categories;
  final List<ProductAttribute> attributes;
  final List<Variation> variations;

  Product({
    required this.id, required this.name, required this.type, required this.sku, required this.permalink,
    required this.shortDescription, required this.description, required this.price, required this.regularPrice,
    required this.onSale, required this.inStock, required this.purchasable, required this.images,
    required this.categories, required this.attributes, required this.variations,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: (j['id'] as num).toInt(),
        name: stripHtml('${j['name']}'),
        type: '${j['type'] ?? 'simple'}',
        sku: '${j['sku'] ?? ''}',
        permalink: '${j['permalink'] ?? ''}',
        shortDescription: stripHtml('${j['short_description'] ?? ''}'),
        description: stripHtml('${j['description'] ?? ''}'),
        price: Money.fromPrices(j['prices'] as Map<String, dynamic>?, 'price'),
        regularPrice: Money.fromPrices(j['prices'] as Map<String, dynamic>?, 'regular_price'),
        onSale: j['on_sale'] == true,
        inStock: j['is_in_stock'] != false,
        purchasable: j['is_purchasable'] != false,
        images: ((j['images'] as List?) ?? []).map((e) => ProductImage.fromJson(e)).toList(),
        categories: ((j['categories'] as List?) ?? [])
            .map((c) => Category((c['id'] as num).toInt(), stripHtml('${c['name']}'), '${c['slug']}', 0, 0, null))
            .toList(),
        attributes: ((j['attributes'] as List?) ?? []).map((a) => ProductAttribute.fromJson(a)).toList(),
        variations: ((j['variations'] as List?) ?? []).map((v) => Variation.fromJson(v)).toList(),
      );

  bool get isVariable => type == 'variable';
  String get image => images.isNotEmpty ? images.first.src : '';
  String get hoverImage => images.length > 1 ? images[1].src : image;
  List<ProductAttribute> get variationAttributes => attributes.where((a) => a.hasVariations).toList();

  /// Most specific category name (child before parent).
  String get categoryLabel => categories.isEmpty ? '' : categories.last.name;

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'type': type, 'sku': sku, 'permalink': permalink,
        'short_description': shortDescription, 'description': description,
        'prices': {'price': '${price.minor}', 'regular_price': '${regularPrice.minor}', 'currency_minor_unit': price.unit, 'currency_prefix': price.prefix, 'currency_suffix': price.suffix},
        'on_sale': onSale, 'is_in_stock': inStock, 'is_purchasable': purchasable,
        'images': images.map((i) => {'src': i.src, 'thumbnail': i.thumb, 'alt': i.alt}).toList(),
        'categories': categories.map((c) => {'id': c.id, 'name': c.name, 'slug': c.slug}).toList(),
        'attributes': attributes.map((a) => {'name': a.name, 'taxonomy': a.taxonomy, 'has_variations': a.hasVariations, 'terms': a.terms.map((t) => {'id': t.id, 'name': t.name, 'slug': t.slug}).toList()}).toList(),
        'variations': variations.map((v) => {'id': v.id, 'attributes': v.attributes.entries.map((e) => {'name': e.key, 'value': e.value}).toList()}).toList(),
      };

  /// Find the variation that matches the selected attribute slugs.
  Variation? matchVariation(Map<String, String> selected) {
    for (final v in variations) {
      var ok = true;
      v.attributes.forEach((k, val) {
        final s = selected[k];
        if (val.isNotEmpty && s != val) ok = false; // empty value = "any"
      });
      if (ok) return v;
    }
    return null;
  }
}

class CartItem {
  final String key;
  final int id;
  final String name;
  final int quantity;
  final String image;
  final Money linePrice;
  final Money unitPrice;
  final List<String> variationLabels;
  CartItem(this.key, this.id, this.name, this.quantity, this.image, this.linePrice, this.unitPrice, this.variationLabels);

  factory CartItem.fromJson(Map<String, dynamic> j) {
    final totals = j['totals'] as Map<String, dynamic>? ?? {};
    final prices = j['prices'] as Map<String, dynamic>? ?? {};
    final imgs = (j['images'] as List?) ?? [];
    return CartItem(
      '${j['key']}',
      (j['id'] as num).toInt(),
      stripHtml('${j['name']}'),
      (j['quantity'] as num?)?.toInt() ?? 1,
      imgs.isNotEmpty ? '${imgs.first['thumbnail'] ?? imgs.first['src']}' : '',
      Money.fromPrices(totals, 'line_total'),
      Money.fromPrices(prices, 'price'),
      ((j['variation'] as List?) ?? []).map((v) => '${stripHtml('${v['attribute']}')}: ${stripHtml('${v['value']}')}').toList(),
    );
  }
}

class ShippingRate {
  final String packageId;
  final String rateId;
  final String name;
  final Money price;
  final bool selected;
  ShippingRate(this.packageId, this.rateId, this.name, this.price, this.selected);
}

class Cart {
  final List<CartItem> items;
  final int count;
  final Money subtotal;
  final Money shipping;
  final Money discount;
  final Money total;
  final List<String> paymentMethods;
  final bool needsShipping;
  final List<ShippingRate> shippingRates;
  final List<String> coupons;
  final List<String> errors;

  Cart({
    required this.items, required this.count, required this.subtotal, required this.shipping, required this.discount,
    required this.total, required this.paymentMethods, required this.needsShipping, required this.shippingRates,
    required this.coupons, required this.errors,
  });

  factory Cart.empty() => Cart(items: [], count: 0, subtotal: const Money(0), shipping: const Money(0), discount: const Money(0),
      total: const Money(0), paymentMethods: [], needsShipping: false, shippingRates: [], coupons: [], errors: []);

  factory Cart.fromJson(Map<String, dynamic> j) {
    final t = j['totals'] as Map<String, dynamic>? ?? {};
    final rates = <ShippingRate>[];
    for (final pkg in (j['shipping_rates'] as List? ?? [])) {
      for (final r in (pkg['shipping_rates'] as List? ?? [])) {
        rates.add(ShippingRate(
          '${pkg['package_id']}', '${r['rate_id']}', stripHtml('${r['name']}'),
          Money(int.tryParse('${r['price']}') ?? 0, unit: (r['currency_minor_unit'] as num?)?.toInt() ?? 2, prefix: '${r['currency_prefix'] ?? '£'}'),
          r['selected'] == true,
        ));
      }
    }
    return Cart(
      items: ((j['items'] as List?) ?? []).map((e) => CartItem.fromJson(e)).toList(),
      count: (j['items_count'] as num?)?.toInt() ?? 0,
      subtotal: Money.fromPrices(t, 'total_items'),
      shipping: Money.fromPrices(t, 'total_shipping'),
      discount: Money.fromPrices(t, 'total_discount'),
      total: Money.fromPrices(t, 'total_price'),
      paymentMethods: ((j['payment_methods'] as List?) ?? []).map((e) => '$e').toList(),
      needsShipping: j['needs_shipping'] == true,
      shippingRates: rates,
      coupons: ((j['coupons'] as List?) ?? []).map((c) => '${c['code']}').toList(),
      errors: ((j['errors'] as List?) ?? []).map((e) => stripHtml('${e['message']}')).toList(),
    );
  }
}

class Address {
  String firstName, lastName, address1, address2, city, state, postcode, country, email, phone;
  Address({
    this.firstName = '', this.lastName = '', this.address1 = '', this.address2 = '', this.city = '',
    this.state = '', this.postcode = '', this.country = AppConfig.defaultCountry, this.email = '', this.phone = '',
  });

  Map<String, dynamic> toJson({bool billing = true}) {
    final m = {
      'first_name': firstName, 'last_name': lastName, 'address_1': address1, 'address_2': address2,
      'city': city, 'state': state, 'postcode': postcode, 'country': country, 'phone': phone,
    };
    if (billing) m['email'] = email;
    return m;
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        firstName: '${j['first_name'] ?? ''}', lastName: '${j['last_name'] ?? ''}', address1: '${j['address_1'] ?? ''}',
        address2: '${j['address_2'] ?? ''}', city: '${j['city'] ?? ''}', state: '${j['state'] ?? ''}',
        postcode: '${j['postcode'] ?? ''}', country: '${j['country'] ?? AppConfig.defaultCountry}',
        email: '${j['email'] ?? ''}', phone: '${j['phone'] ?? ''}',
      );
}

class SavedOrder {
  final int id;
  final String key;
  final String email;
  final String total;
  final DateTime date;
  final int items;
  String status;
  SavedOrder(this.id, this.key, this.email, this.total, this.date, this.items, this.status);

  Map<String, dynamic> toJson() => {'id': id, 'key': key, 'email': email, 'total': total, 'date': date.toIso8601String(), 'items': items, 'status': status};
  factory SavedOrder.fromJson(Map<String, dynamic> j) => SavedOrder((j['id'] as num).toInt(), '${j['key']}', '${j['email']}',
      '${j['total']}', DateTime.tryParse('${j['date']}') ?? DateTime.now(), (j['items'] as num?)?.toInt() ?? 0, '${j['status']}');
}

String paymentLabel(String id) {
  switch (id) {
    case 'cod': return 'Cash on delivery';
    case 'bacs': return 'Direct bank transfer';
    case 'cheque': return 'Cheque';
    case 'ppcp-gateway':
    case 'paypal': return 'PayPal';
    case 'stripe': return 'Card (Stripe)';
    default: return id.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}
