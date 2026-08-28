/// Merchant-console models: live queue + menu availability (86'ing),
/// plus admin/CEO/foot-carrier/Sefer-Round domain fixtures.
library;

import 'catalog.dart';
import 'order.dart';

class MerchantOrder {
  final Order order;
  final DateTime ackDeadlineAt;
  final bool smsFallbackSent;

  const MerchantOrder({
    required this.order,
    required this.ackDeadlineAt,
    this.smsFallbackSent = false,
  });

  int get ackSecondsLeft =>
      ackDeadlineAt.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31).toInt();

  factory MerchantOrder.fromJson(Map<String, dynamic> json) => MerchantOrder(
    order: Order.fromJson(json),
    ackDeadlineAt: DateTime.tryParse(json['ackDeadlineAt'] as String? ?? '') ??
        DateTime.now().add(const Duration(seconds: 90)),
    smsFallbackSent: json['smsFallbackSent'] as bool? ?? false,
  );
}

class MenuAvailabilityToggle {
  final String itemId;
  final bool isAvailable;

  const MenuAvailabilityToggle({required this.itemId, required this.isAvailable});
}

class OcrDraftItem {
  final String nameEn;
  final String nameAm;
  final int priceEtb;
  final bool isTsom;
  final String category;

  const OcrDraftItem({
    required this.nameEn,
    required this.nameAm,
    required this.priceEtb,
    required this.isTsom,
    required this.category,
  });
}

class OcrStaging {
  final String id;
  final String merchantId;
  final double confidence;
  final List<OcrDraftItem> items;
  final String status;

  const OcrStaging({
    required this.id,
    required this.merchantId,
    required this.confidence,
    required this.items,
    required this.status,
  });
}

// ---- admin ----
class MerchantApplication {
  final String id;
  final String ownerName;
  final String phone;
  final String businessName;
  final String subCity;
  final String sefer;
  final bool acceptsCash;
  final bool acceptsChapa;
  final bool tsomCertified;
  final bool halalCertified;
  final String? photoB64;
  final String status;

  const MerchantApplication({
    required this.id,
    required this.ownerName,
    required this.phone,
    required this.businessName,
    required this.subCity,
    required this.sefer,
    required this.acceptsCash,
    required this.acceptsChapa,
    required this.tsomCertified,
    required this.halalCertified,
    this.photoB64,
    required this.status,
  });

  factory MerchantApplication.fromJson(Map<String, dynamic> json) => MerchantApplication(
    id: json['id'] as String? ?? '',
    ownerName: json['ownerName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    businessName: json['businessName'] as String? ?? '',
    subCity: json['subCity'] as String? ?? '',
    sefer: json['sefer'] as String? ?? '',
    acceptsCash: json['acceptsCash'] as bool? ?? true,
    acceptsChapa: json['acceptsChapa'] as bool? ?? true,
    tsomCertified: json['tsomCertified'] as bool? ?? false,
    halalCertified: json['halalCertified'] as bool? ?? false,
    photoB64: json['photoB64'] as String?,
    status: json['status'] as String? ?? 'pending',
  );
}

class OtpLogEntry {
  final String phone;
  final String channel;
  final String provider;
  final DateTime? createdAt;
  final bool used;

  const OtpLogEntry({
    required this.phone,
    required this.channel,
    required this.provider,
    this.createdAt,
    required this.used,
  });

  factory OtpLogEntry.fromJson(Map<String, dynamic> json) => OtpLogEntry(
    phone: json['phone'] as String? ?? '',
    channel: json['channel'] as String? ?? '',
    provider: json['provider'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    used: json['used'] as bool? ?? false,
  );
}

class ChannelStatus {
  final String provider;
  final bool demo;
  final List<String> missingSecrets;

  const ChannelStatus({
    required this.provider,
    required this.demo,
    required this.missingSecrets,
  });
}

class AdminSnapshot {
  final int ordersToday;
  final int gmvEtb;
  final int activeCouriers;
  final List<Order> liveOrders;
  final List<MerchantApplication> merchantApplications;
  final List<OcrStaging> ocrQueue;
  final List<OtpLogEntry> otpLog;
  final ChannelStatus channelStatus;
  final AppConfig config;

  const AdminSnapshot({
    required this.ordersToday,
    required this.gmvEtb,
    required this.activeCouriers,
    required this.liveOrders,
    required this.merchantApplications,
    required this.ocrQueue,
    required this.otpLog,
    required this.channelStatus,
    required this.config,
  });
}

// ---- foot carrier ----
class FootStatus {
  final bool signupComplete;
  final bool orientationComplete;
  final bool earningToday;
  final double radiusKm;
  final int missed;
  final String phone;

  const FootStatus({
    required this.signupComplete,
    required this.orientationComplete,
    required this.earningToday,
    required this.radiusKm,
    required this.missed,
    required this.phone,
  });

  bool get canStartEarning => signupComplete && orientationComplete;
}

class FootBonus {
  final String kind;
  final int amountEtb;
  final int deliveredEtb;
  final String status;

  const FootBonus({
    required this.kind,
    required this.amountEtb,
    required this.deliveredEtb,
    required this.status,
  });

  factory FootBonus.fromJson(Map<String, dynamic> json) => FootBonus(
    kind: json['kind'] as String? ?? '',
    amountEtb: (json['amountEtb'] as num?)?.toInt() ?? 0,
    deliveredEtb: (json['deliveredEtb'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'pending',
  );
}

class FootEarnings {
  final int walletBalanceEtb;
  final List<FootBonus> bonuses;
  final List<Order> trips;
  final Order? activeOrder;

  const FootEarnings({
    required this.walletBalanceEtb,
    required this.bonuses,
    required this.trips,
    this.activeOrder,
  });

  factory FootEarnings.fromJson(Map<String, dynamic> json) => FootEarnings(
    walletBalanceEtb: (json['walletBalanceEtb'] as num?)?.toInt() ?? 0,
    bonuses: ((json['bonuses'] as List?) ?? const [])
        .map((e) => FootBonus.fromJson(e as Map<String, dynamic>))
        .toList(),
    trips: ((json['trips'] as List?) ?? const [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList(),
    activeOrder: json['activeOrder'] == null
        ? null
        : Order.fromJson(json['activeOrder'] as Map<String, dynamic>),
  );
}

// ---- CEO ----
class Dispute {
  final String id;
  final String orderId;
  final String reason;
  final String status;
  final String? resolution;

  const Dispute({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    this.resolution,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
    id: json['id'] as String? ?? '',
    orderId: json['orderId'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    resolution: json['resolution'] as String?,
  );
}

class Promotion {
  final String id;
  final String label;
  final int discountPct;
  final int maxUses;
  final int uses;
  final bool active;

  const Promotion({
    required this.id,
    required this.label,
    required this.discountPct,
    required this.maxUses,
    required this.uses,
    required this.active,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    discountPct: (json['discountPct'] as num?)?.toInt() ?? 0,
    maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
    uses: (json['uses'] as num?)?.toInt() ?? 0,
    active: json['active'] as bool? ?? true,
  );
}

class CeoDashboard {
  final int gmvEtb;
  final int orders;
  final double codSharePct;
  final int drivers;
  final int customers;
  final double inflationPct;
  final double feeMultiplier;
  final List<Dispute> disputes;
  final List<Promotion> promotions;

  const CeoDashboard({
    required this.gmvEtb,
    required this.orders,
    required this.codSharePct,
    required this.drivers,
    required this.customers,
    required this.inflationPct,
    required this.feeMultiplier,
    required this.disputes,
    required this.promotions,
  });
}

// ---- refund tracker (guardrail 1) ----
class RefundTracker {
  final String orderId;
  final String refCode;
  final String status; // Initiated -> Processing -> Returned
  final DateTime createdAt;

  const RefundTracker({
    required this.orderId,
    required this.refCode,
    required this.status,
    required this.createdAt,
  });
}

// ---- Sefer Rounds (savings engine) ----
class SeferRound {
  final String id;
  final String hub;
  final String label;
  final DateTime? departureAt;
  final int memberCount;
  final int perHeadFeeEtb;
  final bool joinable;

  const SeferRound({
    required this.id,
    required this.hub,
    required this.label,
    this.departureAt,
    required this.memberCount,
    required this.perHeadFeeEtb,
    required this.joinable,
  });

  int feeIfNext(int joinableDelta) => (perHeadFeeEtb - joinableDelta).clamp(0, 1 << 30);
}