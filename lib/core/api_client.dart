import 'package:dio/dio.dart';

import '../models/backend_services.dart';
import '../models/catalog.dart';
import '../models/catalog_response.dart';
import '../models/driver.dart';
import '../models/order.dart';
import '../models/rating.dart';
import '../models/role_dashboards.dart';
import '../models/session.dart';
import 'api_types.dart';
import 'mock_backend.dart';

/// REST client against the Addis Bites backend. Reads ONLY `API_BASE` via
/// dart-define (`--dart-define=API_BASE=https://addis-bites.higgsfield.app`).
///
/// When no base URL is configured, the client runs against an in-memory
/// [MockBackend] so the whole app (all five role dashboards) is demoable and
/// fully offline. No secrets ever live in the client.
class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
      : baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE')).trim(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: (baseUrl ?? const String.fromEnvironment('API_BASE')).trim(),
              headers: {'Content-Type': 'application/json'},
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            )) {
    _mock = MockBackend();
  }

  final String baseUrl;
  final Dio _dio;
  late final MockBackend _mock;

  bool get isMock => baseUrl.isEmpty;

  Map<String, dynamic> _auth(String token) =>
      {'Authorization': 'Bearer $token'};

  Future<dynamic> _get(String path, String token) async {
    try {
      final r = await _dio.get<dynamic>(path, options: Options(headers: _auth(token)));
      return r.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw ApiException.unauthenticated(e.response?.statusCode ?? 401);
      }
      throw ApiException.network(e.message ?? 'Network error');
    }
  }

  // ================= AUTH =================
  Future<Session> join({required String phone, required String name, required String role}) async {
    if (isMock) return _mock.join(phone: phone, name: name, role: role);
    final r = await _dio.post<dynamic>('/join', data: {'phone': phone, 'name': name, 'role': role});
    return Session.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OtpRequestResult> otpRequest({required String phone, String channel = 'sms'}) async {
    if (isMock) return _mock.otpRequest(phone: phone, channel: channel);
    final r = await _dio.post<dynamic>('/api/otp/request', data: {'phone': phone, 'channel': channel});
    final j = r.data as Map<String, dynamic>;
    return OtpRequestResult(
      ok: j['ok'] as bool? ?? false,
      provider: j['provider'] as String? ?? '',
      demoCode: j['demoCode'] as String?,
    );
  }

  Future<String> otpVerify({required String phone, required String code}) async {
    if (isMock) return _mock.otpVerify(phone: phone, code: code);
    final r = await _dio.post<dynamic>('/api/otp/verify', data: {'phone': phone, 'code': code});
    return (r.data as Map<String, dynamic>)['phone'] as String? ?? phone;
  }

  Future<Session> tgAuth({required String initData}) async {
    if (isMock) return _mock.tgAuth(initData: initData);
    final r = await _dio.post<dynamic>('/api/tg-auth', data: {'initData': initData});
    return Session.fromJson(r.data as Map<String, dynamic>);
  }

  // ================= CATALOG =================
  Future<CatalogResponse> fetchCatalog({String? token}) async {
    if (isMock) return _mock.catalog();
    final data = await _get('/api/catalog', token ?? '');
    return CatalogResponse.fromJson(data as Map<String, dynamic>);
  }

  // ================= ORDERS =================
  Future<Order> placeOrder({
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
    String? promoCode,
  }) async {
    if (isMock) {
      return _mock.placeOrder(
        token: token,
        phone: phone,
        merchantId: merchantId,
        items: items,
        subCity: subCity,
        sefer: sefer,
        landmarkText: landmarkText,
        lat: lat,
        lng: lng,
        paymentMethod: paymentMethod,
        roundId: roundId,
        promoCode: promoCode,
      );
    }
    final body = {
      'token': token,
      'phone': phone,
      'merchantId': merchantId,
      'items': items,
      'subCity': subCity,
      'sefer': sefer,
      'landmarkText': landmarkText,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'paymentMethod': paymentMethod,
      if (roundId != null) 'roundId': roundId,
      if (promoCode != null && promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim(),
    };
    final r = await _dio.post<dynamic>('/api/place-order', data: body, options: Options(headers: _auth(token)));
    return Order.fromJson(r.data as Map<String, dynamic>);
  }

  /// Server-side promo preview (no side effects). Returns
  /// {ok, valid, discountPct, label}.
  Future<Map<String, dynamic>> promoValidate(String code, String token) async {
    if (isMock) return _mock.promoValidate(code);
    final r = await _dio.post<dynamic>('/api/promo/validate',
        data: {'code': code}, options: Options(headers: _auth(token)));
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Order> fetchOrder(String id, String token) async {
    if (isMock) return _mock.order(id);
    final data = await _get('/api/order/$id', token);
    return Order.fromJson(data as Map<String, dynamic>);
  }

  /// Initializes a Chapa hosted-checkout for [orderId]. Returns the worker's
  /// payload: {ok, simulated, checkoutUrl} — checkoutUrl is null when the
  /// order is already paid.
  Future<Map<String, dynamic>> chapaInitialize(String orderId, String token) async {
    if (isMock) return _mock.chapaInitialize(orderId);
    final r = await _dio.post<dynamic>('/api/payments/chapa/initialize',
        data: {'orderId': orderId}, options: Options(headers: _auth(token)));
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<Order>> fetchOrders(String phone, String token) async {
    if (isMock) return _mock.ordersFor(phone);
    final data = await _get('/api/orders/$phone', token);
    return (data as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ================= MERCHANT =================
  Future<List<MerchantOrder>> merchantQueue(String token) async {
    if (isMock) return _mock.merchantQueue();
    final data = await _get('/api/merchant/queue', token);
    return (data as List).map((e) => MerchantOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> merchantAction(String token, String orderId, String action) async {
    if (isMock) return _mock.merchantAction(orderId, action);
    await _dio.post<dynamic>('/api/merchant/action',
        data: {'orderId': orderId, 'action': action}, options: Options(headers: _auth(token)));
  }

  Future<void> toggleMenuAvailability(String token, String itemId, bool available) async {
    if (isMock) return _mock.toggleMenuAvailability(itemId, available);
    await _dio.post<dynamic>('/api/merchant/menu-toggle',
        data: {'itemId': itemId, 'isAvailable': available}, options: Options(headers: _auth(token)));
  }

  Future<void> uploadMenuPhoto(String token, String merchantId, String photoB64) async {
    if (isMock) return _mock.uploadMenuPhoto(merchantId, photoB64);
    await _dio.post<dynamic>('/api/merchant/menu-photo',
        data: {'merchantId': merchantId, 'photoB64': photoB64}, options: Options(headers: _auth(token)));
  }

  // ================= DRIVER =================
  Future<DriverDashboard> driverDashboard(String token) async {
    if (isMock) return _mock.driverDashboard();
    final data = await _get('/api/driver/dashboard', token);
    return DriverDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<void> driverAccept(String token, String orderId) async {
    if (isMock) return _mock.driverAccept(orderId);
    await _dio.post<dynamic>('/api/driver/accept', data: {'orderId': orderId}, options: Options(headers: _auth(token)));
  }

  Future<void> submitPOD(String token, ProofOfDelivery pod) async {
    if (isMock) return _mock.submitPOD(pod);
    await _dio.post<dynamic>('/api/driver/pod',
        data: {'orderId': pod.orderId, 'photoB64': pod.photoB64, 'pin': pod.pin},
        options: Options(headers: _auth(token)));
  }

  // ================= FOOT =================
  Future<FootStatus> footStart(String phone) async {
    if (isMock) return _mock.footStart(phone);
    await _dio.post<dynamic>('/api/foot/start', data: {'phone': phone});
    return FootStatus(
      signupComplete: true,
      orientationComplete: false,
      earningToday: false,
      radiusKm: 1.5,
      missed: 0,
      phone: phone,
    );
  }

  Future<FootStatus> footOrientation(String token) async {
    if (isMock) return _mock.footOrientation();
    await _dio.post<dynamic>('/api/foot/orientation', data: const {}, options: Options(headers: _auth(token)));
    return const FootStatus(signupComplete: true, orientationComplete: true, earningToday: false, radiusKm: 1.5, missed: 0, phone: '');
  }

  Future<FootStatus> footEarnToday(String token) async {
    if (isMock) return _mock.footEarnToday();
    await _dio.post<dynamic>('/api/foot/earn-today', data: const {}, options: Options(headers: _auth(token)));
    return const FootStatus(signupComplete: true, orientationComplete: true, earningToday: true, radiusKm: 1.5, missed: 0, phone: '');
  }

  Future<FootEarnings> footEarnings(String token) async {
    if (isMock) return _mock.footEarnings();
    final data = await _get('/api/foot/earnings', token);
    return FootEarnings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ================= ADMIN =================
  Future<AdminSnapshot> adminSnapshot(String token) async {
    if (isMock) return _mock.adminSnapshot();
    final data = await _get('/api/admin/snapshot', token);
    final j = data as Map<String, dynamic>;
    return AdminSnapshot(
      ordersToday: (j['ordersToday'] as num?)?.toInt() ?? 0,
      gmvEtb: (j['gmvEtb'] as num?)?.toInt() ?? 0,
      activeCouriers: (j['activeCouriers'] as num?)?.toInt() ?? 0,
      liveOrders: ((j['liveOrders'] as List?) ?? const [])
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      merchantApplications: ((j['merchantApplications'] as List?) ?? const [])
          .map((e) => MerchantApplication.fromJson(e as Map<String, dynamic>))
          .toList(),
      ocrQueue: const [],
      otpLog: ((j['otpLog'] as List?) ?? const [])
          .map((e) => OtpLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      channelStatus: const ChannelStatus(provider: 'demo', demo: true, missingSecrets: []),
      config: AppConfig.fromJson(Map<String, dynamic>.from(j['config'] as Map? ?? const {})),
    );
  }

  /// GET /api/merchant/applications — merchant approval queue (admin).
  Future<List<MerchantApplication>> merchantApplications(String token) async {
    if (isMock) return _mock.merchantApplications();
    final data = await _get('/api/merchant/applications', token);
    return (data as List)
        .map((e) => MerchantApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/merchant/applications/:id/approve — activate a merchant (admin).
  Future<void> approveMerchantApplication(String token, String id) async {
    if (isMock) return _mock.approveMerchantApplication(id);
    await _dio.post<dynamic>('/api/merchant/applications/$id/approve',
        data: const {}, options: Options(headers: _auth(token)));
  }

  /// POST /api/merchant/applications/:id/reject — reject with a note (admin).
  Future<void> rejectMerchantApplication(String token, String id, String note) async {
    if (isMock) return _mock.rejectMerchantApplication(id, note);
    await _dio.post<dynamic>('/api/merchant/applications/$id/reject',
        data: {'note': note}, options: Options(headers: _auth(token)));
  }

  /// GET /api/admin/otp-log — OTP request log (admin).
  Future<List<OtpLogEntry>> adminOtpLog(String token) async {
    if (isMock) return _mock.adminOtpLog();
    final data = await _get('/api/admin/otp-log', token);
    return (data as List)
        .map((e) => OtpLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> adminConfig(String token, AppConfig config) async {
    if (isMock) return _mock.adminConfig(config);
    await _dio.post<dynamic>('/api/admin/config', data: _configToJson(config), options: Options(headers: _auth(token)));
  }

  Future<void> adminOrderAction(String token, String orderId, String action) async {
    if (isMock) return _mock.adminOrderAction(orderId, action);
    await _dio.post<dynamic>('/api/admin/order-action',
        data: {'orderId': orderId, 'action': action}, options: Options(headers: _auth(token)));
  }

  Future<void> adminVerifyOcr(String token, String stagingId) async {
    if (isMock) return _mock.verifyOcr(stagingId);
    await _dio.post<dynamic>('/api/admin/verify-ocr', data: {'stagingId': stagingId}, options: Options(headers: _auth(token)));
  }

  // ================= RATINGS (three-directional, tech-spec §3.6) =================
  Future<void> submitRating(String token, RatingSubmission rating) async {
    if (isMock) return _mock.submitRating(rating);
    await _dio.post<dynamic>('/api/ratings',
        data: rating.toJson(), options: Options(headers: _auth(token)));
  }

  // ================= SUPPORT CONSOLE (trust & safety) =================
  // Route builders kept as statics so tests can assert the id is interpolated
  // and no path ever contains a dangling '//' (a historical concat bug).
  static String supportValidatePath(String reportId) => '/api/support/reports/$reportId/validate';
  static String supportApproveRefundPath(String refundId) => '/api/support/refunds/$refundId/approve';
  static String financeRunPayoutPath(String batchId) => '/api/finance/payouts/$batchId/run';

  Future<SupportDashboard> supportDashboard(String token) async {
    if (isMock) return _mock.supportDashboard();
    final j = await _get('/api/support/dashboard', token) as Map<String, dynamic>;
    return SupportDashboard(
      reports: ((j['reports'] as List?) ?? const []).map((e) => MisconductReport.fromJson(e as Map<String, dynamic>)).toList(),
      strikes: ((j['strikes'] as List?) ?? const []).map((e) => StrikeRecord.fromJson(e as Map<String, dynamic>)).toList(),
      refunds: ((j['refunds'] as List?) ?? const []).map((e) => RefundRecord.fromJson(e as Map<String, dynamic>)).toList(),
      disputes: ((j['disputes'] as List?) ?? const []).map((e) => Dispute.fromJson(e as Map<String, dynamic>)).toList(),
      firstResponseMin: (j['firstResponseMin'] as num?)?.toInt() ?? 0,
      resolutionHours: (j['resolutionHours'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> validateReport(String token, String reportId, bool valid) async {
    if (isMock) return _mock.validateReport(reportId, valid);
    await _dio.post<dynamic>(supportValidatePath(reportId), data: {'valid': valid}, options: Options(headers: _auth(token)));
  }

  Future<void> approveRefund(String token, String refundId) async {
    if (isMock) return _mock.approveRefund(refundId);
    await _dio.post<dynamic>(supportApproveRefundPath(refundId), data: const {}, options: Options(headers: _auth(token)));
  }

  // ================= FINANCE CONSOLE =================
  Future<FinanceDashboard> financeDashboard(String token) async {
    if (isMock) return _mock.financeDashboard();
    final j = await _get('/api/finance/dashboard', token) as Map<String, dynamic>;
    return FinanceDashboard(
      ledgerImbalance: (j['ledgerImbalance'] as num?)?.toInt() ?? 0,
      unreconciled24h: (j['unreconciled24h'] as num?)?.toInt() ?? 0,
      batches: ((j['batches'] as List?) ?? const []).map((e) => PayoutBatch.fromJson(e as Map<String, dynamic>)).toList(),
      ledger: ((j['ledger'] as List?) ?? const []).map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList(),
      payoutFailureCount: (j['payoutFailureCount'] as num?)?.toInt() ?? 0,
      takeRateNetPromos: (j['takeRateNetPromos'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> runPayoutBatch(String token, String batchId) async {
    if (isMock) return _mock.runPayoutBatch(batchId);
    await _dio.post<dynamic>(financeRunPayoutPath(batchId), data: const {}, options: Options(headers: _auth(token)));
  }

  Future<void> reconcile(String token) async {
    if (isMock) return _mock.reconcile();
    await _dio.post<dynamic>('/api/finance/reconcile', data: const {}, options: Options(headers: _auth(token)));
  }
  // ================= CEO =================
  Future<CeoDashboard> ceoDashboard(String token) async {
    if (isMock) return _mock.ceoDashboard();
    final data = await _get('/api/ceo/dashboard', token) as Map<String, dynamic>;
    return CeoDashboard(
      gmvEtb: (data['gmvEtb'] as num?)?.toInt() ?? 0,
      orders: (data['orders'] as num?)?.toInt() ?? 0,
      codSharePct: (data['codSharePct'] as num?)?.toDouble() ?? 0,
      drivers: (data['drivers'] as num?)?.toInt() ?? 0,
      customers: (data['customers'] as num?)?.toInt() ?? 0,
      inflationPct: (data['inflationPct'] as num?)?.toDouble() ?? 22,
      feeMultiplier: (data['feeMultiplier'] as num?)?.toDouble() ?? 1,
      disputes: ((data['disputes'] as List?) ?? const [])
          .map((e) => Dispute.fromJson(e as Map<String, dynamic>))
          .toList(),
      promotions: ((data['promotions'] as List?) ?? const [])
          .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> resolveDispute(String token, String disputeId) async {
    if (isMock) return _mock.resolveDispute(disputeId);
    await _dio.post<dynamic>(ceoResolveDisputePath(disputeId), data: const {}, options: Options(headers: _auth(token)));
  }

  /// Route builder kept static so tests can assert the id is interpolated and
  /// no path ever contains a dangling '//' (historical concat-bug class).
  static String ceoResolveDisputePath(String disputeId) => '/api/ceo/dispute/$disputeId/resolve';

  /// §11.5 customer-side ticket creation (mock for now; wire to the real
  /// disputes endpoint when deployed).
  Future<Dispute> openDispute(String token, String orderId, String reason) async {
    if (isMock) return _mock.openDispute(orderId, reason);
    final r = await _dio.post<dynamic>('/api/customer/dispute',
        data: {'orderId': orderId, 'reason': reason}, options: Options(headers: _auth(token)));
    return Dispute.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> createPromo(String token, String label, int discountPct, int maxUses) async {
    if (isMock) return _mock.createPromo(label, discountPct, maxUses);
    await _dio.post<dynamic>('/api/ceo/promo',
        data: {'label': label, 'discountPct': discountPct, 'maxUses': maxUses},
        options: Options(headers: _auth(token)));
  }

  // ================= Sefer Rounds =================
  Future<List<SeferRound>> roundsForHub(String hub) async {
    if (isMock) return _mock.roundsForHub(hub);
    try {
      final data = await _get('/api/rounds?hub=$hub', '');
      return (data as List).map((e) => SeferRound(
            id: e['id'] as String? ?? '',
            hub: e['hub'] as String? ?? hub,
            label: e['label'] as String? ?? '',
            departureAt: DateTime.tryParse(e['departureAt'] as String? ?? ''),
            memberCount: (e['memberCount'] as num?)?.toInt() ?? 0,
            perHeadFeeEtb: (e['perHeadFeeEtb'] as num?)?.toInt() ?? 0,
            joinable: e['joinable'] as bool? ?? true,
          )).toList();
    } on ApiException {
      return const []; // hide UI gracefully on 404 until live
    }
  }

  static Map<String, dynamic> _configToJson(AppConfig c) => {
    'serviceFee': c.serviceFee,
    'deliveryFee2km': c.deliveryFee2km,
    'deliveryFee5km': c.deliveryFee5km,
    'deliveryFee8km': c.deliveryFee8km,
    'footFee': c.footFee,
    'rainSurge': c.rainSurge,
    'bunaRunFee': c.bunaRunFee,
    'bunaMaxOrder': c.bunaMaxOrder,
    'bunaMaxKm': c.bunaMaxKm,
    'courierSharePct': c.courierSharePct,
    'courierTipsPct': c.courierTipsPct,
    'codFloatCap': c.codFloatCap,
    'codSettlementHours': c.codSettlementHours,
    'commissionPct': c.commissionPct,
    'restaurantOfTheDayCommissionPct': c.restaurantOfTheDayCommissionPct,
    'ackTimeoutSeconds': c.ackTimeoutSeconds,
    'smsProvider': c.smsProvider,
    'smsCostEtb': c.smsCostEtb,
    'rainMode': c.rainMode,
    'fastingOverride': c.fastingOverride,
    'vehicleCurfew': c.vehicleCurfew,
    'restaurantOfTheDayId': c.restaurantOfTheDayId,
    'inflationPct': c.inflationPct,
    'feeMultiplier': c.feeMultiplier,
  };
}