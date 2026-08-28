import 'role_dashboards.dart';

/// Backend services models (tech-spec §3.3–§3.6): trust & safety, finance,
/// hubs/gear, identity (Fayda), and dispatch. These power the Support and
/// Finance role consoles integrated into the same app.

// ---- Trust & Safety (strike engine, misconduct, suspensions) ----
enum StrikeLevel { warning, suspendWeek, suspendMonth, permanent }

extension StrikeLevelX on StrikeLevel {
  String get label => switch (this) {
    StrikeLevel.warning => '1st — Formal warning',
    StrikeLevel.suspendWeek => '2nd — Suspended 1 week',
    StrikeLevel.suspendMonth => '3rd — Suspended 1 month',
    StrikeLevel.permanent => '4th — Permanent removal',
  };
}

class StrikeRecord {
  final String subjectType; // courier | restaurant | customer
  final String subjectId;
  final int validatedCount; // 1..4
  final StrikeLevel level;
  final DateTime issuedAt;

  const StrikeRecord({
    required this.subjectType,
    required this.subjectId,
    required this.validatedCount,
    required this.level,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() => {
    'subjectType': subjectType,
    'subjectId': subjectId,
    'validatedCount': validatedCount,
    'level': level.name,
    'issuedAt': issuedAt.toIso8601String(),
  };

  factory StrikeRecord.fromJson(Map<String, dynamic> j) => StrikeRecord(
    subjectType: j['subjectType'] as String? ?? '',
    subjectId: j['subjectId'] as String? ?? '',
    validatedCount: (j['validatedCount'] as num?)?.toInt() ?? 1,
    level: StrikeLevel.values.firstWhere((e) => e.name == j['level'], orElse: () => StrikeLevel.warning),
    issuedAt: DateTime.tryParse(j['issuedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class MisconductReport {
  final String id;
  final String orderId;
  final String reporterType; // courier | customer | restaurant
  final String subjectType;
  final String subjectId;
  final String category;
  final String status; // open | validated | rejected | duplicate

  const MisconductReport({
    required this.id,
    required this.orderId,
    required this.reporterType,
    required this.subjectType,
    required this.subjectId,
    required this.category,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'reporterType': reporterType,
    'subjectType': subjectType,
    'subjectId': subjectId,
    'category': category,
    'status': status,
  };

  factory MisconductReport.fromJson(Map<String, dynamic> j) => MisconductReport(
    id: j['id'] as String? ?? '',
    orderId: j['orderId'] as String? ?? '',
    reporterType: j['reporterType'] as String? ?? '',
    subjectType: j['subjectType'] as String? ?? '',
    subjectId: j['subjectId'] as String? ?? '',
    category: j['category'] as String? ?? '',
    status: j['status'] as String? ?? 'open',
  );
}

// ---- Finance (payout batches, ledger, refunds) ----
class PayoutBatch {
  final String id;
  final String method; // telebirr_b2c | bank_transfer
  final String status; // pending | sent | confirmed | failed
  final int totalEtb;
  final int count;
  final DateTime scheduledFor;

  const PayoutBatch({
    required this.id,
    required this.method,
    required this.status,
    required this.totalEtb,
    required this.count,
    required this.scheduledFor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'status': status,
    'totalEtb': totalEtb,
    'count': count,
    'scheduledFor': scheduledFor.toIso8601String(),
  };

  factory PayoutBatch.fromJson(Map<String, dynamic> j) => PayoutBatch(
    id: j['id'] as String? ?? '',
    method: j['method'] as String? ?? 'telebirr_b2c',
    status: j['status'] as String? ?? 'pending',
    totalEtb: (j['totalEtb'] as num?)?.toInt() ?? 0,
    count: (j['count'] as num?)?.toInt() ?? 0,
    scheduledFor: DateTime.tryParse(j['scheduledFor'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Double-entry ledger entry. Sums to zero per txnId.
class LedgerEntry {
  final String txnId;
  final String account; // courier:x | merchant:y | platform:fees | cod_float:x | tax:vat
  final int debit;
  final int credit;
  final String? orderId;

  const LedgerEntry({
    required this.txnId,
    required this.account,
    required this.debit,
    required this.credit,
    this.orderId,
  });

  int get signed => credit - debit;

  Map<String, dynamic> toJson() => {
    'txnId': txnId,
    'account': account,
    'debit': debit,
    'credit': credit,
    if (orderId != null) 'orderId': orderId,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
    txnId: j['txnId'] as String? ?? '',
    account: j['account'] as String? ?? '',
    debit: (j['debit'] as num?)?.toInt() ?? 0,
    credit: (j['credit'] as num?)?.toInt() ?? 0,
    orderId: j['orderId'] as String?,
  );
}

class RefundRecord {
  final String id;
  final String orderId;
  final int amountEtb;
  final String status; // requested | under_review | approved | rejected | paid
  final DateTime created;

  const RefundRecord({
    required this.id,
    required this.orderId,
    required this.amountEtb,
    required this.status,
    required this.created,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'amountEtb': amountEtb,
    'status': status,
    'created': created.toIso8601String(),
  };

  factory RefundRecord.fromJson(Map<String, dynamic> j) => RefundRecord(
    id: j['id'] as String? ?? '',
    orderId: j['orderId'] as String? ?? '',
    amountEtb: (j['amountEtb'] as num?)?.toInt() ?? 0,
    status: j['status'] as String? ?? 'requested',
    created: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
  );
}

// ---- Hubs & gear custody ----
class Hub {
  final String id;
  final String name;
  final String zone;
  final int runners;
  final int equipmentReturnPct;

  const Hub({required this.id, required this.name, required this.zone, required this.runners, required this.equipmentReturnPct});
}

/// Gear custody trail item (loaner phone / vest / thermal box …).
class GearRecord {
  final String item;
  final String serial;
  final String status; // checked_out | returned
  final String? courierId;

  const GearRecord({required this.item, required this.serial, required this.status, this.courierId});
}

// ---- Identity / KYC (Fayda) ----
class KycStatus {
  final String faydaVerifiedAt;
  final String kycLevel; // none | introducer | fayda_full

  const KycStatus({required this.faydaVerifiedAt, required this.kycLevel});
}

// ---- Aggregate dashboards ----
class FinanceDashboard {
  final int ledgerImbalance; // must be 0
  final int unreconciled24h;
  final List<PayoutBatch> batches;
  final List<LedgerEntry> ledger;
  final int payoutFailureCount;
  final double takeRateNetPromos; // percent

  const FinanceDashboard({
    required this.ledgerImbalance,
    required this.unreconciled24h,
    required this.batches,
    required this.ledger,
    required this.payoutFailureCount,
    required this.takeRateNetPromos,
  });
}

class SupportDashboard {
  final List<MisconductReport> reports;
  final List<StrikeRecord> strikes;
  final List<RefundRecord> refunds;
  final List<Dispute> disputes;
  final int firstResponseMin;
  final int resolutionHours;

  const SupportDashboard({
    required this.reports,
    required this.strikes,
    required this.refunds,
    required this.disputes,
    required this.firstResponseMin,
    required this.resolutionHours,
  });
}