/// Bilingual (Amharic + English) strings per the microcopy matrix (Â§8).
/// All copy lives here â€” zero hardcoded strings in widgets.
library;

enum LocaleId { en, am }

/// Immutable bilingual catalog. Constructed once per locale and provided via
/// [StringsProvider].
class Strings {
  final LocaleId locale;

  const Strings(this.locale);

  bool get isAm => locale == LocaleId.am;

  String t(String en, String am) => isAm ? am : en;

  // ---- microcopy matrix (Â§8) ----
  String get orderCta => t('Place Order', 'á‰µá‹•á‹›á‹ á‹­áˆ‹áŠ©');
  String get customizePlatter => t('Customize Platter', 'áŒˆá‰ á‰³á‹ŽáŠ• á‹«á‹˜áŒ‹áŒ');
  String get sendGursha => t('Send Gursha', 'áŒ‰áˆ­áˆ» á‹­áˆ‹áŠ©');
  String get addExtraInjera => t('Add Extra Injera', 'á‰°áŒ¨áˆ›áˆª áŠ¥áŠ•áŒ€áˆ« á‹­áŒ¨áˆáˆ©');
  String get statusPlaced => t('Order Placed', 'á‰µá‹•á‹›á‹á‹Ž á‰°á‰€á‰¥áˆˆáŠ“áˆ');
  String get statusPreparing => t('In the Kitchen', 'áˆáŒá‰¥á‹Ž áŠ¥á‹¨á‰°á‹˜áŒ‹áŒ€ áŠá‹');
  String get statusEnRoute => t('Rider En Route', 'áŠ á‰ áˆ‹áˆ¹ á‰ áˆ˜áŠ•áŒˆá‹µ áˆ‹á‹­ áŠá‹');
  String get statusArrived => t('Arrived at Landmark', 'áŠ á‰ áˆ‹áˆ¹ áˆáˆáŠ­á‰± á‰¦á‰³ á‹°áˆ­áˆ·áˆ');
  String get statusDelivered => t('Delivered', 'á‰°áˆ‹áˆááˆ');
  String get connectionLost => t('Connection Lost', 'áŠ®áŠ”áŠ­áˆ½áŠ• á‰°á‰‹áˆ­áŒ§áˆ');
  String get retry => t('Retry', 'á‹µáŒ‹áˆš á‹­áˆžáŠ­áˆ©');
  String get verifyingPayment => t('Verifying Payment', 'áŠ­áá‹«á‹Ž áŠ¥á‹¨á‰°áˆ¨áŒ‹áŒˆáŒ  áŠá‹');
  String get fastingTag => t('Fasting', 'á‹¨áŒ¾áˆ');
  String get coffeeRun => t('Coffee Run', 'á‹¨á‰¡áŠ“ áˆ°á‹“á‰µ');
  String get dailySpecial => t('Top Choice', 'á‹¨á‹›áˆ¬ áˆá‹©');
  String get enjoyMeal => t('Enjoy your meal', 'áˆ˜áˆáŠ«áˆ áˆáŒá‰¥');

  // ---- search & filter (core feature) ----
  String get searchPlaceholder => t(
    'Search food, restaurants, categories, lifestylesâ€¦',
    'áˆáŒá‰¥á£ áˆ¬áˆµá‰¶áˆ«áŠ•á‰µá£ áˆá‹µá‰¥á£ á‹¨áŠ áˆ˜áŒ‹áŒˆá‰¥ áŠ á‹­áŠá‰µ á‹­áˆáˆáŒ‰â€¦',
  );
  String get openNow => t('Open Now', 'áŠ áˆáŠ• áŠ­áá‰µ');
  String get all => t('All', 'áˆáˆ‰áˆ');
  String get fasting => t('áŒ¾áˆ', 'á‹¨áŒ¾áˆ');
  String get halal => t('Halal', 'áˆƒáˆ‹áˆ');
  String get lifestyleTitle => t('Lifestyle', 'á‹¨áŠ áˆ˜áŒ‹áŒˆá‰¥ áŠ á‹­áŠá‰µ');
  String get categoriesTitle => t('Categories', 'áˆá‹µá‰¦á‰½');
  String get restaurants => t('Restaurants', 'áˆ¬áˆµá‰¶áˆ«áŠ•á‰¶á‰½');
  String get menuItems => t('Menu items', 'á‹¨áˆáŒá‰¥ á‹áˆ­á‹áˆ­');
  String get noResults => t('No results', 'áˆáŠ•áˆ á‹áŒ¤á‰µ á‹¨áˆˆáˆ');
  String get tryClearFilters => t('Try clearing your search or filters', 'áˆ›áŒ£áˆªá‹«á‹Žá‰½áŠ• á‹«áŒ½á‹±');
  String get soldOut => t('Sold out', 'á‰°áˆ½áŒ§áˆ');
  String get fastingModeActive => t('Fasting Mode Active', 'á‹¨áŒ¾áˆ á‰€áŠ•');
  String get showAll => t('Show all', 'áˆáˆ‰áŠ•áˆ á‹«áˆ³á‹©');
  String get showFastingFriendly => t('Show fasting-friendly', 'á‹¨áŒ¾áˆ á‹ˆá‹³áŒƒá‹Š á‹«áˆ³á‹©');
  String get resultsFor => t('Results for', 'á‹áŒ¤á‰¶á‰½ áˆˆ');
  String get open => t('Open', 'áŠ­áá‰µ');
  String get closed => t('Closed', 'á‹áŒ');
  String get orders => t('Orders', 'á‰µá‹•á‹›á‹žá‰½');
  String get cart => t('Cart', 'áŒˆá‰ á‰³');
  String get more => t('More', 'á‰°áŒ¨áˆ›áˆª');

  // ---- configurator / cart ----
  String get quantity => t('Quantity', 'á‰¥á‹›á‰µ');
  String get injeraRolls => t('How many rolls of injera?', 'áˆµáŠ•á‰µ áŠ¥áŠ•áŒ€áˆ«?');
  String get addFor => t('Add for', 'á‹­áŒ¨áˆáˆ© áˆˆ');
  String get spiceLevel => t('Spice level', 'á‹¨á‰…áˆ˜áˆ áˆ˜áŒ áŠ•');
  String get injera => t('Injera', 'áŠ¥áŠ•áŒ€áˆ«');
  String get subtotal => t('Subtotal', 'áŠ•á‹‘áˆµ-á‹µáˆáˆ­');
  String get deliveryFee => t('Delivery', 'áˆ˜áˆ‹áŠªá‹«');
  String get serviceFee => t('Service fee', 'á‹¨áŠ áŒˆáˆáŒáˆŽá‰µ áŠ­áá‹«');
  String get surge => t('Rain surge', 'á‹¨á‹áŠ“á‰¥ á‰°áŒ¨áˆ›áˆª');
  String get total => t('Total', 'áŒ á‰…áˆ‹áˆ‹');
  String get placeOrder => t('Place order', 'á‰µá‹•á‹›á‹ á‹­áˆ‹áŠ©');
  String get youSave => t('You save', 'á‹­á‰†áŒ¥á‰¡');
  String get whyThisFee => t('Why this fee?', 'á‹­áˆ… áŠ­áá‹« áˆˆáˆáŠ•?');
  String get deliveredOnFoot => t('Delivered on foot', 'á‰ áŠ¥áŒáˆ­ á‰°áˆ‹áˆááˆ');
  String get emptyCart => t('Your platter is empty', 'áŒˆá‰ á‰³á‹Ž á‰£á‹¶ áŠá‹');
  String get browseFood => t('Browse food', 'áˆáŒá‰¥ á‹­áˆ˜áˆáŠ¨á‰±');
  String get deliveryBand => t('Delivery distance', 'á‹¨áˆ›á‹µáˆ¨áˆµ áˆ­á‰€á‰µ');
  String get deliverTo => t('Deliver to', 'á‹ˆá‹° áˆ›á‹µáˆ¨áˆµ');
  String get phone => t('Phone', 'áˆµáˆáŠ­');
  String get subCity => t('Sub-city / Area', 'áŠ•á‹‘áˆµ áŠ¨á‰°áˆ›');
  String get selectNeighborhood => t('Select neighborhood', 'áˆ°áˆáˆ­ á‹­áˆáˆ¨áŒ¡');
  String get landmarkLabel => t('Nearby Landmark & Gate Details', 'áˆá‹© á‰¦á‰³ áŠ¥áŠ“ á‹¨á‰¤á‰µ áˆáˆáŠ­á‰µ');
  String get landmarkPlaceholder =>
      t('e.g., Behind Total station, yellow building, green gate', 'áˆˆáˆáˆ³áˆŒ áŠ¨á‰¶á‰³áˆ áŒ€áˆ­á‰£á£ á‰¢áŒ« áŽá‰…á£ áŠ áˆ¨áŠ•áŒ“á‹´ á‰ áˆ­');
  String get paymentMethod => t('Payment method', 'á‹¨áŠ­áá‹« á‹˜á‹´');
  String get orderCheckout => t('Checkout', 'áˆ˜áŠ­áˆá‹«');
  String get chapa => t('Chapa / Telebirr / CBE', 'á‰»á“ / á‰´áˆŒá‰¥áˆ­');
  String get chapaSub => t('Cards, Telebirr, CBE Birr', 'áŠ«áˆ­á‹µá£ á‰´áˆŒá‰¥áˆ­á£ áˆ²á‰¢áŠ¢');
  String get cod => t('Cash on Delivery', 'á‰ áŠ á‰…áˆ«á‰¢ á‰ áŒ¥áˆ¬ áŒˆáŠ•á‹˜á‰¥');
  String get codNote => t('Courier float cap 1,500 ETB Â· settle in 24 h', 'á‹¨áŒ­áŠá‰µ áŒˆáŠ•á‹˜á‰¥ áŒˆá‹°á‰¥ 1,500 á‰¥áˆ­');
  String get sefer => t('Sefer / hub', 'áˆ°áˆáˆ­');
  String get verified => t('VERIFIED', 'á€á‹µá‰‹áˆ');
  String get codPending => t('COD pending', 'á‰ áŒ¥áˆ¬ áŒˆáŠ•á‹˜á‰¥ á‰ áˆ˜áŒ á‰ á‰… áˆ‹á‹­');
  String get pending => t('Pending', 'á‰ áˆ˜áŒ á‰ á‰… áˆ‹á‹­');
  String get smsEscalated => t('Merchant notified by SMS ticket â€” escalating to voice call', 'áŠáŒ‹á‹´á‹ á‰ SMS á‰°áŠáŒáˆ®á‰³áˆ');
  String get ackNow => t('Merchant ack in', 'á‹¨áŠáŒ‹á‹´ áˆ›áˆ¨áŒ‹áŒˆáŒ«');
  String get landmark => t('Landmark', 'áˆá‹© á‰¦á‰³');
  String get plusCode => t('Plus Code', 'áŠ®á‹µ');
  String get items => t('Items', 'á‹•á‰ƒá‹Žá‰½');
  String get noOrders => t('No orders yet', 'áŒˆáŠ“ á‰µá‹•á‹›á‹ á‹¨áˆˆáˆ');
  String get continueBtn => t('Continue', 'á‰€áŒ¥áˆ');

  // ---- role dashboards (Â§5.8â€“5.12) ----
  String get driverTitle => t('Driver Dashboard', 'á‹¨áŠ á‰ áˆ‹áˆ½ áˆ°áˆŒá‹³');
  String get economicsCard => t('Economics', 'áŠ¢áŠ®áŠ–áˆšáŠ­áˆµ');
  String get costPerKm => t('Cost / km', 'á‹‹áŒ‹ / áŠª.áˆœ.');
  String get effectiveRange => t('Effective range', 'á‹áŒ¤á‰³áˆ› áˆ­á‰€á‰µ');
  String get keeperShare => t('Keeper share', 'á‹¨áŠ á‰ áˆ‹áˆ¹ á‹µáˆ­áˆ»');
  String get walletCard => t('Wallet', 'á‰¦áˆ­áˆ³');
  String get balance => t('Balance', 'á‰€áˆª');
  String get codFloat => t('COD float used', 'á‹¨áŒ¥áˆ¬ áŒˆáŠ•á‹˜á‰¥ á‰°áŒ á‰…áˆ¶');
  String get codBlockedNote => t('COD orders blocked: float at cap. Reconcile before taking cash orders.', 'á‹¨áŒ¥áˆ¬ áŒˆáŠ•á‹˜á‰¥ áŠ¥á‰ƒ á‹¨áˆˆáˆ');
  String get payoutDue => t('Payout due', 'á‹¨áˆšáŠ¨áˆáˆ');
  String get curfewNote => t('Evening rider restrictions â€” motorbike offers suppressed, delivery by car/foot.', 'á‹¨áˆáˆ½á‰µ áŒˆá‹°á‰¦á‰½');
  String get liveOffers => t('Live offers', 'á‰€áŒ¥á‰³ á‰…áŠ“áˆ¾á‰½');
  String get activeOrder => t('Active order', 'áŠ•á‰ á‰µá‹•á‹›á‹');
  String get noOffers => t('No live offers right now', 'áŠ áˆáŠ• áˆáŠ•áˆ á‰…áŠ“áˆ½ á‹¨áˆˆáˆ');
  String get fuelBurn => t('Fuel burn', 'áŠá‹³áŒ…');
  String get platformSubsidy => t('Platform subsidy', 'á‹¨á•áˆ‹á‰µáŽáˆ­áˆ á‹µáŒ‹á');
  String get netEarnings => t('Net earnings', 'á‹¨á‰°áŒ£áˆ« áŒˆá‰¢');
  String get accept => t('Accept', 'á‰°á‰€á‰ áˆ');
  String get assignedOrdersPending => t('Assigned orders appear here â€” deliver with POD photo + PIN.', 'á‹¨á‰°áˆ°áŒ¡ á‰µá‹•á‹›á‹žá‰½');
  String get proofOfDelivery => t('Proof of delivery', 'á‹¨áˆ›á‹µáˆ¨áˆµ áˆ›áˆ¨áŒ‹áŒˆáŒ«');

  // ---- merchant ----
  String get merchantTitle => t('Merchant Console', 'á‹¨áŠáŒ‹á‹´ áˆ°áˆŒá‹³');
  String get liveQueue => t('Live order queue', 'á‰€áŒ¥á‰³ á‰µá‹•á‹›á‹ á‹ˆáˆ¨á‹');
  String get merchantAck => t('Merchant ack', 'á‹¨áŠáŒ‹á‹´ áˆ›áˆ¨áŒ‹áŒˆáŒ«');
  String get acceptOrder => t('Accept', 'á‰°á‰€á‰ áˆ');
  String get declineOrder => t('Decline', 'áŠ áŠ•á‰€á‰ áˆáˆ');
  String get markPreparing => t('Mark Preparing', 'á‰ á‹áŒáŒ…á‰µ áˆáˆáŠ­á‰µ');
  String get menuAvailability => t('Menu availability', 'á‹¨áˆáŒá‰¥ á‹áˆ­á‹áˆ­ áˆ˜áŒˆáŠ˜á‰µ');
  String get pendingActions => t('Queued actions', 'የተያዙ እርምጃዎች');
  String get uploadMenuPhoto => t('Upload menu photo (OCR)', 'á‹¨áˆáŒá‰¥ á‹áˆ­á‹áˆ­ áŽá‰¶');
  String get inStock => t('Today', 'áŠ­áá‰µ');
  String get outOfStock => t('Sold out', 'á‰°áˆŸáŒ¦');

  // ---- admin ----
  String get adminTitle => t('Admin Panel', 'á‹¨áŠ áˆµá‰°á‹³á‹³áˆª áˆ°áˆŒá‹³');
  String get ordersToday => t('Orders today', 'á‹¨á‹›áˆ¬ á‰µá‹•á‹›á‹žá‰½');
  String get gmv => t('GMV', 'GMV');
  String get activeCouriers => t('Active couriers', 'áŠ•á‰ áŠ á‰ áˆ‹áˆ¾á‰½');
  String get pricingEditor => t('Pricing engine editor', 'á‹¨á‹‹áŒ‹ áŠ áˆ­á‰³á‹’');

  // ---- admin (cont.) / ceo / foot ----
  String get rainMode => t('Rain Mode', 'á‹¨á‹áŠ“á‰¥ áˆáŠá‰³');
  String get fastingOverride => t('Fasting override', 'á‹¨áŒ¾áˆ áˆˆá‹áŒ¥');
  String get footFunnel => t('Foot-carrier funnel', 'á‹¨áŠ¥áŒáˆ­ áŠ á‰ áˆ‹áˆ½ áˆ˜áˆµáˆ˜áˆ­');
  String get merchantApplications => t('Merchant applications', 'á‹¨áŠáŒ‹á‹´ áˆ›áˆ˜áˆáŠ¨á‰»á‹Žá‰½');
  String get ocrQueue => t('OCR verification queue', 'OCR áˆ›áˆ¨áŒ‹áŒˆáŒ«');
  String get verify => t('Verify', 'áŠ áˆ¨áŒ‹áŒáŒ¥');
  String get approve => t('Approve', 'á‹«áŒ½á‹µá‰');
  String get reject => t('Reject', 'á‹á‹µá‰…');
  String get otpLog => t('OTP log', 'OTP áˆ˜á‹áŒˆá‰¥');
  String get providerStatus => t('Channel provider status', 'á‹¨á‰»áŠ“áˆ áˆáŠ”á‰³');
  String get deliver => t('Deliver', 'áŠ áˆ³áˆá');
  String get cancel => t('Cancel', 'áˆ°áˆ­á‹');
  String get ceoTitle => t('CEO Dashboard', 'á‹¨á‰£áˆˆá‰¤á‰µ áˆ°áˆŒá‹³');
  String get inflationEngine => t('Inflation engine', 'á‹¨á‹‹áŒ‹ áŒáˆ½á‰ á‰µ');
  String get unitEconomics => t('Unit economics (4 km)', 'áŠ¢áŠ®áŠ–áˆšáŠ­áˆµ');
  String get footNetwork => t('Foot-carrier network', 'á‹¨áŠ¥áŒáˆ­ áŠ á‰ áˆ‹áˆ½ áˆ˜áˆ¨á‰¥');
  String get disputes => t('Disputes', 'áŠ­áˆ­áŠ­áˆ®á‰½');
  String get promotions => t('Promotions', 'áˆ›áˆµá‰°á‹‹á‹ˆá‰‚á‹«á‹Žá‰½');
  String get resolve => t('Resolve', 'áá‰³');
  String get recruits => t('Recruit', 'á‰€áŒ¥áˆ­');
  String get subsidyGuarantee =>
      t('Drivers always net above fuel â€” platform subsidizes the gap.', 'áŠ á‰ áˆ‹áˆ¾á‰½ áˆáˆáŒŠá‹œ áŠ¨áŠá‹³áŒ… á‰ áˆ‹á‹­ á‹«áŒˆáŠ›áˆ‰');
  String get footCarrierTitle => t('Foot Carrier', 'á‹¨áŠ¥áŒáˆ­ áŠ á‰ áˆ‹áˆ½');
  String get carrierWelcome => t('Start earning today', 'á‹›áˆ¬ áˆ˜áˆµáˆ«á‰µ á‹­áŒ€áˆáˆ©');
  String get orientationChecklist => t('1-minute orientation checklist', 'á‹¨á‹áŒáŒ…á‰µ á‹áˆ­á‹áˆ­');
  String get carrierEarnings => t('Earnings', 'áŒˆá‰¢');
  String get bonusesLedger => t('Bonuses ledger', 'á‹¨áŒ‰áˆ­áˆ» áˆ˜á‹áŒˆá‰¥');
  String get tripHistory => t('Trip history', 'á‹¨áŒ‰á‹ž á‰³áˆªáŠ­');
  String get markDelivered => t('Mark delivered', 'á‰°áˆ‹áˆááˆ');
  String get carrierKeep95 => t('Foot carriers keep 95% of fees', 'á‹¨áŠ¥áŒáˆ­ áŠ á‰ áˆ‹áˆ¾á‰½ 95% á‹«áŒˆáŠ›áˆ‰');
  String get platformFlags => t('Platform flags', 'á‹¨á•áˆ‹á‰µáŽáˆ­áˆ áˆ›á‰¥áˆªá‹«');
  String get demoWatermark => t('DEMO', 'áˆ›áˆ³á‹«');
  String get liveOrders => t('Live orders', 'á‰€áŒ¥á‰³ á‰µá‹•á‹›á‹žá‰½');
  String get scheduledFor => t('Scheduled for', 'á‹¨á‰°á‹«á‹˜áˆˆá‰µ');
  String get funded => t('Prepaid', 'á‰…á‹µáˆšá‹«');

  // ---- payments / verified receipt / refunds / disputes ----
  String get verifiedReceipt => t('VERIFIED PAYMENT RECEIPT', 'á‹¨á‰°áˆ¨áŒ‹áŒˆáŒ  áŠ­áá‹« á‹°áˆ¨áˆ°áŠ');
  String get scanForDriver => t('Scan this QR at the restaurant', 'á‹­áˆ…áŠ• QR á‹«áˆµá‰ƒáŠ™');
  String get payWithChapa => t('Pay with Chapa hosted checkout', 'á‰ á‰»á“ á‹­áŠ­áˆáˆ‰');
  String get refundTracker => t('Refund tracker', 'á‹¨á‰°áˆ˜áˆ‹áˆ½ áŠ­á‰µá‰µáˆ');
  String get refundInitiated => t('Refund initiated', 'á‰°áŒ€áˆáˆ¯áˆ');
  String get refundProcessing => t('Processing', 'á‰ áˆ‚á‹°á‰µ');
  String get refundReturned => t('Returned to your Telebirr/CBE', 'á‰°áˆ˜áˆáˆ·áˆ');
  String get refundRef => t('Refund ref', 'á‹¨á‰°áˆ˜áˆ‹áˆ½ áŠ®á‹µ');
  String get neverReceived => t('I never received this', 'áŠ áˆá‰°á‰€á‰ áˆáŠ©á‰µáˆ');
  String get overcharged => t('I was overcharged', 'á‰ áˆ‹á‹­ á‰°áŠ¨áá‹¬á‹«áˆˆáˆ');
  String get disputeTicket => t('Dispute ticket opened', 'áŠ­áˆ­áŠ­áˆ­ á‰°áŠ¨áá‰·áˆ');
  String get orderBySms => t('Order by SMS', 'á‰ SMS á‹­á‹˜á‹™');
  String get voiceOrderLine => t('Voice order line', 'á‹¨á‹µáˆá… áˆ›á‹˜á‹£');
  String get smsBridgeNote =>
      t('No signal? Compose an SMS order instead.', 'áˆ²áŒáŠ“áˆ á‹¨áˆˆáˆ?');
  String get honestEta => t('Honest ETA', 'áŠ¥á‹áŠá‰°áŠ› áŒŠá‹œ');
  String get etaReduced => t('Evening rider restrictions â€” delivered by car.', 'á‹¨áˆáˆ½á‰µ áˆ›á‹µáˆ¨áˆµ');
  String get cancelFullRefund => t('Cancel with full refund', 'á‹­áˆ°áˆ­á‹™ áŠ¥áŠ“ áˆ™áˆ‰ á‰°áˆ˜áˆ‹áˆ½');
  String get feeBreakdown => t('Why this fee?', 'á‹­áˆ… áŠ­áá‹« áˆˆáˆáŠ•?');
  String get deposit => t('Deposit', 'á‰°á‰€áˆ›áŒ­');
  String get split => t('Split', 'áˆµá‰¥áˆ­');
  String get pickupMode => t('Pickup', 'áˆ›áŠ•áˆ³á‰µ');
  String get meetPoint => t('Meet-point handoff', 'áˆµáˆáˆáŠá‰µ á‰¦á‰³');
  String get scheduleAhead => t('Schedule ahead', 'á‰€á‹µáˆ˜á‹ á‹«á‹á‹™');
  String get loyaltyStamps => t('Loyalty stamps', 'á‹¨á‰³áˆ›áŠáŠá‰µ áˆ›áˆ…á‰°áˆ');
  String get perHead => t('Per person', 'á‰ áŠ áŠ•á‹µ áˆ°á‹');
  String get freeDelivery => t('free delivery', 'áŠáŒ» áˆ›á‹µáˆ¨áˆµ');
  String get rateYourExperience => t('How was your order?', 'á‰µá‹•á‹›á‹á‹Ž áŠ¥áŠ•á‹´á‰µ áŠá‰ áˆ­?');
  String get rateRestaurant => t('Rate restaurant', 'áˆáŒá‰¥ á‰¤á‰±áŠ• á‹­áˆµáŒ¥áˆ©');
  String get rateCourier => t('Rate courier', 'áŠ á‰ áˆ‹áˆ¹áŠ• á‹­áˆµáŒ¥áˆ©');
  String get thanks => t('Thanks for your feedback!', 'áˆˆáŠ áˆµá‰°á‹«á‹¨á‰µá‹Ž áŠ¥áŠ“áˆ˜áˆ°áŒáŠ“áˆˆáŠ•!');
  String get tier => t('Tier', 'á‹°áˆ¨áŒƒ');
  String get nextTier => t('Next tier', 'á‰€áŒ£á‹­ á‹°áˆ¨áŒƒ');
  String get crewLeader => t('Leader nominated by admin', 'á‰ áŠ áˆµá‰°á‹³á‹³áˆª á‹¨á‰°áˆ¾áˆ™');
  String get sponsorPay => t('Sponsor a meal', 'áˆáŒá‰¥ á‹«á‰ áˆ¨áŠ­á‰±');
  String get homeFed => t('Meal paid â€” your family will be notified!', 'áˆáŒá‰¥ á‰°áŠ¨ááˆáˆ â€” á‰¤á‰°áˆ°á‰¥á‹Ž á‹­áŠáŒˆáˆ«áˆ!');
  String get supportConsole => t('Support Console', 'á‹¨á‹µáŒ‹á áˆ°áˆŒá‹³');
  String get financeConsole => t('Finance Console', 'á‹¨á‹á‹­áŠ“áŠ•áˆµ áˆ°áˆŒá‹³');
  String get misconductReports => t('Misconduct reports', 'á‹¨áˆµáŠáˆáŒá‰£áˆ­ á‹˜áŒˆá‰£á‹Žá‰½');
  String get strikeLedger => t('Strike ledger', 'á‹¨á‰…áŒ£á‰µ áˆ˜á‹áŒˆá‰¥');
  String get refundQueue => t('Refund queue', 'á‹¨á‰°áˆ˜áˆ‹áˆ½ á‹ˆáˆ¨á‹');
  String get payoutBatches => t('Payout batches', 'á‹¨áŠ­áá‹« áˆµá‰¥áˆµá‰¦á‰½');
  String get ledger => t('Ledger', 'áˆ˜á‹áŒˆá‰¥');
  String get ledgerZeroNote => t('Ledger must balance to zero.', 'áˆ’áˆ³á‰¥ 0 áˆ˜áˆ†áŠ• áŠ áˆˆá‰ á‰µ');
  String get reconcileNow => t('Reconcile', 'áˆ›áˆµá‰³áˆ¨á‰…');
  String get validate => t('Validate', 'áŠ áˆ¨áŒ‹áŒáŒ¥');
  String get trueCost => t('Sort by total cost', 'á‰ áŒ á‰…áˆ‹áˆ‹ á‹‹áŒ‹ á‹°áˆ­á‹µáˆ­');
  String get digitalPaymentDiscount => t('Digital payment discount', 'á‹¨á‹²áŒ‚á‰³áˆ áŠ­áá‹« á‰…áŠ“áˆ½');
  String get dataSaver => t('Data-saver mode', 'áˆ˜áˆ¨áŒƒ á‰†áŒ£á‰¢');
  String get gursha => t('Gursha gifting', 'áŒ‰áˆ­áˆ»');
  String get shareGebeta => t('Share Gebeta', 'áŒˆá‰ á‰³ á‹«áŒ‹áˆ©');
  String get referralCode => t('Referral code', 'á‹¨áˆ›áŒ‹áˆ«á‰µ áŠ®á‹µ');
  String get referFriend => t('Refer a friend â€” both get 50 ETB', 'á‹ˆá‹³áŒ… á‹­áŒ‹áˆ©');
  String get nominateRestaurant => t('Nominate a missing restaurant', 'á‹«áˆá‰°áˆ˜á‹˜áŒˆá‰  áˆ¬áˆµá‰¶áˆ«áŠ•á‰µ á‹­áŒ á‰áˆ™');
  String get walletTopup => t('Wallet prepay (+5% bonus)', 'á‹¨á‰¦áˆ­áˆ³ á‰…á‹µáˆ˜-áŠ­áá‹« (+5%)');
  String get lunchPass => t('Weekly lunch pass (5 meals)', 'áˆ³áˆáŠ•á‰³á‹Š á‹¨áˆáˆ³ á“áˆµ');
  String get shareOnTelegram => t('Share on Telegram', 'á‰ á‰´áˆŒáŒáˆ«áˆ á‹«áŒ‹áˆ©');
  String get sendWarmMeal => t('Send a warm meal home to Addis', 'áˆžá‰… á‹«áˆˆ áˆáŒá‰¥ á‹­áˆ‹áŠ©');
  String get joinRound => t('Join the Round', 'á‹™áˆ­ á‹­á‰€áˆ‹á‰€áˆ‰');
  String get neighborsJoined => t('neighbors joined', 'áŒŽáˆ¨á‰¤á‰¶á‰½ á‰°á‰€áˆ‹á‰…áˆˆá‹‹áˆ');
  String get yourFeeNow => t('your fee is now', 'áŠ­áá‹«á‹Ž áŠ áˆáŠ•');
  String get moreNeighborSaved => t('1 more neighbor = âˆ’8 ETB', 'á‰°áŒ¨áˆ›áˆª áŒŽáˆ¨á‰¤á‰µ = âˆ’8 á‰¥áˆ­');
  String get roundsArriveWindow => t('Batched orders arrive within the round window.', 'á‹™áˆ­ áŒŠá‹œ á‹áˆµáŒ¥ á‹­á‹°áˆ­áˆ³áˆ');
  String get priceLockNote => t('Locked total â€” pay exactly this. Collecting more is grounds for removal.', 'á‰‹áˆš áŒ á‰…áˆ‹áˆ‹ â€” á‹­áˆ…áŠ• á‰ á‰µáŠ­áŠ­áˆ á‹­áŠ­áˆáˆ‰');
  String get deliveryGuaranteeNote => t('On-time guaranteed: >30 min late â†’ delivery fee refunded automatically.', 'á‹áˆ­áˆµ á‹¨á‰°áˆ¨áŒ‹áŒˆáŒ á¡ áŠ¨30 á‹°á‰‚á‰ƒ áŠ«áˆˆáˆ â†’ á‹¨áˆ›áŒ“áŒ“á‹£ áŠ­áá‹« á‰ áˆ«áˆ± á‹­áˆ˜áˆˆáˆ³áˆá¢');

  /// Â§11.3 driver-side price lock: identical locked total to collect.
  String collectExactly(int totalEtb) => t(
    'Collect exactly $totalEtb ETB â€” collecting more is grounds for removal.',
    'á‰ á‰µáŠ­áŠ­áˆ $totalEtb á‰¥áˆ­ á‹­áˆ°á‰¥áˆµá‰¡ â€” á‰ áˆ‹á‹­ áˆ˜áˆ°á‰¥áˆ°á‰¥ áˆ˜á‹ˆáŒˆá‹µáŠ• á‹«áˆ˜áŒ£áˆ',
  );
  String get shareToSaveNames => t('Order from local kitchens, delivered with care â€” share to save on your next ride.', 'áˆžá‰… á‹«áˆˆ áˆáŒá‰¥ á‹­áˆ‹áŠ©');

  // ---- field agent (Â§12) ----
  String get fieldAgentTitle => t('Field Agent', 'á‹¨áˆ˜áˆµáŠ­ á‹ˆáŠªáˆ');
  String get fieldNearby => t('Nearby draft merchants (GPS-sorted)', 'á‹¨á‰…áˆ­á‰¥ áŠáŒ‹á‹´á‹Žá‰½');
  String get fieldCapture => t('Capture & verify (< 2 min)', 'á‹­á‹«á‹™áŠ“ á‹«áˆ¨áŒ‹áŒáŒ¡');
  String get fieldTally => t('Agent tally & ledger', 'á‹¨áŠ áˆµá‰°á‹³á‹°áˆ­ áˆ˜á‹áŒˆá‰¥');
  String get photoMenu => t('Photograph the paper menu', 'á‹¨áˆáŒá‰¥ á‹áˆ­á‹áˆ­ á‹«áŠ•áˆ±');
  String get photoStorefront => t('Photograph the storefront', 'áˆ±á‰áŠ• á‹«áŠ•áˆ±');
  String get confirmPin => t('Confirm / correct GPS pin', 'áˆ›áŠ•áŠªá‹«á‹áŠ• á‹«áˆ¨áŒ‹áŒáŒ¡');
  String get paymentDetails => t('Capture Telebirr/CBE + phone', 'á‹¨áŠ­áá‹« á‹áˆ­á‹áˆ­');
  String get verifyMerchant => t('Submit verification', 'á‹«áˆµáŒˆá‰¡');
  String get agentLedger => t('Earnings ledger', 'á‹¨áŒˆá‰¢ áˆ˜á‹áŒˆá‰¥');
}
