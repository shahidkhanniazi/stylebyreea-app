/// App-wide settings. Change these to point the app at another store.
class AppConfig {
  static const String siteUrl = 'https://www.stylebyreea.com';
  static const String storeApi = '$siteUrl/wp-json/wc/store/v1';
  static const String appName = 'Style By Reea';

  /// WhatsApp number with country code, digits only (leave empty to hide the button).
  static const String whatsapp = '';
  static const String email = 'hello@stylebyreea.com';

  /// Default country for checkout (ISO code).
  static const String defaultCountry = 'GB';

  /// Display order for sizes (anything not listed goes last).
  static const List<String> sizeOrder = [
    'xxs', 'xs', 's', 'm', 'l', 'xl', 'xxl', 'xxxl',
    '4', '6', '8', '10', '12', '14', '16', '18',
    '26', '28', '30', '32', '34', '36', '38', '40',
  ];

  /// Category ids/slugs highlighted on the home screen.
  static const List<String> homeCategorySlugs = [
    'men-tshirts', 'men-polos', 'coord-sets', 'women-jeans', 'women-tops', 'men-trousers',
  ];
}
