import '../models/catalog.dart';
import '../models/catalog_response.dart';
import '../models/driver.dart';
import '../models/menu.dart';
import '../models/merchant.dart';
import '../models/backend_services.dart';
import '../models/order.dart';
import '../models/rating.dart';
import '../models/role_dashboards.dart';
import '../models/session.dart';
import 'api_types.dart';
import 'mock_catalog.dart';

/// In-memory backend emulation for demo/offline mode. Mirrors the §4 wire
/// contract and produces coherent fixtures for all five role dashboards so the
/// app is fully demonstrable without a deployed backend.
class MockBackend {
  MockBackend() {
    _catalog = MockCatalog.data;
    for (final o in _seedOrders()) {
      _orders[o.id] = o;
    }
    _rounds = _seedRounds();
    _disputes = _seedDisputes();
    _promos = _seedPromos();
    _otp = <String, String>{
      for (final p in _otpPhones) p: _genCode(),
    };
  }

  late CatalogResponse _catalog;
  final Map<String, Order> _orders = {};
  List<SeferRound> _rounds = [];
  List<Dispute> _disputes = [];
  List<Promotion> _promos = [];
  List<MerchantApplication> _applications = _seedApplications();
  final List<OtpLogEntry> _otpLog = _seedOtpLog();
  Map<String, String> _otp = {};
  final List<String> _otpPhones = const ['+251911224410', '+251911000001'];

  int _n = 0;
  AppConfig get _cfg => _catalog.config;

  String _genCode() => (100000 + (_n++ * 7) % 899999).toString();

  // ---- auth ----
  Session join({required String phone, required String name, required String role}) {
    return Session(
      token: 'demo-$phone',
      profile: Profile(
        id: 'p-${_n++}',
        phone: phone,
        name: name,
        role: UserRole.values.firstWhere((e) => e.name == role, orElse: () => UserRole.customer),
      ),
    );
  }

  OtpRequestResult otpRequest({required String phone, String channel = 'sms'}) {
    final code = _otp.putIfAbsent(phone, _genCode);
    return OtpRequestResult(ok: true, provider: 'demo', demoCode: code);
  }

  String otpVerify({required String phone, required String code}) {
    if (_otp[phone] == code) return phone;
    throw const ApiPublic('Invalid OTP');
  }

  Session tgAuth({required String initData}) => const Session(
    token: 'tg-demo',
    profile: Profile(id: 'p-tg', phone: '+251911000001', name: 'Telegram User', role: UserRole.customer),
  );

  // ---- catalog ----
  CatalogResponse catalog() => _catalog;

  // ---- orders ----
  Order placeOrder({
    required String token,
    required String phone,
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required String subCity,
    required String sefer,
    required String landmarkText,
    double? lat,
    double? lng,
    required String paymentMethod,
    String? roundId,
  }) {
    // Server-authoritative pricing: re-fetch from catalog menu.
    int subtotal = 0;
    final lines = <OrderItemLine>[];
    for (final it in items) {
      final id = it['itemId'] as String? ?? '';
      final qty = (it['qty'] as num?)?.toInt() ?? 0;
      final item = _itemById(id);
      if (item == null || !item.isAvailable || qty <= 0) {
        throw ApiPublic('Item unavailable: $id');
      }
      final price = item.priceEtb * qty;
      subtotal += price;
      lines.add(OrderItemLine(
        nameEn: item.nameEn,
        nameAm: item.nameAm,
        qty: qty,
        price: item.priceEtb,
        injera: (it['injeraCount'] as num?)?.toInt() ?? 0,
        spice: (it['spice'] as num?)?.toInt() ?? 0,
      ));
    }
    final delivery = _deliveryFor(lat, subtotal, roundId);
    final surge = _cfg.rainMode ? _cfg.rainSurge : 0;
    final service = _cfg.serviceFee;
    final total = subtotal + delivery + service + surge;
    final merchant = _merchantById(merchantId);
    // §11.4 coverage gating: server enforces at order time with a clear
    // pre-submit error — never a post-hoc cancellation.
    if (merchant != null && !merchant.covers(subCity)) {
      throw ApiPublic('This restaurant cannot deliver to $subCity');
    }
    final id = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final order = Order(
      id: id,
      merchantName: merchant?.nameEn ?? 'Kitchen',
      items: lines,
      subtotal: subtotal,
      deliveryFee: delivery,
      serviceFee: service,
      surge: surge,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'chapa' ? PaymentStatus.confirmed : PaymentStatus.codPending,
      paymentRef: paymentMethod == 'chapa' ? 'FT2589102X4' : null,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
      phone: phone,
      ackDeadlineAt: DateTime.now().add(Duration(seconds: _cfg.ackTimeoutSeconds)),
      landmarkText: landmarkText,
      plusCode: '8FMC4RWV+X2',
      subCity: subCity,
      sefer: sefer,
      lat: lat,
      lng: lng,
    );
    _orders[id] = order;
    return order;
  }

  Order order(String id) {
    final o = _orders[id];
    if (o == null) throw const ApiPublic('Order not found');
    // Simulate progression so tracking demos live.
    _orders[id] = _advance(o);
    return _orders[id]!;
  }

  List<Order> ordersFor(String phone) =>
      _orders.values.where((o) => o.phone == phone).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
Order _advance(Order o) {
    // §5.5 Chapa: hosted payment is confirmed server-side — surface it on poll.
    if (o.paymentMethod == 'chapa' && o.paymentStatus == PaymentStatus.pending) {
      return _withPayment(_withStatus(o, OrderStatus.courierAssigned), PaymentStatus.confirmed, 'FT2589102X4');
    }
    if (o.status == OrderStatus.placed) {
      return _withStatus(o, OrderStatus.preparing)
          .copyWithCourier(name: 'Tariku Assefa', phone: '+251911224410', vehicle: 'Bajaj · AA 2-38102');
    }

    return o;
  }

  MenuItem? _itemById(String id) {
    for (final i in _catalog.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Merchant? _merchantById(String id) {
    for (final m in _catalog.merchants) {
      if (m.id == id) return m;
    }
    return null;
  }

  int _deliveryFor(double? lat, int subtotal, String? roundId) {
    if (subtotal < _cfg.bunaMaxOrder && lat != null) return _cfg.bunaRunFee;
    // Round-fee: batched drop-offs split the delivery fee (§6B).
    if (roundId != null) return (_cfg.deliveryFee2km ~/ 3).clamp(20, _cfg.deliveryFee2km);
    // Foot-tier downgrade for short docks (zero fuel).
    if (lat != null && subtotal < _cfg.bunaMaxOrder) return _cfg.footFee;
    return _cfg.deliveryFee2km;
  }

  // ---- merchant ----
  List<MerchantOrder> merchantQueue() {
    final placed = _orders.values.where((o) => o.status == OrderStatus.placed).map((o) => o).toList();
    return [
      for (final o in placed)
        MerchantOrder(
          order: o,
          ackDeadlineAt: o.ackDeadlineAt ?? DateTime.now().add(const Duration(seconds: 90)),
        ),
    ];
  }

  Future<void> merchantAction(String orderId, String action) async {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = o.copyWith(
      status: switch (action) {
        'accept' => OrderStatus.merchantAck,
        'decline' => OrderStatus.cancelled,
        'preparing' => OrderStatus.preparing,
        _ => o.status,
      },
      ackDeadlineAt: null,
      smsFallbackSent: false,
    );
  }

  Future<void> toggleMenuAvailability(String itemId, bool available) async {
    // In mock, no-op (kept for contract parity).
  }

  Future<void> uploadMenuPhoto(String merchantId, String photoB64) async {}

  // ---- driver ----
  DriverDashboard driverDashboard() {
    final placed = _orders.values.where((o) => o.status == OrderStatus.placed).toList();
    final curfew = _cfg.vehicleCurfew; // §5.8b evening motorbike restriction
    final offers = <DriverOffer>[
      if (placed.isNotEmpty)
        for (final o in placed.take(3))
          DriverOffer(
            orderId: o.id,
            merchant: o.merchantName,
            sefer: o.subCity,
            distanceKm: 1.2,
            grossFee: 80,
            keeperShare: 64,
            fuelCost: 10,
            net: 54,
            subsidy: 0,
            tipsEtb: 12,
            // §5.8b: curfew shifts dispatch to car/foot → conservative extended ETA.
            etaMin: curfew ? 32 : 15,
            footEligible: true,
          ),
    ];
    // §5.8b: during curfew, motorbike dispatch is suppressed — only foot/bicycle
    // (zero-fuel short) offers remain eligible.
    final visible = curfew ? offers.where((o) => o.footEligible).toList() : offers;
    // §11.3 price lock: surface the locked collect-on-arrival total of the
    // driver's active pickup (first placed order) so the driver collects the
    // identical amount the customer locked — never a hardcoded constant.
    final activeTotal = placed.isNotEmpty ? placed.first.total : null;
    return DriverDashboard(
      wallet: const DriverWallet(balanceEtb: 640, floatEtb: 1200, floatCap: 1500, payoutDue: 0),
      econByVehicle: const [
        VehicleEconomics(vehicle: DeliveryVehicle.foot, costPerKm: 0, rangeKm: 1.5, keeperSharePct: 95),
        VehicleEconomics(vehicle: DeliveryVehicle.bicycle, costPerKm: 0, rangeKm: 4, keeperSharePct: 80),
        VehicleEconomics(vehicle: DeliveryVehicle.motorbike, costPerKm: 10, rangeKm: 18, keeperSharePct: 80),
        VehicleEconomics(vehicle: DeliveryVehicle.car, costPerKm: 18, rangeKm: 30, keeperSharePct: 80),
      ],
      offers: visible,
      curfewActive: curfew,
      activeOrderTotalEtb: activeTotal,
    );
  }

  Future<void> driverAccept(String orderId) async {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = _withStatus(o, OrderStatus.courierAssigned);
  }

  Future<void> submitPOD(ProofOfDelivery pod) async {
    final o = _orders[pod.orderId];
    if (o == null) return;
    _orders[pod.orderId] = _withStatus(o, OrderStatus.delivered);
  }

  // ---- foot ----
  FootStatus footStart(String phone) =>
      const FootStatus(signupComplete: true, orientationComplete: false, earningToday: false, radiusKm: 1.5, missed: 0, phone: '+251911000001');
  FootStatus footOrientation() => const FootStatus(signupComplete: true, orientationComplete: true, earningToday: false, radiusKm: 1.5, missed: 0, phone: '');
  FootStatus footEarnToday() => const FootStatus(signupComplete: true, orientationComplete: true, earningToday: true, radiusKm: 1.5, missed: 0, phone: '');
  FootEarnings footEarnings() => const FootEarnings(
    walletBalanceEtb: 95,
    bonuses: [
      FootBonus(kind: 'signup', amountEtb: 50, deliveredEtb: 0, status: 'released'),
      FootBonus(kind: 'first_trip', amountEtb: 100, deliveredEtb: 0, status: 'pending'),
    ],
    trips: [],
  );

  // ---- admin ----
  AdminSnapshot adminSnapshot() => AdminSnapshot(
    ordersToday: 47,
    gmvEtb: 18450,
    activeCouriers: 23,
    liveOrders: _orders.values.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList(),
    merchantApplications: _applications,
    ocrQueue: const [
      OcrStaging(
        id: 'ocr-1',
        merchantId: 'sheger-kitchen',
        confidence: 0.93,
        items: [
          OcrDraftItem(nameEn: 'Shiro Wot', nameAm: 'ሽሮ ወጥ', priceEtb: 245, isTsom: true, category: 'Vegan / Yetsom'),
        ],
        status: 'pending',
      ),
    ],
    otpLog: _otpLog,
    channelStatus: const ChannelStatus(provider: 'demo', demo: true, missingSecrets: ['AFROMESSAGE_API_KEY', 'TELEGRAM_BOT_TOKEN']),
    config: _cfg,
  );

  Future<void> adminConfig(AppConfig config) async {
    _catalog = CatalogResponse(
      merchants: _catalog.merchants,
      items: _catalog.items,
      config: config,
      fasting: _catalog.fasting,
      subCities: _catalog.subCities,
    );
  }

  Future<void> adminOrderAction(String orderId, String action) async {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = _withStatus(o, switch (action) {
      'deliver' => OrderStatus.delivered,
      'cancel' => OrderStatus.cancelled,
      'preparing' => OrderStatus.preparing,
      _ => o.status,
    });
  }

  Future<void> verifyOcr(String stagingId) async {}

  // ---- Merchant applications (admin) ----
  List<MerchantApplication> merchantApplications() => _applications;

  Future<void> approveMerchantApplication(String id) async {
    _applications = [
      for (final a in _applications)
        if (a.id == id)
          MerchantApplication(
            id: a.id,
            ownerName: a.ownerName,
            phone: a.phone,
            businessName: a.businessName,
            subCity: a.subCity,
            sefer: a.sefer,
            acceptsCash: a.acceptsCash,
            acceptsChapa: a.acceptsChapa,
            tsomCertified: a.tsomCertified,
            halalCertified: a.halalCertified,
            photoB64: a.photoB64,
            status: 'active',
          )
        else
          a,
    ];
  }

  Future<void> rejectMerchantApplication(String id, String note) async {
    _applications = [
      for (final a in _applications)
        if (a.id == id)
          MerchantApplication(
            id: a.id,
            ownerName: a.ownerName,
            phone: a.phone,
            businessName: a.businessName,
            subCity: a.subCity,
            sefer: a.sefer,
            acceptsCash: a.acceptsCash,
            acceptsChapa: a.acceptsChapa,
            tsomCertified: a.tsomCertified,
            halalCertified: a.halalCertified,
            photoB64: a.photoB64,
            status: 'rejected',
          )
        else
          a,
    ];
  }

  List<OtpLogEntry> adminOtpLog() => _otpLog;

  static List<MerchantApplication> _seedApplications() => const [
    MerchantApplication(
      id: 'app-1',
      ownerName: 'Selam Tadesse',
      phone: '+251911224410',
      businessName: 'ቡና ቤት · Buna Bet',
      subCity: 'Bole',
      sefer: 'Edna Mall',
      acceptsCash: true,
      acceptsChapa: true,
      tsomCertified: true,
      halalCertified: false,
      status: 'pending',
    ),
  ];

  static List<OtpLogEntry> _seedOtpLog() => const [
    OtpLogEntry(phone: '+251911000001', channel: 'sms', provider: 'demo', createdAt: null, used: false),
  ];

  // ---- Support / Finance consoles (tech-spec 3.5/3.6) ----
  List<MisconductReport> _reports = _seedReports();
  final List<StrikeRecord> _strikes = _seedStrikes();
  List<RefundRecord> _refunds = _seedRefunds();
  List<PayoutBatch> _batches = _seedBatches();
  bool _reconciled = true;

  SupportDashboard supportDashboard() => SupportDashboard(
    reports: _reports,
    strikes: _strikes,
    refunds: _refunds,
    disputes: _disputes,
    firstResponseMin: 4,
    resolutionHours: 18,
  );

  Future<void> validateReport(String reportId, bool valid) async {
    _reports = [
      for (final r in _reports)
        if (r.id == reportId)
          MisconductReport(
            id: r.id,
            orderId: r.orderId,
            reporterType: r.reporterType,
            subjectType: r.subjectType,
            subjectId: r.subjectId,
            category: r.category,
            status: valid ? 'validated' : 'rejected',
          )
        else
          r,
    ];
  }

  Future<void> approveRefund(String refundId) async {
    _refunds = [
      for (final r in _refunds)
        if (r.id == refundId)
          RefundRecord(id: r.id, orderId: r.orderId, amountEtb: r.amountEtb, status: 'approved', created: r.created)
        else
          r,
    ];
  }

  FinanceDashboard financeDashboard() => FinanceDashboard(
    ledgerImbalance: 0,
    unreconciled24h: _reconciled ? 0 : 1,
    batches: _batches,
    ledger: _seedLedger(),
    payoutFailureCount: 0,
    takeRateNetPromos: 11.4,
  );

  Future<void> runPayoutBatch(String batchId) async {
    _batches = [
      for (final b in _batches)
        if (b.id == batchId)
          PayoutBatch(id: b.id, method: b.method, status: 'confirmed', totalEtb: b.totalEtb, count: b.count, scheduledFor: b.scheduledFor)
        else
          b,
    ];
  }

  Future<void> reconcile() async {
    _reconciled = true;
  }

  static List<MisconductReport> _seedReports() => const [
    MisconductReport(id: 'rep-1', orderId: 'ord-1', reporterType: 'customer', subjectType: 'courier', subjectId: 'c-1', category: 'late_slow', status: 'open'),
    MisconductReport(id: 'rep-2', orderId: 'ord-2', reporterType: 'courier', subjectType: 'restaurant', subjectId: 'r-1', category: 'nonpayment', status: 'open'),
  ];

  static List<StrikeRecord> _seedStrikes() => [
    StrikeRecord(subjectType: 'courier', subjectId: 'c-1', validatedCount: 1, level: StrikeLevel.warning, issuedAt: DateTime(2026, 8, 25)),
  ];

  static List<RefundRecord> _seedRefunds() => [
    RefundRecord(id: 'rf-1', orderId: 'ord-9', amountEtb: 120, status: 'requested', created: DateTime(2026, 8, 25)),
  ];

  static List<PayoutBatch> _seedBatches() => [
    PayoutBatch(id: 'pb-1', method: 'telebirr_b2c', status: 'pending', totalEtb: 18500, count: 23, scheduledFor: DateTime(2026, 8, 26, 10)),
    PayoutBatch(id: 'pb-2', method: 'bank_transfer', status: 'sent', totalEtb: 64200, count: 5, scheduledFor: DateTime(2026, 8, 26, 13)),
  ];

  static List<LedgerEntry> _seedLedger() => const [
    LedgerEntry(txnId: 'txn-1', account: 'platform:fees', debit: 0, credit: 1280, orderId: 'ord-1'),
    LedgerEntry(txnId: 'txn-1', account: 'courier:c-1', debit: 1280, credit: 0, orderId: 'ord-1'),
    LedgerEntry(txnId: 'txn-2', account: 'merchant:sheger-kitchen', debit: 0, credit: 2400, orderId: 'ord-2'),
    LedgerEntry(txnId: 'txn-2', account: 'platform:fees', debit: 2400, credit: 0, orderId: 'ord-2'),
  ];
  // ---- CEO ----
  CeoDashboard ceoDashboard() => CeoDashboard(
    gmvEtb: 184500,
    orders: 1203,
    codSharePct: 42,
    drivers: 214,
    customers: 8900,
    inflationPct: 22,
    feeMultiplier: _cfg.feeMultiplier,
    disputes: _disputes,
    promotions: _promos,
  );

  Future<void> resolveDispute(String disputeId) async {
    _disputes = [
      for (final d in _disputes) if (d.id == disputeId) Dispute(id: d.id, orderId: d.orderId, reason: d.reason, status: 'resolved', resolution: 'Refunded') else d,
    ];
  }

  /// §11.5 ticketed disputes: a customer-opened dispute gets a visible ticket ID
  /// that the CEO dashboard resolves (same ticket, both sides).
  Future<Dispute> openDispute(String orderId, String reason) async {
    final id = 'tkt-${DateTime.now().millisecondsSinceEpoch}';
    final d = Dispute(id: id, orderId: orderId, reason: reason, status: 'open');
    _disputes = [..._disputes, d];
    return d;
  }

  Future<void> createPromo(String label, int discountPct, int maxUses) async {
    _promos = [
      ..._promos,
      Promotion(id: 'promo-${_n++}', label: label, discountPct: discountPct, maxUses: maxUses, uses: 0, active: true),
    ];
  }

  // ---- ratings (three-directional, tech-spec §3.6) ----
  final Map<String, RatingSubmission> _ratings = {};

  Future<void> submitRating(RatingSubmission r) async {
    // One rating per direction per order. Re-submitting the same direction
    // overwrites instead of allowing duplicates.
    _ratings['${r.orderId}:${r.direction.wire}'] = r;
  }

  // ---- rounds ----
  List<SeferRound> roundsForHub(String hub) => _rounds;
  List<SeferRound> _seedRounds() => const [
    SeferRound(id: 'round-1', hub: 'Bole', label: 'Bole 12:30 Round', departureAt: null, memberCount: 3, perHeadFeeEtb: 30, joinable: true),
    SeferRound(id: 'round-2', hub: 'Kazanchis', label: 'Kazanchis 13:00 Round', departureAt: null, memberCount: 5, perHeadFeeEtb: 24, joinable: true),
  ];

  List<Dispute> _seedDisputes() => const [
    Dispute(id: 'd-1', orderId: 'ord-1', reason: 'I never received this', status: 'open'),
  ];

  List<Promotion> _seedPromos() => const [
    Promotion(id: 'promo-1', label: 'Welcome -10%', discountPct: 10, maxUses: 500, uses: 42, active: true),
  ];

  List<Order> _seedOrders() => [];

  Order _withStatus(Order o, OrderStatus status) => Order(
    id: o.id,
    merchantName: o.merchantName,
    items: o.items,
    subtotal: o.subtotal,
    deliveryFee: o.deliveryFee,
    serviceFee: o.serviceFee,
    surge: o.surge,
    total: o.total,
    paymentMethod: o.paymentMethod,
    paymentStatus: o.paymentStatus,
    paymentRef: o.paymentRef,
    status: status,
    createdAt: o.createdAt,
    courierName: o.courierName,
    courierPhone: o.courierPhone,
    courierVehicle: o.courierVehicle,
    ackDeadlineAt: o.ackDeadlineAt,
    smsFallbackSent: o.smsFallbackSent,
    landmarkText: o.landmarkText,
    plusCode: o.plusCode,
    subCity: o.subCity,
    sefer: o.sefer,
    phone: o.phone,
    lat: o.lat,
    lng: o.lng,
    settlementBatch: o.settlementBatch,
  );
}

Order _withPayment(Order o, PaymentStatus paymentStatus, String? ref) => Order(
  id: o.id,
  merchantName: o.merchantName,
  items: o.items,
  subtotal: o.subtotal,
  deliveryFee: o.deliveryFee,
  serviceFee: o.serviceFee,
  surge: o.surge,
  total: o.total,
  paymentMethod: o.paymentMethod,
  paymentStatus: paymentStatus,
  paymentRef: ref ?? o.paymentRef,
  status: o.status,
  createdAt: o.createdAt,
  phone: o.phone,
  courierName: o.courierName,
  courierPhone: o.courierPhone,
  courierVehicle: o.courierVehicle,
  ackDeadlineAt: o.ackDeadlineAt,
  smsFallbackSent: o.smsFallbackSent,
  landmarkText: o.landmarkText,
  plusCode: o.plusCode,
  subCity: o.subCity,
  sefer: o.sefer,
  lat: o.lat,
  lng: o.lng,
  settlementBatch: o.settlementBatch,
);

