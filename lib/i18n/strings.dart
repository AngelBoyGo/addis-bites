/// Bilingual (Amharic + English) strings per the microcopy matrix (§8).
/// All copy lives here — zero hardcoded strings in widgets.
library;

enum LocaleId { en, am }

/// Immutable bilingual catalog. Constructed once per locale and provided via
/// [StringsProvider].
class Strings {
  final LocaleId locale;

  const Strings(this.locale);

  bool get isAm => locale == LocaleId.am;

  String t(String en, String am) => isAm ? am : en;

  // ---- microcopy matrix (§8) ----
  String get orderCta => t('Place Order', 'ትዕዛዝ ይላኩ');
  String get customizePlatter => t('Customize Platter', 'ገበታዎን ያዘጋጁ');
  String get sendGursha => t('Send Gursha', 'ጉርሻ ይላኩ');
  String get addExtraInjera => t('Add Extra Injera', 'ተጨማሪ እንጀራ ይጨምሩ');
  String get statusPlaced => t('Order Placed', 'ትዕዛዝዎ ተቀብለናል');
  String get statusPreparing => t('In the Kitchen', 'ምግብዎ እየተዘጋጀ ነው');
  String get statusEnRoute => t('Rider En Route', 'አበላሹ በመንገድ ላይ ነው');
  String get statusArrived => t('Arrived at Landmark', 'አበላሹ ምልክቱ ቦታ ደርሷል');
  String get statusDelivered => t('Delivered', 'ተላልፏል');
  String get connectionLost => t('Connection Lost', 'ኮኔክሽን ተቋርጧል');
  String get retry => t('Retry', 'ድጋሚ ይሞክሩ');
  String get verifyingPayment => t('Verifying Payment', 'ክፍያዎ እየተረጋገጠ ነው');
  String get fastingTag => t('Fasting', 'የጾም');
  String get coffeeRun => t('Coffee Run', 'የቡና ሰዓት');
  String get dailySpecial => t('Top Choice', 'የዛሬ ልዩ');
  String get enjoyMeal => t('Enjoy your meal', 'መልካም ምግብ');

  // ---- search & filter (core feature) ----
  String get searchPlaceholder => t(
    'Search food, restaurants, categories, lifestyles…',
    'ምግብ፣ ሬስቶራንት፣ ምድብ፣ የአመጋገብ አይነት ይፈልጉ…',
  );
  String get openNow => t('Open Now', 'አሁን ክፍት');
  String get all => t('All', 'ሁሉም');
  String get fasting => t('ጾም', 'የጾም');
  String get halal => t('Halal', 'ሃላል');
  String get lifestyleTitle => t('Lifestyle', 'የአመጋገብ አይነት');
  String get categoriesTitle => t('Categories', 'ምድቦች');
  String get restaurants => t('Restaurants', 'ሬስቶራንቶች');
  String get menuItems => t('Menu items', 'የምግብ ዝርዝር');
  String get noResults => t('No results', 'ምንም ውጤት የለም');
  String get tryClearFilters => t('Try clearing your search or filters', 'ማጣሪያዎችን ያጽዱ');
  String get fastingModeActive => t('Fasting Mode Active', 'የጾም ቀን');
  String get showAll => t('Show all', 'ሁሉንም ያሳዩ');
  String get showFastingFriendly => t('Show fasting-friendly', 'የጾም ወዳጃዊ ያሳዩ');
  String get resultsFor => t('Results for', 'ውጤቶች ለ');
  String get open => t('Open', 'ክፍት');
  String get closed => t('Closed', 'ዝግ');
  String get orders => t('Orders', 'ትዕዛዞች');
  String get cart => t('Cart', 'ገበታ');
  String get more => t('More', 'ተጨማሪ');

  // ---- configurator / cart ----
  String get quantity => t('Quantity', 'ብዛት');
  String get injeraRolls => t('How many rolls of injera?', 'ስንት እንጀራ?');
  String get addFor => t('Add for', 'ይጨምሩ ለ');
  String get spiceLevel => t('Spice level', 'የቅመም መጠን');
  String get injera => t('Injera', 'እንጀራ');
  String get subtotal => t('Subtotal', 'ንዑስ-ድምር');
  String get deliveryFee => t('Delivery', 'መላኪያ');
  String get serviceFee => t('Service fee', 'የአገልግሎት ክፍያ');
  String get surge => t('Rain surge', 'የዝናብ ተጨማሪ');
  String get total => t('Total', 'ጠቅላላ');
  String get placeOrder => t('Place order', 'ትዕዛዝ ይላኩ');
  String get youSave => t('You save', 'ይቆጥቡ');
  String get whyThisFee => t('Why this fee?', 'ይህ ክፍያ ለምን?');
  String get deliveredOnFoot => t('Delivered on foot', 'በእግር ተላልፏል');
  String get emptyCart => t('Your platter is empty', 'ገበታዎ ባዶ ነው');
  String get deliveryBand => t('Delivery distance', 'የማድረስ ርቀት');
  String get deliverTo => t('Deliver to', 'ወደ ማድረስ');
  String get phone => t('Phone', 'ስልክ');
  String get subCity => t('Sub-city / Area', 'ንዑስ ከተማ');
  String get selectNeighborhood => t('Select neighborhood', 'ሰፈር ይምረጡ');
  String get landmarkLabel => t('Nearby Landmark & Gate Details', 'ልዩ ቦታ እና የቤት ምልክት');
  String get landmarkPlaceholder =>
      t('e.g., Behind Total station, yellow building, green gate', 'ለምሳሌ ከቶታል ጀርባ፣ ቢጫ ፎቅ፣ አረንጓዴ በር');
  String get paymentMethod => t('Payment method', 'የክፍያ ዘዴ');
  String get orderCheckout => t('Checkout', 'መክፈያ');
  String get chapa => t('Chapa / Telebirr / CBE', 'ቻፓ / ቴሌብር');
  String get chapaSub => t('Cards, Telebirr, CBE Birr', 'ካርድ፣ ቴሌብር፣ ሲቢኢ');
  String get cod => t('Cash on Delivery', 'በአቅራቢ በጥሬ ገንዘብ');
  String get codNote => t('Courier float cap 1,500 ETB · settle in 24 h', 'የጭነት ገንዘብ ገደብ 1,500 ብር');
  String get sefer => t('Sefer / hub', 'ሰፈር');
  String get verified => t('VERIFIED', 'ፀድቋል');
  String get codPending => t('COD pending', 'በጥሬ ገንዘብ በመጠበቅ ላይ');
  String get pending => t('Pending', 'በመጠበቅ ላይ');
  String get smsEscalated => t('Merchant notified by SMS ticket — escalating to voice call', 'ነጋዴው በSMS ተነግሮታል');
  String get ackNow => t('Merchant ack in', 'የነጋዴ ማረጋገጫ');
  String get landmark => t('Landmark', 'ልዩ ቦታ');
  String get plusCode => t('Plus Code', 'ኮድ');
  String get items => t('Items', 'ዕቃዎች');
  String get noOrders => t('No orders yet', 'ገና ትዕዛዝ የለም');
  String get continueBtn => t('Continue', 'ቀጥል');

  // ---- role dashboards (§5.8–5.12) ----
  String get driverTitle => t('Driver Dashboard', 'የአበላሽ ሰሌዳ');
  String get economicsCard => t('Economics', 'ኢኮኖሚክስ');
  String get costPerKm => t('Cost / km', 'ዋጋ / ኪ.ሜ.');
  String get effectiveRange => t('Effective range', 'ውጤታማ ርቀት');
  String get keeperShare => t('Keeper share', 'የአበላሹ ድርሻ');
  String get walletCard => t('Wallet', 'ቦርሳ');
  String get balance => t('Balance', 'ቀሪ');
  String get codFloat => t('COD float used', 'የጥሬ ገንዘብ ተጠቅሶ');
  String get codBlockedNote => t('COD orders blocked: float at cap. Reconcile before taking cash orders.', 'የጥሬ ገንዘብ እቃ የለም');
  String get payoutDue => t('Payout due', 'የሚከፈል');
  String get curfewNote => t('Evening rider restrictions — motorbike offers suppressed, delivery by car/foot.', 'የምሽት ገደቦች');
  String get liveOffers => t('Live offers', 'ቀጥታ ቅናሾች');
  String get activeOrder => t('Active order', 'ንቁ ትዕዛዝ');
  String get noOffers => t('No live offers right now', 'አሁን ምንም ቅናሽ የለም');
  String get fuelBurn => t('Fuel burn', 'ነዳጅ');
  String get platformSubsidy => t('Platform subsidy', 'የፕላትፎርም ድጋፍ');
  String get netEarnings => t('Net earnings', 'የተጣራ ገቢ');
  String get accept => t('Accept', 'ተቀበል');
  String get assignedOrdersPending => t('Assigned orders appear here — deliver with POD photo + PIN.', 'የተሰጡ ትዕዛዞች');
  String get proofOfDelivery => t('Proof of delivery', 'የማድረስ ማረጋገጫ');

  // ---- merchant ----
  String get merchantTitle => t('Merchant Console', 'የነጋዴ ሰሌዳ');
  String get liveQueue => t('Live order queue', 'ቀጥታ ትዕዛዝ ወረፋ');
  String get merchantAck => t('Merchant ack', 'የነጋዴ ማረጋገጫ');
  String get acceptOrder => t('Accept', 'ተቀበል');
  String get declineOrder => t('Decline', 'አንቀበልም');
  String get markPreparing => t('Mark Preparing', 'በዝግጅት ምልክት');
  String get menuAvailability => t('Menu availability', 'የምግብ ዝርዝር መገኘት');
  String get uploadMenuPhoto => t('Upload menu photo (OCR)', 'የምግብ ዝርዝር ፎቶ');
  String get inStock => t('Today', 'ክፍት');
  String get outOfStock => t('Sold out', 'ተሟጦ');

  // ---- admin ----
  String get adminTitle => t('Admin Panel', 'የአስተዳዳሪ ሰሌዳ');
  String get ordersToday => t('Orders today', 'የዛሬ ትዕዛዞች');
  String get gmv => t('GMV', 'GMV');
  String get activeCouriers => t('Active couriers', 'ንቁ አበላሾች');
  String get pricingEditor => t('Pricing engine editor', 'የዋጋ አርታዒ');

  // ---- admin (cont.) / ceo / foot ----
  String get rainMode => t('Rain Mode', 'የዝናብ ሁነታ');
  String get fastingOverride => t('Fasting override', 'የጾም ለውጥ');
  String get footFunnel => t('Foot-carrier funnel', 'የእግር አበላሽ መስመር');
  String get merchantApplications => t('Merchant applications', 'የነጋዴ ማመልከቻዎች');
  String get ocrQueue => t('OCR verification queue', 'OCR ማረጋገጫ');
  String get verify => t('Verify', 'አረጋግጥ');
  String get approve => t('Approve', 'ያጽድቁ');
  String get reject => t('Reject', 'ውድቅ');
  String get otpLog => t('OTP log', 'OTP መዝገብ');
  String get providerStatus => t('Channel provider status', 'የቻናል ሁኔታ');
  String get deliver => t('Deliver', 'አሳልፍ');
  String get cancel => t('Cancel', 'ሰርዝ');
  String get ceoTitle => t('CEO Dashboard', 'የባለቤት ሰሌዳ');
  String get inflationEngine => t('Inflation engine', 'የዋጋ ግሽበት');
  String get unitEconomics => t('Unit economics (4 km)', 'ኢኮኖሚክስ');
  String get footNetwork => t('Foot-carrier network', 'የእግር አበላሽ መረብ');
  String get disputes => t('Disputes', 'ክርክሮች');
  String get promotions => t('Promotions', 'ማስተዋወቂያዎች');
  String get resolve => t('Resolve', 'ፍታ');
  String get recruits => t('Recruit', 'ቀጥር');
  String get subsidyGuarantee =>
      t('Drivers always net above fuel — platform subsidizes the gap.', 'አበላሾች ሁልጊዜ ከነዳጅ በላይ ያገኛሉ');
  String get footCarrierTitle => t('Foot Carrier', 'የእግር አበላሽ');
  String get carrierWelcome => t('Start earning today', 'ዛሬ መስራት ይጀምሩ');
  String get orientationChecklist => t('1-minute orientation checklist', 'የዝግጅት ዝርዝር');
  String get carrierEarnings => t('Earnings', 'ገቢ');
  String get bonusesLedger => t('Bonuses ledger', 'የጉርሻ መዝገብ');
  String get tripHistory => t('Trip history', 'የጉዞ ታሪክ');
  String get markDelivered => t('Mark delivered', 'ተላልፏል');
  String get carrierKeep95 => t('Foot carriers keep 95% of fees', 'የእግር አበላሾች 95% ያገኛሉ');
  String get platformFlags => t('Platform flags', 'የፕላትፎርም ማብሪያ');
  String get demoWatermark => t('DEMO', 'ማሳያ');
  String get liveOrders => t('Live orders', 'ቀጥታ ትዕዛዞች');
  String get scheduledFor => t('Scheduled for', 'የተያዘለት');
  String get funded => t('Prepaid', 'ቅድሚያ');

  // ---- payments / verified receipt / refunds / disputes ----
  String get verifiedReceipt => t('VERIFIED PAYMENT RECEIPT', 'የተረጋገጠ ክፍያ ደረሰኝ');
  String get scanForDriver => t('Scan this QR at the restaurant', 'ይህን QR ያስቃኙ');
  String get payWithChapa => t('Pay with Chapa hosted checkout', 'በቻፓ ይክፈሉ');
  String get refundTracker => t('Refund tracker', 'የተመላሽ ክትትል');
  String get refundInitiated => t('Refund initiated', 'ተጀምሯል');
  String get refundProcessing => t('Processing', 'በሂደት');
  String get refundReturned => t('Returned to your Telebirr/CBE', 'ተመልሷል');
  String get refundRef => t('Refund ref', 'የተመላሽ ኮድ');
  String get neverReceived => t('I never received this', 'አልተቀበልኩትም');
  String get overcharged => t('I was overcharged', 'በላይ ተከፍዬያለሁ');
  String get disputeTicket => t('Dispute ticket opened', 'ክርክር ተከፍቷል');
  String get orderBySms => t('Order by SMS', 'በSMS ይዘዙ');
  String get voiceOrderLine => t('Voice order line', 'የድምፅ ማዘዣ');
  String get smsBridgeNote =>
      t('No signal? Compose an SMS order instead.', 'ሲግናል የለም?');
  String get honestEta => t('Honest ETA', 'እውነተኛ ጊዜ');
  String get etaReduced => t('Evening rider restrictions — delivered by car.', 'የምሽት ማድረስ');
  String get cancelFullRefund => t('Cancel with full refund', 'ይሰርዙ እና ሙሉ ተመላሽ');
  String get feeBreakdown => t('Why this fee?', 'ይህ ክፍያ ለምን?');
  String get deposit => t('Deposit', 'ተቀማጭ');
  String get split => t('Split', 'ስብር');
  String get pickupMode => t('Pickup', 'ማንሳት');
  String get meetPoint => t('Meet-point handoff', 'ስምምነት ቦታ');
  String get scheduleAhead => t('Schedule ahead', 'ቀድመው ያዝዙ');
  String get loyaltyStamps => t('Loyalty stamps', 'የታማኝነት ማህተም');
  String get perHead => t('Per person', 'በአንድ ሰው');
  String get freeDelivery => t('free delivery', 'ነጻ ማድረስ');
  String get rateYourExperience => t('How was your order?', 'ትዕዛዝዎ እንዴት ነበር?');
  String get rateRestaurant => t('Rate restaurant', 'ምግብ ቤቱን ይስጥሩ');
  String get rateCourier => t('Rate courier', 'አበላሹን ይስጥሩ');
  String get thanks => t('Thanks for your feedback!', 'ለአስተያየትዎ እናመሰግናለን!');
  String get tier => t('Tier', 'ደረጃ');
  String get nextTier => t('Next tier', 'ቀጣይ ደረጃ');
  String get crewLeader => t('Leader nominated by admin', 'በአስተዳዳሪ የተሾሙ');
  String get sponsorPay => t('Sponsor a meal', 'ምግብ ያበረክቱ');
  String get homeFed => t('Meal paid — your family will be notified!', 'ምግብ ተከፍሏል — ቤተሰብዎ ይነገራል!');
  String get supportConsole => t('Support Console', 'የድጋፍ ሰሌዳ');
  String get financeConsole => t('Finance Console', 'የፋይናንስ ሰሌዳ');
  String get misconductReports => t('Misconduct reports', 'የስነምግባር ዘገባዎች');
  String get strikeLedger => t('Strike ledger', 'የቅጣት መዝገብ');
  String get refundQueue => t('Refund queue', 'የተመላሽ ወረፋ');
  String get payoutBatches => t('Payout batches', 'የክፍያ ስብስቦች');
  String get ledger => t('Ledger', 'መዝገብ');
  String get ledgerZeroNote => t('Ledger must balance to zero.', 'ሒሳብ 0 መሆን አለበት');
  String get reconcileNow => t('Reconcile', 'ማስታረቅ');
  String get validate => t('Validate', 'አረጋግጥ');
  String get trueCost => t('Sort by total cost', 'በጠቅላላ ዋጋ ደርድር');
  String get digitalPaymentDiscount => t('Digital payment discount', 'የዲጂታል ክፍያ ቅናሽ');
  String get dataSaver => t('Data-saver mode', 'መረጃ ቆጣቢ');
  String get gursha => t('Gursha gifting', 'ጉርሻ');
  String get shareGebeta => t('Share Gebeta', 'ገበታ ያጋሩ');
  String get referralCode => t('Referral code', 'የማጋራት ኮድ');
  String get referFriend => t('Refer a friend — both get 50 ETB', 'ወዳጅ ይጋሩ');
  String get nominateRestaurant => t('Nominate a missing restaurant', 'ያልተመዘገበ ሬስቶራንት ይጠቁሙ');
  String get walletTopup => t('Wallet prepay (+5% bonus)', 'የቦርሳ ቅድመ-ክፍያ (+5%)');
  String get lunchPass => t('Weekly lunch pass (5 meals)', 'ሳምንታዊ የምሳ ፓስ');
  String get shareOnTelegram => t('Share on Telegram', 'በቴሌግራም ያጋሩ');
  String get sendWarmMeal => t('Send a warm meal home to Addis', 'ሞቅ ያለ ምግብ ይላኩ');
  String get joinRound => t('Join the Round', 'ዙር ይቀላቀሉ');
  String get neighborsJoined => t('neighbors joined', 'ጎረቤቶች ተቀላቅለዋል');
  String get yourFeeNow => t('your fee is now', 'ክፍያዎ አሁን');
  String get moreNeighborSaved => t('1 more neighbor = −8 ETB', 'ተጨማሪ ጎረቤት = −8 ብር');
  String get roundsArriveWindow => t('Batched orders arrive within the round window.', 'ዙር ጊዜ ውስጥ ይደርሳል');
  String get priceLockNote => t('Locked total — pay exactly this. Collecting more is grounds for removal.', 'ቋሚ ጠቅላላ — ይህን በትክክል ይክፈሉ');

  /// §11.3 driver-side price lock: identical locked total to collect.
  String collectExactly(int totalEtb) => t(
    'Collect exactly $totalEtb ETB — collecting more is grounds for removal.',
    'በትክክል $totalEtb ብር ይሰብስቡ — በላይ መሰብሰብ መወገድን ያመጣል',
  );
  String get shareToSaveNames => t('Order from local kitchens, delivered with care — share to save on your next ride.', 'ሞቅ ያለ ምግብ ይላኩ');

  // ---- field agent (§12) ----
  String get fieldAgentTitle => t('Field Agent', 'የመስክ ወኪል');
  String get fieldNearby => t('Nearby draft merchants (GPS-sorted)', 'የቅርብ ነጋዴዎች');
  String get fieldCapture => t('Capture & verify (< 2 min)', 'ይያዙና ያረጋግጡ');
  String get fieldTally => t('Agent tally & ledger', 'የአስተዳደር መዝገብ');
  String get photoMenu => t('Photograph the paper menu', 'የምግብ ዝርዝር ያንሱ');
  String get photoStorefront => t('Photograph the storefront', 'ሱቁን ያንሱ');
  String get confirmPin => t('Confirm / correct GPS pin', 'ማንኪያውን ያረጋግጡ');
  String get paymentDetails => t('Capture Telebirr/CBE + phone', 'የክፍያ ዝርዝር');
  String get verifyMerchant => t('Submit verification', 'ያስገቡ');
  String get agentLedger => t('Earnings ledger', 'የገቢ መዝገብ');
}