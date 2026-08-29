/// Bilingual (Amharic + English) strings per the microcopy matrix (Ã‚Â§8).
/// All copy lives here Ã¢â‚¬â€ zero hardcoded strings in widgets.
library;

enum LocaleId { en, am }

/// Immutable bilingual catalog. Constructed once per locale and provided via
/// [StringsProvider].
class Strings {
  final LocaleId locale;

  const Strings(this.locale);

  bool get isAm => locale == LocaleId.am;

  String t(String en, String am) => isAm ? am : en;

  // ---- microcopy matrix (Ã‚Â§8) ----
  String get orderCta => t('Place Order', 'Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Â Ã¡â€¹Â­Ã¡Ë†â€¹Ã¡Å Â©');
  String get customizePlatter => t('Customize Platter', 'Ã¡Å’Ë†Ã¡â€°Â Ã¡â€°Â³Ã¡â€¹Å½Ã¡Å â€¢ Ã¡â€¹Â«Ã¡â€¹ËœÃ¡Å’â€¹Ã¡Å’Â');
  String get sendGursha => t('Send Gursha', 'Ã¡Å’â€°Ã¡Ë†Â­Ã¡Ë†Â» Ã¡â€¹Â­Ã¡Ë†â€¹Ã¡Å Â©');
  String get addExtraInjera => t('Add Extra Injera', 'Ã¡â€°Â°Ã¡Å’Â¨Ã¡Ë†â€ºÃ¡Ë†Âª Ã¡Å Â¥Ã¡Å â€¢Ã¡Å’â‚¬Ã¡Ë†Â« Ã¡â€¹Â­Ã¡Å’Â¨Ã¡Ë†ÂÃ¡Ë†Â©');
  String get statusPlaced => t('Order Placed', 'Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹ÂÃ¡â€¹Å½ Ã¡â€°Â°Ã¡â€°â‚¬Ã¡â€°Â¥Ã¡Ë†Ë†Ã¡Å â€œÃ¡Ë†Â');
  String get statusPreparing => t('In the Kitchen', 'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥Ã¡â€¹Å½ Ã¡Å Â¥Ã¡â€¹Â¨Ã¡â€°Â°Ã¡â€¹ËœÃ¡Å’â€¹Ã¡Å’â‚¬ Ã¡Å ÂÃ¡â€¹Â');
  String get statusEnRoute => t('Rider En Route', 'Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¹ Ã¡â€°Â Ã¡Ë†ËœÃ¡Å â€¢Ã¡Å’Ë†Ã¡â€¹Âµ Ã¡Ë†â€¹Ã¡â€¹Â­ Ã¡Å ÂÃ¡â€¹Â');
  String get statusArrived => t('Arrived at Landmark', 'Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¹ Ã¡Ë†ÂÃ¡Ë†ÂÃ¡Å Â­Ã¡â€°Â± Ã¡â€°Â¦Ã¡â€°Â³ Ã¡â€¹Â°Ã¡Ë†Â­Ã¡Ë†Â·Ã¡Ë†Â');
  String get statusDelivered => t('Delivered', 'Ã¡â€°Â°Ã¡Ë†â€¹Ã¡Ë†ÂÃ¡ÂÂÃ¡Ë†Â');
  String get connectionLost => t('Connection Lost', 'Ã¡Å Â®Ã¡Å â€Ã¡Å Â­Ã¡Ë†Â½Ã¡Å â€¢ Ã¡â€°Â°Ã¡â€°â€¹Ã¡Ë†Â­Ã¡Å’Â§Ã¡Ë†Â');
  String get retry => t('Retry', 'Ã¡â€¹ÂµÃ¡Å’â€¹Ã¡Ë†Å¡ Ã¡â€¹Â­Ã¡Ë†Å¾Ã¡Å Â­Ã¡Ë†Â©');
  String get verifyingPayment => t('Verifying Payment', 'Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â«Ã¡â€¹Å½ Ã¡Å Â¥Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â  Ã¡Å ÂÃ¡â€¹Â');
  String get fastingTag => t('Fasting', 'Ã¡â€¹Â¨Ã¡Å’Â¾Ã¡Ë†Â');
  String get coffeeRun => t('Coffee Run', 'Ã¡â€¹Â¨Ã¡â€°Â¡Ã¡Å â€œ Ã¡Ë†Â°Ã¡â€¹â€œÃ¡â€°Âµ');
  String get dailySpecial => t('Top Choice', 'Ã¡â€¹Â¨Ã¡â€¹â€ºÃ¡Ë†Â¬ Ã¡Ë†ÂÃ¡â€¹Â©');
  String get enjoyMeal => t('Enjoy your meal', 'Ã¡Ë†ËœÃ¡Ë†ÂÃ¡Å Â«Ã¡Ë†Â Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥');

  // ---- search & filter (core feature) ----
  String get searchPlaceholder => t(
    'Search food, restaurants, categories, lifestylesÃ¢â‚¬Â¦',
    'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥Ã¡ÂÂ£ Ã¡Ë†Â¬Ã¡Ë†ÂµÃ¡â€°Â¶Ã¡Ë†Â«Ã¡Å â€¢Ã¡â€°ÂµÃ¡ÂÂ£ Ã¡Ë†ÂÃ¡â€¹ÂµÃ¡â€°Â¥Ã¡ÂÂ£ Ã¡â€¹Â¨Ã¡Å Â Ã¡Ë†ËœÃ¡Å’â€¹Ã¡Å’Ë†Ã¡â€°Â¥ Ã¡Å Â Ã¡â€¹Â­Ã¡Å ÂÃ¡â€°Âµ Ã¡â€¹Â­Ã¡ÂË†Ã¡Ë†ÂÃ¡Å’â€°Ã¢â‚¬Â¦',
  );
  String get openNow => t('Open Now', 'Ã¡Å Â Ã¡Ë†ÂÃ¡Å â€¢ Ã¡Å Â­Ã¡ÂÂÃ¡â€°Âµ');
  String get all => t('All', 'Ã¡Ë†ÂÃ¡Ë†â€°Ã¡Ë†Â');
  String get fasting => t('Ã¡Å’Â¾Ã¡Ë†Â', 'Ã¡â€¹Â¨Ã¡Å’Â¾Ã¡Ë†Â');
  String get halal => t('Halal', 'Ã¡Ë†Æ’Ã¡Ë†â€¹Ã¡Ë†Â');
  String get lifestyleTitle => t('Lifestyle', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡Ë†ËœÃ¡Å’â€¹Ã¡Å’Ë†Ã¡â€°Â¥ Ã¡Å Â Ã¡â€¹Â­Ã¡Å ÂÃ¡â€°Âµ');
  String get categoriesTitle => t('Categories', 'Ã¡Ë†ÂÃ¡â€¹ÂµÃ¡â€°Â¦Ã¡â€°Â½');
  String get restaurants => t('Restaurants', 'Ã¡Ë†Â¬Ã¡Ë†ÂµÃ¡â€°Â¶Ã¡Ë†Â«Ã¡Å â€¢Ã¡â€°Â¶Ã¡â€°Â½');
  String get menuItems => t('Menu items', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­');
  String get noResults => t('No results', 'Ã¡Ë†ÂÃ¡Å â€¢Ã¡Ë†Â Ã¡â€¹ÂÃ¡Å’Â¤Ã¡â€°Âµ Ã¡â€¹Â¨Ã¡Ë†Ë†Ã¡Ë†Â');
  String get tryClearFilters => t('Try clearing your search or filters', 'Ã¡Ë†â€ºÃ¡Å’Â£Ã¡Ë†ÂªÃ¡â€¹Â«Ã¡â€¹Å½Ã¡â€°Â½Ã¡Å â€¢ Ã¡â€¹Â«Ã¡Å’Â½Ã¡â€¹Â±');
  String get soldOut => t('Sold out', 'Ã¡â€°Â°Ã¡Ë†Â½Ã¡Å’Â§Ã¡Ë†Â');
  String get fastingModeActive => t('Fasting Mode Active', 'Ã¡â€¹Â¨Ã¡Å’Â¾Ã¡Ë†Â Ã¡â€°â‚¬Ã¡Å â€¢');
  String get showAll => t('Show all', 'Ã¡Ë†ÂÃ¡Ë†â€°Ã¡Å â€¢Ã¡Ë†Â Ã¡â€¹Â«Ã¡Ë†Â³Ã¡â€¹Â©');
  String get showFastingFriendly => t('Show fasting-friendly', 'Ã¡â€¹Â¨Ã¡Å’Â¾Ã¡Ë†Â Ã¡â€¹Ë†Ã¡â€¹Â³Ã¡Å’Æ’Ã¡â€¹Å  Ã¡â€¹Â«Ã¡Ë†Â³Ã¡â€¹Â©');
  String get resultsFor => t('Results for', 'Ã¡â€¹ÂÃ¡Å’Â¤Ã¡â€°Â¶Ã¡â€°Â½ Ã¡Ë†Ë†');
  String get open => t('Open', 'Ã¡Å Â­Ã¡ÂÂÃ¡â€°Âµ');
  String get closed => t('Closed', 'Ã¡â€¹ÂÃ¡Å’Â');
  String get orders => t('Orders', 'Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Å¾Ã¡â€°Â½');
  String get cart => t('Cart', 'Ã¡Å’Ë†Ã¡â€°Â Ã¡â€°Â³');
  String get more => t('More', 'Ã¡â€°Â°Ã¡Å’Â¨Ã¡Ë†â€ºÃ¡Ë†Âª');

  // ---- configurator / cart ----
  String get quantity => t('Quantity', 'Ã¡â€°Â¥Ã¡â€¹â€ºÃ¡â€°Âµ');
  String get injeraRolls => t('How many rolls of injera?', 'Ã¡Ë†ÂµÃ¡Å â€¢Ã¡â€°Âµ Ã¡Å Â¥Ã¡Å â€¢Ã¡Å’â‚¬Ã¡Ë†Â«?');
  String get addFor => t('Add for', 'Ã¡â€¹Â­Ã¡Å’Â¨Ã¡Ë†ÂÃ¡Ë†Â© Ã¡Ë†Ë†');
  String get spiceLevel => t('Spice level', 'Ã¡â€¹Â¨Ã¡â€°â€¦Ã¡Ë†ËœÃ¡Ë†Â Ã¡Ë†ËœÃ¡Å’Â Ã¡Å â€¢');
  String get injera => t('Injera', 'Ã¡Å Â¥Ã¡Å â€¢Ã¡Å’â‚¬Ã¡Ë†Â«');
  String get subtotal => t('Subtotal', 'Ã¡Å â€¢Ã¡â€¹â€˜Ã¡Ë†Âµ-Ã¡â€¹ÂµÃ¡Ë†ÂÃ¡Ë†Â­');
  String get deliveryFee => t('Delivery', 'Ã¡Ë†ËœÃ¡Ë†â€¹Ã¡Å ÂªÃ¡â€¹Â«');
  String get serviceFee => t('Service fee', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡Å’Ë†Ã¡Ë†ÂÃ¡Å’ÂÃ¡Ë†Å½Ã¡â€°Âµ Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â«');
  String get surge => t('Rain surge', 'Ã¡â€¹Â¨Ã¡â€¹ÂÃ¡Å â€œÃ¡â€°Â¥ Ã¡â€°Â°Ã¡Å’Â¨Ã¡Ë†â€ºÃ¡Ë†Âª');
  String get total => t('Total', 'Ã¡Å’Â Ã¡â€°â€¦Ã¡Ë†â€¹Ã¡Ë†â€¹');
  String get placeOrder => t('Place order', 'Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Â Ã¡â€¹Â­Ã¡Ë†â€¹Ã¡Å Â©');
  String get youSave => t('You save', 'Ã¡â€¹Â­Ã¡â€°â€ Ã¡Å’Â¥Ã¡â€°Â¡');
  String get whyThisFee => t('Why this fee?', 'Ã¡â€¹Â­Ã¡Ë†â€¦ Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡Ë†Ë†Ã¡Ë†ÂÃ¡Å â€¢?');
  String get deliveredOnFoot => t('Delivered on foot', 'Ã¡â€°Â Ã¡Å Â¥Ã¡Å’ÂÃ¡Ë†Â­ Ã¡â€°Â°Ã¡Ë†â€¹Ã¡Ë†ÂÃ¡ÂÂÃ¡Ë†Â');
  String get emptyCart => t('Your platter is empty', 'Ã¡Å’Ë†Ã¡â€°Â Ã¡â€°Â³Ã¡â€¹Å½ Ã¡â€°Â£Ã¡â€¹Â¶ Ã¡Å ÂÃ¡â€¹Â');
  String get browseFood => t('Browse food', 'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹Â­Ã¡Ë†ËœÃ¡Ë†ÂÃ¡Å Â¨Ã¡â€°Â±');
  String get deliveryBand => t('Delivery distance', 'Ã¡â€¹Â¨Ã¡Ë†â€ºÃ¡â€¹ÂµÃ¡Ë†Â¨Ã¡Ë†Âµ Ã¡Ë†Â­Ã¡â€°â‚¬Ã¡â€°Âµ');
  String get deliverTo => t('Deliver to', 'Ã¡â€¹Ë†Ã¡â€¹Â° Ã¡Ë†â€ºÃ¡â€¹ÂµÃ¡Ë†Â¨Ã¡Ë†Âµ');
  String get phone => t('Phone', 'Ã¡Ë†ÂµÃ¡Ë†ÂÃ¡Å Â­');
  String get subCity => t('Sub-city / Area', 'Ã¡Å â€¢Ã¡â€¹â€˜Ã¡Ë†Âµ Ã¡Å Â¨Ã¡â€°Â°Ã¡Ë†â€º');
  String get selectNeighborhood => t('Select neighborhood', 'Ã¡Ë†Â°Ã¡ÂË†Ã¡Ë†Â­ Ã¡â€¹Â­Ã¡Ë†ÂÃ¡Ë†Â¨Ã¡Å’Â¡');
  String get landmarkLabel => t('Nearby Landmark & Gate Details', 'Ã¡Ë†ÂÃ¡â€¹Â© Ã¡â€°Â¦Ã¡â€°Â³ Ã¡Å Â¥Ã¡Å â€œ Ã¡â€¹Â¨Ã¡â€°Â¤Ã¡â€°Âµ Ã¡Ë†ÂÃ¡Ë†ÂÃ¡Å Â­Ã¡â€°Âµ');
  String get landmarkPlaceholder =>
      t('e.g., Behind Total station, yellow building, green gate', 'Ã¡Ë†Ë†Ã¡Ë†ÂÃ¡Ë†Â³Ã¡Ë†Å’ Ã¡Å Â¨Ã¡â€°Â¶Ã¡â€°Â³Ã¡Ë†Â Ã¡Å’â‚¬Ã¡Ë†Â­Ã¡â€°Â£Ã¡ÂÂ£ Ã¡â€°Â¢Ã¡Å’Â« Ã¡ÂÅ½Ã¡â€°â€¦Ã¡ÂÂ£ Ã¡Å Â Ã¡Ë†Â¨Ã¡Å â€¢Ã¡Å’â€œÃ¡â€¹Â´ Ã¡â€°Â Ã¡Ë†Â­');
  String get paymentMethod => t('Payment method', 'Ã¡â€¹Â¨Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡â€¹ËœÃ¡â€¹Â´');
  String get orderCheckout => t('Checkout', 'Ã¡Ë†ËœÃ¡Å Â­Ã¡ÂË†Ã¡â€¹Â«');
  String get chapa => t('Chapa / Telebirr / CBE', 'Ã¡â€°Â»Ã¡Ââ€œ / Ã¡â€°Â´Ã¡Ë†Å’Ã¡â€°Â¥Ã¡Ë†Â­');
  String get chapaSub => t('Cards, Telebirr, CBE Birr', 'Ã¡Å Â«Ã¡Ë†Â­Ã¡â€¹ÂµÃ¡ÂÂ£ Ã¡â€°Â´Ã¡Ë†Å’Ã¡â€°Â¥Ã¡Ë†Â­Ã¡ÂÂ£ Ã¡Ë†Â²Ã¡â€°Â¢Ã¡Å Â¢');
  String get cod => t('Cash on Delivery', 'Ã¡â€°Â Ã¡Å Â Ã¡â€°â€¦Ã¡Ë†Â«Ã¡â€°Â¢ Ã¡â€°Â Ã¡Å’Â¥Ã¡Ë†Â¬ Ã¡Å’Ë†Ã¡Å â€¢Ã¡â€¹ËœÃ¡â€°Â¥');
  String get codNote => t('Courier float cap 1,500 ETB Ã‚Â· settle in 24 h', 'Ã¡â€¹Â¨Ã¡Å’Â­Ã¡Å ÂÃ¡â€°Âµ Ã¡Å’Ë†Ã¡Å â€¢Ã¡â€¹ËœÃ¡â€°Â¥ Ã¡Å’Ë†Ã¡â€¹Â°Ã¡â€°Â¥ 1,500 Ã¡â€°Â¥Ã¡Ë†Â­');
  String get sefer => t('Sefer / hub', 'Ã¡Ë†Â°Ã¡ÂË†Ã¡Ë†Â­');
  String get verified => t('VERIFIED', 'Ã¡Ââ‚¬Ã¡â€¹ÂµÃ¡â€°â€¹Ã¡Ë†Â');
  String get codPending => t('COD pending', 'Ã¡â€°Â Ã¡Å’Â¥Ã¡Ë†Â¬ Ã¡Å’Ë†Ã¡Å â€¢Ã¡â€¹ËœÃ¡â€°Â¥ Ã¡â€°Â Ã¡Ë†ËœÃ¡Å’Â Ã¡â€°Â Ã¡â€°â€¦ Ã¡Ë†â€¹Ã¡â€¹Â­');
  String get pending => t('Pending', 'Ã¡â€°Â Ã¡Ë†ËœÃ¡Å’Â Ã¡â€°Â Ã¡â€°â€¦ Ã¡Ë†â€¹Ã¡â€¹Â­');
  String get smsEscalated => t('Merchant notified by SMS ticket Ã¢â‚¬â€ escalating to voice call', 'Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´Ã¡â€¹Â Ã¡â€°Â SMS Ã¡â€°Â°Ã¡Å ÂÃ¡Å’ÂÃ¡Ë†Â®Ã¡â€°Â³Ã¡Ë†Â');
  String get ackNow => t('Merchant ack in', 'Ã¡â€¹Â¨Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´ Ã¡Ë†â€ºÃ¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â«');
  String get landmark => t('Landmark', 'Ã¡Ë†ÂÃ¡â€¹Â© Ã¡â€°Â¦Ã¡â€°Â³');
  String get plusCode => t('Plus Code', 'Ã¡Å Â®Ã¡â€¹Âµ');
  String get items => t('Items', 'Ã¡â€¹â€¢Ã¡â€°Æ’Ã¡â€¹Å½Ã¡â€°Â½');
  String get noOrders => t('No orders yet', 'Ã¡Å’Ë†Ã¡Å â€œ Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Â Ã¡â€¹Â¨Ã¡Ë†Ë†Ã¡Ë†Â');
  String get continueBtn => t('Continue', 'Ã¡â€°â‚¬Ã¡Å’Â¥Ã¡Ë†Â');

  // ---- role dashboards (Ã‚Â§5.8Ã¢â‚¬â€œ5.12) ----
  String get driverTitle => t('Driver Dashboard', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â½ Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get economicsCard => t('Economics', 'Ã¡Å Â¢Ã¡Å Â®Ã¡Å â€“Ã¡Ë†Å¡Ã¡Å Â­Ã¡Ë†Âµ');
  String get costPerKm => t('Cost / km', 'Ã¡â€¹â€¹Ã¡Å’â€¹ / Ã¡Å Âª.Ã¡Ë†Å“.');
  String get effectiveRange => t('Effective range', 'Ã¡â€¹ÂÃ¡Å’Â¤Ã¡â€°Â³Ã¡Ë†â€º Ã¡Ë†Â­Ã¡â€°â‚¬Ã¡â€°Âµ');
  String get keeperShare => t('Keeper share', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¹ Ã¡â€¹ÂµÃ¡Ë†Â­Ã¡Ë†Â»');
  String get walletCard => t('Wallet', 'Ã¡â€°Â¦Ã¡Ë†Â­Ã¡Ë†Â³');
  String get balance => t('Balance', 'Ã¡â€°â‚¬Ã¡Ë†Âª');
  String get radius => t('Radius', 'ራዲየስ');
  String get earningToday => t('Earning today', 'ዛሬ እያገኘሁ');
  String get inactive => t('Inactive', 'እንቅስቃሴ የለም');
  String get codFloat => t('COD float used', 'Ã¡â€¹Â¨Ã¡Å’Â¥Ã¡Ë†Â¬ Ã¡Å’Ë†Ã¡Å â€¢Ã¡â€¹ËœÃ¡â€°Â¥ Ã¡â€°Â°Ã¡Å’Â Ã¡â€°â€¦Ã¡Ë†Â¶');
  String get codBlockedNote => t('COD orders blocked: float at cap. Reconcile before taking cash orders.', 'Ã¡â€¹Â¨Ã¡Å’Â¥Ã¡Ë†Â¬ Ã¡Å’Ë†Ã¡Å â€¢Ã¡â€¹ËœÃ¡â€°Â¥ Ã¡Å Â¥Ã¡â€°Æ’ Ã¡â€¹Â¨Ã¡Ë†Ë†Ã¡Ë†Â');
  String get payoutDue => t('Payout due', 'Ã¡â€¹Â¨Ã¡Ë†Å¡Ã¡Å Â¨Ã¡ÂË†Ã¡Ë†Â');
  String get curfewNote => t('Evening rider restrictions Ã¢â‚¬â€ motorbike offers suppressed, delivery by car/foot.', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Ë†Â½Ã¡â€°Âµ Ã¡Å’Ë†Ã¡â€¹Â°Ã¡â€°Â¦Ã¡â€°Â½');
  String get liveOffers => t('Live offers', 'Ã¡â€°â‚¬Ã¡Å’Â¥Ã¡â€°Â³ Ã¡â€°â€¦Ã¡Å â€œÃ¡Ë†Â¾Ã¡â€°Â½');
  String get activeOrder => t('Active order', 'Ã¡Å â€¢Ã¡â€°Â Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Â');
  String get noOffers => t('No live offers right now', 'Ã¡Å Â Ã¡Ë†ÂÃ¡Å â€¢ Ã¡Ë†ÂÃ¡Å â€¢Ã¡Ë†Â Ã¡â€°â€¦Ã¡Å â€œÃ¡Ë†Â½ Ã¡â€¹Â¨Ã¡Ë†Ë†Ã¡Ë†Â');
  String get fuelBurn => t('Fuel burn', 'Ã¡Å ÂÃ¡â€¹Â³Ã¡Å’â€¦');
  String get platformSubsidy => t('Platform subsidy', 'Ã¡â€¹Â¨Ã¡Ââ€¢Ã¡Ë†â€¹Ã¡â€°ÂµÃ¡ÂÅ½Ã¡Ë†Â­Ã¡Ë†Â Ã¡â€¹ÂµÃ¡Å’â€¹Ã¡ÂÂ');
  String get netEarnings => t('Net earnings', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Å’Â£Ã¡Ë†Â« Ã¡Å’Ë†Ã¡â€°Â¢');
  String get accept => t('Accept', 'Ã¡â€°Â°Ã¡â€°â‚¬Ã¡â€°Â Ã¡Ë†Â');
  String get assignedOrdersPending => t('Assigned orders appear here Ã¢â‚¬â€ deliver with POD photo + PIN.', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Â°Ã¡Å’Â¡ Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Å¾Ã¡â€°Â½');
  String get proofOfDelivery => t('Proof of delivery', 'Ã¡â€¹Â¨Ã¡Ë†â€ºÃ¡â€¹ÂµÃ¡Ë†Â¨Ã¡Ë†Âµ Ã¡Ë†â€ºÃ¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â«');

  // ---- merchant ----
  String get merchantTitle => t('Merchant Console', 'Ã¡â€¹Â¨Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´ Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get liveQueue => t('Live order queue', 'Ã¡â€°â‚¬Ã¡Å’Â¥Ã¡â€°Â³ Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Â Ã¡â€¹Ë†Ã¡Ë†Â¨Ã¡Ââ€¹');
  String get merchantAck => t('Merchant ack', 'Ã¡â€¹Â¨Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´ Ã¡Ë†â€ºÃ¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â«');
  String get acceptOrder => t('Accept', 'Ã¡â€°Â°Ã¡â€°â‚¬Ã¡â€°Â Ã¡Ë†Â');
  String get declineOrder => t('Decline', 'Ã¡Å Â Ã¡Å â€¢Ã¡â€°â‚¬Ã¡â€°Â Ã¡Ë†ÂÃ¡Ë†Â');
  String get markPreparing => t('Mark Preparing', 'Ã¡â€°Â Ã¡â€¹ÂÃ¡Å’ÂÃ¡Å’â€¦Ã¡â€°Âµ Ã¡Ë†ÂÃ¡Ë†ÂÃ¡Å Â­Ã¡â€°Âµ');
  String get menuAvailability => t('Menu availability', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­ Ã¡Ë†ËœÃ¡Å’Ë†Ã¡Å ËœÃ¡â€°Âµ');
  String get pendingActions => t('Queued actions', 'á‹¨á‰°á‹«á‹™ áŠ¥áˆ­áˆáŒƒá‹Žá‰½');
  String get uploadMenuPhoto => t('Upload menu photo (OCR)', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­ Ã¡ÂÅ½Ã¡â€°Â¶');
  String get inStock => t('Today', 'Ã¡Å Â­Ã¡ÂÂÃ¡â€°Âµ');
  String get outOfStock => t('Sold out', 'Ã¡â€°Â°Ã¡Ë†Å¸Ã¡Å’Â¦');

  // ---- admin ----
  String get adminTitle => t('Admin Panel', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡Ë†ÂµÃ¡â€°Â°Ã¡â€¹Â³Ã¡â€¹Â³Ã¡Ë†Âª Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get ordersToday => t('Orders today', 'Ã¡â€¹Â¨Ã¡â€¹â€ºÃ¡Ë†Â¬ Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Å¾Ã¡â€°Â½');
  String get gmv => t('GMV', 'GMV');
  String get activeCouriers => t('Active couriers', 'Ã¡Å â€¢Ã¡â€°Â Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¾Ã¡â€°Â½');
  String get pricingEditor => t('Pricing engine editor', 'Ã¡â€¹Â¨Ã¡â€¹â€¹Ã¡Å’â€¹ Ã¡Å Â Ã¡Ë†Â­Ã¡â€°Â³Ã¡â€¹â€™');

  // ---- admin (cont.) / ceo / foot ----
  String get rainMode => t('Rain Mode', 'Ã¡â€¹Â¨Ã¡â€¹ÂÃ¡Å â€œÃ¡â€°Â¥ Ã¡Ë†ÂÃ¡Å ÂÃ¡â€°Â³');
  String get fastingOverride => t('Fasting override', 'Ã¡â€¹Â¨Ã¡Å’Â¾Ã¡Ë†Â Ã¡Ë†Ë†Ã¡â€¹ÂÃ¡Å’Â¥');
  String get footFunnel => t('Foot-carrier funnel', 'Ã¡â€¹Â¨Ã¡Å Â¥Ã¡Å’ÂÃ¡Ë†Â­ Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â½ Ã¡Ë†ËœÃ¡Ë†ÂµÃ¡Ë†ËœÃ¡Ë†Â­');
  String get merchantApplications => t('Merchant applications', 'Ã¡â€¹Â¨Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´ Ã¡Ë†â€ºÃ¡Ë†ËœÃ¡Ë†ÂÃ¡Å Â¨Ã¡â€°Â»Ã¡â€¹Å½Ã¡â€°Â½');
  String get ocrQueue => t('OCR verification queue', 'OCR Ã¡Ë†â€ºÃ¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â«');
  String get verify => t('Verify', 'Ã¡Å Â Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’ÂÃ¡Å’Â¥');
  String get approve => t('Approve', 'Ã¡â€¹Â«Ã¡Å’Â½Ã¡â€¹ÂµÃ¡â€°Â');
  String get reject => t('Reject', 'Ã¡â€¹ÂÃ¡â€¹ÂµÃ¡â€°â€¦');
  String get otpLog => t('OTP log', 'OTP Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
  String get providerStatus => t('Channel provider status', 'Ã¡â€¹Â¨Ã¡â€°Â»Ã¡Å â€œÃ¡Ë†Â Ã¡Ë†ÂÃ¡Å â€Ã¡â€°Â³');
  String get deliver => t('Deliver', 'Ã¡Å Â Ã¡Ë†Â³Ã¡Ë†ÂÃ¡ÂÂ');
  String get cancel => t('Cancel', 'Ã¡Ë†Â°Ã¡Ë†Â­Ã¡â€¹Â');
  String get ceoTitle => t('CEO Dashboard', 'Ã¡â€¹Â¨Ã¡â€°Â£Ã¡Ë†Ë†Ã¡â€°Â¤Ã¡â€°Âµ Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get inflationEngine => t('Inflation engine', 'Ã¡â€¹Â¨Ã¡â€¹â€¹Ã¡Å’â€¹ Ã¡Å’ÂÃ¡Ë†Â½Ã¡â€°Â Ã¡â€°Âµ');
  String get unitEconomics => t('Unit economics (4 km)', 'Ã¡Å Â¢Ã¡Å Â®Ã¡Å â€“Ã¡Ë†Å¡Ã¡Å Â­Ã¡Ë†Âµ');
  String get footNetwork => t('Foot-carrier network', 'Ã¡â€¹Â¨Ã¡Å Â¥Ã¡Å’ÂÃ¡Ë†Â­ Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â½ Ã¡Ë†ËœÃ¡Ë†Â¨Ã¡â€°Â¥');
  String get disputes => t('Disputes', 'Ã¡Å Â­Ã¡Ë†Â­Ã¡Å Â­Ã¡Ë†Â®Ã¡â€°Â½');
  String get promotions => t('Promotions', 'Ã¡Ë†â€ºÃ¡Ë†ÂµÃ¡â€°Â°Ã¡â€¹â€¹Ã¡â€¹Ë†Ã¡â€°â€šÃ¡â€¹Â«Ã¡â€¹Å½Ã¡â€°Â½');
  String get resolve => t('Resolve', 'Ã¡ÂÂÃ¡â€°Â³');
  String get recruits => t('Recruit', 'Ã¡â€°â‚¬Ã¡Å’Â¥Ã¡Ë†Â­');
  String get subsidyGuarantee =>
      t('Drivers always net above fuel Ã¢â‚¬â€ platform subsidizes the gap.', 'Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¾Ã¡â€°Â½ Ã¡Ë†ÂÃ¡Ë†ÂÃ¡Å’Å Ã¡â€¹Å“ Ã¡Å Â¨Ã¡Å ÂÃ¡â€¹Â³Ã¡Å’â€¦ Ã¡â€°Â Ã¡Ë†â€¹Ã¡â€¹Â­ Ã¡â€¹Â«Ã¡Å’Ë†Ã¡Å â€ºÃ¡Ë†â€°');
  String get footCarrierTitle => t('Foot Carrier', 'Ã¡â€¹Â¨Ã¡Å Â¥Ã¡Å’ÂÃ¡Ë†Â­ Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â½');
  String get carrierWelcome => t('Start earning today', 'Ã¡â€¹â€ºÃ¡Ë†Â¬ Ã¡Ë†ËœÃ¡Ë†ÂµÃ¡Ë†Â«Ã¡â€°Âµ Ã¡â€¹Â­Ã¡Å’â‚¬Ã¡Ë†ÂÃ¡Ë†Â©');
  String get orientationChecklist => t('1-minute orientation checklist', 'Ã¡â€¹Â¨Ã¡â€¹ÂÃ¡Å’ÂÃ¡Å’â€¦Ã¡â€°Âµ Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­');
  String get carrierEarnings => t('Earnings', 'Ã¡Å’Ë†Ã¡â€°Â¢');
  String get bonusesLedger => t('Bonuses ledger', 'Ã¡â€¹Â¨Ã¡Å’â€°Ã¡Ë†Â­Ã¡Ë†Â» Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
  String get tripHistory => t('Trip history', 'Ã¡â€¹Â¨Ã¡Å’â€°Ã¡â€¹Å¾ Ã¡â€°Â³Ã¡Ë†ÂªÃ¡Å Â­');
  String get markDelivered => t('Mark delivered', 'Ã¡â€°Â°Ã¡Ë†â€¹Ã¡Ë†ÂÃ¡ÂÂÃ¡Ë†Â');
  String get carrierKeep95 => t('Foot carriers keep 95% of fees', 'Ã¡â€¹Â¨Ã¡Å Â¥Ã¡Å’ÂÃ¡Ë†Â­ Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¾Ã¡â€°Â½ 95% Ã¡â€¹Â«Ã¡Å’Ë†Ã¡Å â€ºÃ¡Ë†â€°');
  String get platformFlags => t('Platform flags', 'Ã¡â€¹Â¨Ã¡Ââ€¢Ã¡Ë†â€¹Ã¡â€°ÂµÃ¡ÂÅ½Ã¡Ë†Â­Ã¡Ë†Â Ã¡Ë†â€ºÃ¡â€°Â¥Ã¡Ë†ÂªÃ¡â€¹Â«');
  String get demoWatermark => t('DEMO', 'Ã¡Ë†â€ºÃ¡Ë†Â³Ã¡â€¹Â«');
  String get liveOrders => t('Live orders', 'Ã¡â€°â‚¬Ã¡Å’Â¥Ã¡â€°Â³ Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹Å¾Ã¡â€°Â½');
  String get scheduledFor => t('Scheduled for', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡â€¹Â«Ã¡â€¹ËœÃ¡Ë†Ë†Ã¡â€°Âµ');
  String get funded => t('Prepaid', 'Ã¡â€°â€¦Ã¡â€¹ÂµÃ¡Ë†Å¡Ã¡â€¹Â«');

  // ---- payments / verified receipt / refunds / disputes ----
  String get verifiedReceipt => t('VERIFIED PAYMENT RECEIPT', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â  Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡â€¹Â°Ã¡Ë†Â¨Ã¡Ë†Â°Ã¡Å Â');
  String get scanForDriver => t('Scan this QR at the restaurant', 'Ã¡â€¹Â­Ã¡Ë†â€¦Ã¡Å â€¢ QR Ã¡â€¹Â«Ã¡Ë†ÂµÃ¡â€°Æ’Ã¡Å â„¢');
  String get payWithChapa => t('Pay with Chapa hosted checkout', 'Ã¡â€°Â Ã¡â€°Â»Ã¡Ââ€œ Ã¡â€¹Â­Ã¡Å Â­Ã¡ÂË†Ã¡Ë†â€°');
  String get refundTracker => t('Refund tracker', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†ËœÃ¡Ë†â€¹Ã¡Ë†Â½ Ã¡Å Â­Ã¡â€°ÂµÃ¡â€°ÂµÃ¡Ë†Â');
  String get refundInitiated => t('Refund initiated', 'Ã¡â€°Â°Ã¡Å’â‚¬Ã¡Ë†ÂÃ¡Ë†Â¯Ã¡Ë†Â');
  String get refundProcessing => t('Processing', 'Ã¡â€°Â Ã¡Ë†â€šÃ¡â€¹Â°Ã¡â€°Âµ');
  String get refundReturned => t('Returned to your Telebirr/CBE', 'Ã¡â€°Â°Ã¡Ë†ËœÃ¡Ë†ÂÃ¡Ë†Â·Ã¡Ë†Â');
  String get refundRef => t('Refund ref', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†ËœÃ¡Ë†â€¹Ã¡Ë†Â½ Ã¡Å Â®Ã¡â€¹Âµ');
  String get neverReceived => t('I never received this', 'Ã¡Å Â Ã¡Ë†ÂÃ¡â€°Â°Ã¡â€°â‚¬Ã¡â€°Â Ã¡Ë†ÂÃ¡Å Â©Ã¡â€°ÂµÃ¡Ë†Â');
  String get overcharged => t('I was overcharged', 'Ã¡â€°Â Ã¡Ë†â€¹Ã¡â€¹Â­ Ã¡â€°Â°Ã¡Å Â¨Ã¡ÂÂÃ¡â€¹Â¬Ã¡â€¹Â«Ã¡Ë†Ë†Ã¡Ë†Â');
  String get disputeTicket => t('Dispute ticket opened', 'Ã¡Å Â­Ã¡Ë†Â­Ã¡Å Â­Ã¡Ë†Â­ Ã¡â€°Â°Ã¡Å Â¨Ã¡ÂÂÃ¡â€°Â·Ã¡Ë†Â');
  String get orderBySms => t('Order by SMS', 'Ã¡â€°Â SMS Ã¡â€¹Â­Ã¡â€¹ËœÃ¡â€¹â„¢');
  String get voiceOrderLine => t('Voice order line', 'Ã¡â€¹Â¨Ã¡â€¹ÂµÃ¡Ë†ÂÃ¡Ââ€¦ Ã¡Ë†â€ºÃ¡â€¹ËœÃ¡â€¹Â£');
  String get smsBridgeNote =>
      t('No signal? Compose an SMS order instead.', 'Ã¡Ë†Â²Ã¡Å’ÂÃ¡Å â€œÃ¡Ë†Â Ã¡â€¹Â¨Ã¡Ë†Ë†Ã¡Ë†Â?');
  String get honestEta => t('Honest ETA', 'Ã¡Å Â¥Ã¡â€¹ÂÃ¡Å ÂÃ¡â€°Â°Ã¡Å â€º Ã¡Å’Å Ã¡â€¹Å“');
  String get etaReduced => t('Evening rider restrictions Ã¢â‚¬â€ delivered by car.', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Ë†Â½Ã¡â€°Âµ Ã¡Ë†â€ºÃ¡â€¹ÂµÃ¡Ë†Â¨Ã¡Ë†Âµ');
  String get cancelFullRefund => t('Cancel with full refund', 'Ã¡â€¹Â­Ã¡Ë†Â°Ã¡Ë†Â­Ã¡â€¹â„¢ Ã¡Å Â¥Ã¡Å â€œ Ã¡Ë†â„¢Ã¡Ë†â€° Ã¡â€°Â°Ã¡Ë†ËœÃ¡Ë†â€¹Ã¡Ë†Â½');
  String get feeBreakdown => t('Why this fee?', 'Ã¡â€¹Â­Ã¡Ë†â€¦ Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡Ë†Ë†Ã¡Ë†ÂÃ¡Å â€¢?');
  String get deposit => t('Deposit', 'Ã¡â€°Â°Ã¡â€°â‚¬Ã¡Ë†â€ºÃ¡Å’Â­');
  String get split => t('Split', 'Ã¡Ë†ÂµÃ¡â€°Â¥Ã¡Ë†Â­');
  String get pickupMode => t('Pickup', 'Ã¡Ë†â€ºÃ¡Å â€¢Ã¡Ë†Â³Ã¡â€°Âµ');
  String get meetPoint => t('Meet-point handoff', 'Ã¡Ë†ÂµÃ¡Ë†ÂÃ¡Ë†ÂÃ¡Å ÂÃ¡â€°Âµ Ã¡â€°Â¦Ã¡â€°Â³');
  String get scheduleAhead => t('Schedule ahead', 'Ã¡â€°â‚¬Ã¡â€¹ÂµÃ¡Ë†ËœÃ¡â€¹Â Ã¡â€¹Â«Ã¡â€¹ÂÃ¡â€¹â„¢');
  String get loyaltyStamps => t('Loyalty stamps', 'Ã¡â€¹Â¨Ã¡â€°Â³Ã¡Ë†â€ºÃ¡Å ÂÃ¡Å ÂÃ¡â€°Âµ Ã¡Ë†â€ºÃ¡Ë†â€¦Ã¡â€°Â°Ã¡Ë†Â');
  String get perHead => t('Per person', 'Ã¡â€°Â Ã¡Å Â Ã¡Å â€¢Ã¡â€¹Âµ Ã¡Ë†Â°Ã¡â€¹Â');
  String get freeDelivery => t('free delivery', 'Ã¡Å ÂÃ¡Å’Â» Ã¡Ë†â€ºÃ¡â€¹ÂµÃ¡Ë†Â¨Ã¡Ë†Âµ');
  String get rateYourExperience => t('How was your order?', 'Ã¡â€°ÂµÃ¡â€¹â€¢Ã¡â€¹â€ºÃ¡â€¹ÂÃ¡â€¹Å½ Ã¡Å Â¥Ã¡Å â€¢Ã¡â€¹Â´Ã¡â€°Âµ Ã¡Å ÂÃ¡â€°Â Ã¡Ë†Â­?');
  String get rateRestaurant => t('Rate restaurant', 'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€°Â¤Ã¡â€°Â±Ã¡Å â€¢ Ã¡â€¹Â­Ã¡Ë†ÂµÃ¡Å’Â¥Ã¡Ë†Â©');
  String get rateCourier => t('Rate courier', 'Ã¡Å Â Ã¡â€°Â Ã¡Ë†â€¹Ã¡Ë†Â¹Ã¡Å â€¢ Ã¡â€¹Â­Ã¡Ë†ÂµÃ¡Å’Â¥Ã¡Ë†Â©');
  String get thanks => t('Thanks for your feedback!', 'Ã¡Ë†Ë†Ã¡Å Â Ã¡Ë†ÂµÃ¡â€°Â°Ã¡â€¹Â«Ã¡â€¹Â¨Ã¡â€°ÂµÃ¡â€¹Å½ Ã¡Å Â¥Ã¡Å â€œÃ¡Ë†ËœÃ¡Ë†Â°Ã¡Å’ÂÃ¡Å â€œÃ¡Ë†Ë†Ã¡Å â€¢!');
  String get tier => t('Tier', 'Ã¡â€¹Â°Ã¡Ë†Â¨Ã¡Å’Æ’');
  String get nextTier => t('Next tier', 'Ã¡â€°â‚¬Ã¡Å’Â£Ã¡â€¹Â­ Ã¡â€¹Â°Ã¡Ë†Â¨Ã¡Å’Æ’');
  String get crewLeader => t('Leader nominated by admin', 'Ã¡â€°Â Ã¡Å Â Ã¡Ë†ÂµÃ¡â€°Â°Ã¡â€¹Â³Ã¡â€¹Â³Ã¡Ë†Âª Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Â¾Ã¡Ë†â„¢');
  String get sponsorPay => t('Sponsor a meal', 'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹Â«Ã¡â€°Â Ã¡Ë†Â¨Ã¡Å Â­Ã¡â€°Â±');
  String get homeFed => t('Meal paid Ã¢â‚¬â€ your family will be notified!', 'Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€°Â°Ã¡Å Â¨Ã¡ÂÂÃ¡Ë†ÂÃ¡Ë†Â Ã¢â‚¬â€ Ã¡â€°Â¤Ã¡â€°Â°Ã¡Ë†Â°Ã¡â€°Â¥Ã¡â€¹Å½ Ã¡â€¹Â­Ã¡Å ÂÃ¡Å’Ë†Ã¡Ë†Â«Ã¡Ë†Â!');
  String get supportConsole => t('Support Console', 'Ã¡â€¹Â¨Ã¡â€¹ÂµÃ¡Å’â€¹Ã¡ÂÂ Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get financeConsole => t('Finance Console', 'Ã¡â€¹Â¨Ã¡Ââ€¹Ã¡â€¹Â­Ã¡Å â€œÃ¡Å â€¢Ã¡Ë†Âµ Ã¡Ë†Â°Ã¡Ë†Å’Ã¡â€¹Â³');
  String get misconductReports => t('Misconduct reports', 'Ã¡â€¹Â¨Ã¡Ë†ÂµÃ¡Å ÂÃ¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â£Ã¡Ë†Â­ Ã¡â€¹ËœÃ¡Å’Ë†Ã¡â€°Â£Ã¡â€¹Å½Ã¡â€°Â½');
  String get strikeLedger => t('Strike ledger', 'Ã¡â€¹Â¨Ã¡â€°â€¦Ã¡Å’Â£Ã¡â€°Âµ Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
  String get refundQueue => t('Refund queue', 'Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†ËœÃ¡Ë†â€¹Ã¡Ë†Â½ Ã¡â€¹Ë†Ã¡Ë†Â¨Ã¡Ââ€¹');
  String get payoutBatches => t('Payout batches', 'Ã¡â€¹Â¨Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡Ë†ÂµÃ¡â€°Â¥Ã¡Ë†ÂµÃ¡â€°Â¦Ã¡â€°Â½');
  String get ledger => t('Ledger', 'Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
  String get ledgerZeroNote => t('Ledger must balance to zero.', 'Ã¡Ë†â€™Ã¡Ë†Â³Ã¡â€°Â¥ 0 Ã¡Ë†ËœÃ¡Ë†â€ Ã¡Å â€¢ Ã¡Å Â Ã¡Ë†Ë†Ã¡â€°Â Ã¡â€°Âµ');
  String get reconcileNow => t('Reconcile', 'Ã¡Ë†â€ºÃ¡Ë†ÂµÃ¡â€°Â³Ã¡Ë†Â¨Ã¡â€°â€¦');
  String get validate => t('Validate', 'Ã¡Å Â Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’ÂÃ¡Å’Â¥');
  String get trueCost => t('Sort by total cost', 'Ã¡â€°Â Ã¡Å’Â Ã¡â€°â€¦Ã¡Ë†â€¹Ã¡Ë†â€¹ Ã¡â€¹â€¹Ã¡Å’â€¹ Ã¡â€¹Â°Ã¡Ë†Â­Ã¡â€¹ÂµÃ¡Ë†Â­');
  String get digitalPaymentDiscount => t('Digital payment discount', 'Ã¡â€¹Â¨Ã¡â€¹Â²Ã¡Å’â€šÃ¡â€°Â³Ã¡Ë†Â Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡â€°â€¦Ã¡Å â€œÃ¡Ë†Â½');
  String get dataSaver => t('Data-saver mode', 'Ã¡Ë†ËœÃ¡Ë†Â¨Ã¡Å’Æ’ Ã¡â€°â€ Ã¡Å’Â£Ã¡â€°Â¢');
  String get gursha => t('Gursha gifting', 'Ã¡Å’â€°Ã¡Ë†Â­Ã¡Ë†Â»');
  String get shareGebeta => t('Share Gebeta', 'Ã¡Å’Ë†Ã¡â€°Â Ã¡â€°Â³ Ã¡â€¹Â«Ã¡Å’â€¹Ã¡Ë†Â©');
  String get referralCode => t('Referral code', 'Ã¡â€¹Â¨Ã¡Ë†â€ºÃ¡Å’â€¹Ã¡Ë†Â«Ã¡â€°Âµ Ã¡Å Â®Ã¡â€¹Âµ');
  String get referFriend => t('Refer a friend Ã¢â‚¬â€ both get 50 ETB', 'Ã¡â€¹Ë†Ã¡â€¹Â³Ã¡Å’â€¦ Ã¡â€¹Â­Ã¡Å’â€¹Ã¡Ë†Â©');
  String get nominateRestaurant => t('Nominate a missing restaurant', 'Ã¡â€¹Â«Ã¡Ë†ÂÃ¡â€°Â°Ã¡Ë†ËœÃ¡â€¹ËœÃ¡Å’Ë†Ã¡â€°Â  Ã¡Ë†Â¬Ã¡Ë†ÂµÃ¡â€°Â¶Ã¡Ë†Â«Ã¡Å â€¢Ã¡â€°Âµ Ã¡â€¹Â­Ã¡Å’Â Ã¡â€°ÂÃ¡Ë†â„¢');
  String get walletTopup => t('Wallet prepay (+5% bonus)', 'Ã¡â€¹Â¨Ã¡â€°Â¦Ã¡Ë†Â­Ã¡Ë†Â³ Ã¡â€°â€¦Ã¡â€¹ÂµÃ¡Ë†Ëœ-Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« (+5%)');
  String get lunchPass => t('Weekly lunch pass (5 meals)', 'Ã¡Ë†Â³Ã¡Ë†ÂÃ¡Å â€¢Ã¡â€°Â³Ã¡â€¹Å  Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Ë†Â³ Ã¡Ââ€œÃ¡Ë†Âµ');
  String get shareOnTelegram => t('Share on Telegram', 'Ã¡â€°Â Ã¡â€°Â´Ã¡Ë†Å’Ã¡Å’ÂÃ¡Ë†Â«Ã¡Ë†Â Ã¡â€¹Â«Ã¡Å’â€¹Ã¡Ë†Â©');
  String get sendWarmMeal => t('Send a warm meal home to Addis', 'Ã¡Ë†Å¾Ã¡â€°â€¦ Ã¡â€¹Â«Ã¡Ë†Ë† Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹Â­Ã¡Ë†â€¹Ã¡Å Â©');
  String get joinRound => t('Join the Round', 'Ã¡â€¹â„¢Ã¡Ë†Â­ Ã¡â€¹Â­Ã¡â€°â‚¬Ã¡Ë†â€¹Ã¡â€°â‚¬Ã¡Ë†â€°');
  String get neighborsJoined => t('neighbors joined', 'Ã¡Å’Å½Ã¡Ë†Â¨Ã¡â€°Â¤Ã¡â€°Â¶Ã¡â€°Â½ Ã¡â€°Â°Ã¡â€°â‚¬Ã¡Ë†â€¹Ã¡â€°â€¦Ã¡Ë†Ë†Ã¡â€¹â€¹Ã¡Ë†Â');
  String get yourFeeNow => t('your fee is now', 'Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â«Ã¡â€¹Å½ Ã¡Å Â Ã¡Ë†ÂÃ¡Å â€¢');
  String get moreNeighborSaved => t('1 more neighbor = Ã¢Ë†â€™8 ETB', 'Ã¡â€°Â°Ã¡Å’Â¨Ã¡Ë†â€ºÃ¡Ë†Âª Ã¡Å’Å½Ã¡Ë†Â¨Ã¡â€°Â¤Ã¡â€°Âµ = Ã¢Ë†â€™8 Ã¡â€°Â¥Ã¡Ë†Â­');
  String get roundsArriveWindow => t('Batched orders arrive within the round window.', 'Ã¡â€¹â„¢Ã¡Ë†Â­ Ã¡Å’Å Ã¡â€¹Å“ Ã¡â€¹ÂÃ¡Ë†ÂµÃ¡Å’Â¥ Ã¡â€¹Â­Ã¡â€¹Â°Ã¡Ë†Â­Ã¡Ë†Â³Ã¡Ë†Â');
  String get priceLockNote => t('Locked total Ã¢â‚¬â€ pay exactly this. Collecting more is grounds for removal.', 'Ã¡â€°â€¹Ã¡Ë†Å¡ Ã¡Å’Â Ã¡â€°â€¦Ã¡Ë†â€¹Ã¡Ë†â€¹ Ã¢â‚¬â€ Ã¡â€¹Â­Ã¡Ë†â€¦Ã¡Å â€¢ Ã¡â€°Â Ã¡â€°ÂµÃ¡Å Â­Ã¡Å Â­Ã¡Ë†Â Ã¡â€¹Â­Ã¡Å Â­Ã¡ÂË†Ã¡Ë†â€°');
  String get deliveryGuaranteeNote => t('On-time guaranteed: >30 min late Ã¢â€ â€™ delivery fee refunded automatically.', 'Ã¡â€¹ÂÃ¡Ë†Â­Ã¡Ë†Âµ Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’Ë†Ã¡Å’Â Ã¡ÂÂ¡ Ã¡Å Â¨30 Ã¡â€¹Â°Ã¡â€°â€šÃ¡â€°Æ’ Ã¡Å Â«Ã¡Ë†Ë†Ã¡ÂË† Ã¢â€ â€™ Ã¡â€¹Â¨Ã¡Ë†â€ºÃ¡Å’â€œÃ¡Å’â€œÃ¡â€¹Â£ Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡â€°Â Ã¡Ë†Â«Ã¡Ë†Â± Ã¡â€¹Â­Ã¡Ë†ËœÃ¡Ë†Ë†Ã¡Ë†Â³Ã¡Ë†ÂÃ¡ÂÂ¢');

  /// Ã‚Â§11.3 driver-side price lock: identical locked total to collect.
  String collectExactly(int totalEtb) => t(
    'Collect exactly $totalEtb ETB Ã¢â‚¬â€ collecting more is grounds for removal.',
    'Ã¡â€°Â Ã¡â€°ÂµÃ¡Å Â­Ã¡Å Â­Ã¡Ë†Â $totalEtb Ã¡â€°Â¥Ã¡Ë†Â­ Ã¡â€¹Â­Ã¡Ë†Â°Ã¡â€°Â¥Ã¡Ë†ÂµÃ¡â€°Â¡ Ã¢â‚¬â€ Ã¡â€°Â Ã¡Ë†â€¹Ã¡â€¹Â­ Ã¡Ë†ËœÃ¡Ë†Â°Ã¡â€°Â¥Ã¡Ë†Â°Ã¡â€°Â¥ Ã¡Ë†ËœÃ¡â€¹Ë†Ã¡Å’Ë†Ã¡â€¹ÂµÃ¡Å â€¢ Ã¡â€¹Â«Ã¡Ë†ËœÃ¡Å’Â£Ã¡Ë†Â',
  );
  String get shareToSaveNames => t('Order from local kitchens, delivered with care Ã¢â‚¬â€ share to save on your next ride.', 'Ã¡Ë†Å¾Ã¡â€°â€¦ Ã¡â€¹Â«Ã¡Ë†Ë† Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹Â­Ã¡Ë†â€¹Ã¡Å Â©');

  // ---- field agent (Ã‚Â§12) ----
  String get fieldAgentTitle => t('Field Agent', 'Ã¡â€¹Â¨Ã¡Ë†ËœÃ¡Ë†ÂµÃ¡Å Â­ Ã¡â€¹Ë†Ã¡Å ÂªÃ¡Ë†Â');
  String get fieldNearby => t('Nearby draft merchants (GPS-sorted)', 'Ã¡â€¹Â¨Ã¡â€°â€¦Ã¡Ë†Â­Ã¡â€°Â¥ Ã¡Å ÂÃ¡Å’â€¹Ã¡â€¹Â´Ã¡â€¹Å½Ã¡â€°Â½');
  String get fieldCapture => t('Capture & verify (< 2 min)', 'Ã¡â€¹Â­Ã¡â€¹Â«Ã¡â€¹â„¢Ã¡Å â€œ Ã¡â€¹Â«Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’ÂÃ¡Å’Â¡');
  String get fieldTally => t('Agent tally & ledger', 'Ã¡â€¹Â¨Ã¡Å Â Ã¡Ë†ÂµÃ¡â€°Â°Ã¡â€¹Â³Ã¡â€¹Â°Ã¡Ë†Â­ Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
  String get photoMenu => t('Photograph the paper menu', 'Ã¡â€¹Â¨Ã¡Ë†ÂÃ¡Å’ÂÃ¡â€°Â¥ Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­ Ã¡â€¹Â«Ã¡Å â€¢Ã¡Ë†Â±');
  String get photoStorefront => t('Photograph the storefront', 'Ã¡Ë†Â±Ã¡â€°ÂÃ¡Å â€¢ Ã¡â€¹Â«Ã¡Å â€¢Ã¡Ë†Â±');
  String get confirmPin => t('Confirm / correct GPS pin', 'Ã¡Ë†â€ºÃ¡Å â€¢Ã¡Å ÂªÃ¡â€¹Â«Ã¡â€¹ÂÃ¡Å â€¢ Ã¡â€¹Â«Ã¡Ë†Â¨Ã¡Å’â€¹Ã¡Å’ÂÃ¡Å’Â¡');
  String get paymentDetails => t('Capture Telebirr/CBE + phone', 'Ã¡â€¹Â¨Ã¡Å Â­Ã¡ÂÂÃ¡â€¹Â« Ã¡â€¹ÂÃ¡Ë†Â­Ã¡â€¹ÂÃ¡Ë†Â­');
  String get verifyMerchant => t('Submit verification', 'Ã¡â€¹Â«Ã¡Ë†ÂµÃ¡Å’Ë†Ã¡â€°Â¡');
  String get agentLedger => t('Earnings ledger', 'Ã¡â€¹Â¨Ã¡Å’Ë†Ã¡â€°Â¢ Ã¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¥');
}
