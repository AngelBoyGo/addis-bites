/**
 * Addis Bites — canonical Support & Finance wire shapes.
 *
 * Single source of truth for the JSON returned by the Support and Finance
 * console routes. BOTH the D1-backed queries and the in-memory fallback in
 * index.js emit these shapes, so HTTP output is byte-identical regardless of
 * the storage backend.
 *
 * Mirrors the field names/types the Flutter client parses in
 * lib/models/backend_services.dart and lib/core/api_client.dart.
 * All money values are INTEGER ETB (never floats); timestamps are ISO-8601.
 */

export function report(r) {
  return {
    id: r.id,
    orderId: r.orderId,
    reporterType: r.reporterType,
    subjectType: r.subjectType,
    subjectId: r.subjectId,
    category: r.category,
    status: r.status
  };
}

export function strike(s) {
  return {
    subjectType: s.subjectType,
    subjectId: s.subjectId,
    validatedCount: s.validatedCount,
    level: s.level,
    issuedAt: s.issuedAt
  };
}

export function refund(f) {
  return {
    id: f.id,
    orderId: f.orderId,
    amountEtb: f.amountEtb,
    status: f.status,
    created: f.created
  };
}

export function batch(b) {
  return {
    id: b.id,
    method: b.method,
    status: b.status,
    totalEtb: b.totalEtb,
    count: b.count,
    scheduledFor: b.scheduledFor
  };
}

export function ledgerEntry(e) {
  return {
    txnId: e.txnId,
    account: e.account,
    debit: e.debit,
    credit: e.credit,
    orderId: e.orderId
  };
}

export function dispute(d) {
  return {
    id: d.id,
    orderId: d.orderId,
    reason: d.reason,
    status: d.status,
    resolution: d.resolution
  };
}

export function supportDashboard(d) {
  return {
    reports: (d.reports || []).map(report),
    strikes: (d.strikes || []).map(strike),
    refunds: (d.refunds || []).map(refund),
    disputes: (d.disputes || []).map(dispute),
    firstResponseMin: d.firstResponseMin,
    resolutionHours: d.resolutionHours
  };
}

export function financeDashboard(d) {
  return {
    ledgerImbalance: d.ledgerImbalance,
    unreconciled24h: d.unreconciled24h,
    batches: (d.batches || []).map(batch),
    ledger: (d.ledger || []).map(ledgerEntry),
    payoutFailureCount: d.payoutFailureCount,
    takeRateNetPromos: d.takeRateNetPromos
  };
}

// ---- Merchant console (live queue + menu availability) ----
// A merchant-queue entry is a §4 Order payload plus the ack/sms fields the
// Dart MerchantOrder.fromJson reads at the top level.
export function order(o) {
  return {
    id: o.id,
    merchantName: o.merchantName,
    items: o.items || [],
    subtotal: o.subtotal,
    deliveryFee: o.deliveryFee,
    serviceFee: o.serviceFee,
    surge: o.surge,
    total: o.total,
    paymentMethod: o.paymentMethod,
    paymentStatus: o.paymentStatus,
    paymentRef: o.paymentRef ?? null,
    status: o.status,
    createdAt: o.createdAt,
    phone: o.phone ?? '',
    courierName: o.courierName ?? null,
    courierPhone: o.courierPhone ?? null,
    courierVehicle: o.courierVehicle ?? null,
    ackDeadlineAt: o.ackDeadlineAt ?? null,
    smsFallbackSent: o.smsFallbackSent === true,
    landmarkText: o.landmarkText ?? '',
    plusCode: o.plusCode ?? '',
    subCity: o.subCity ?? '',
    sefer: o.sefer ?? '',
    lat: o.lat ?? null,
    lng: o.lng ?? null,
    settlementBatch: o.settlementBatch ?? ''
  };
}

export function merchantOrderEntry(e) {
  return { ...order(e), ackDeadlineAt: e.ackDeadlineAt ?? e.order?.ackDeadlineAt ?? null, smsFallbackSent: e.smsFallbackSent === true };
}

// ---- Admin helpers ----
export function merchantApplicationRow(a) {
  return {
    id: a.id,
    ownerName: a.ownerName,
    phone: a.phone,
    businessName: a.businessName,
    subCity: a.subCity,
    sefer: a.sefer,
    acceptsCash: a.acceptsCash === true,
    acceptsChapa: a.acceptsChapa === true,
    tsomCertified: a.tsomCertified === true,
    halalCertified: a.halalCertified === true,
    photoB64: a.photoB64 ?? null,
    status: a.status
  };
}

export function otpLogRow(e) {
  return { phone: e.phone, channel: e.channel, provider: e.provider, createdAt: e.createdAt, used: e.used === true };
}

export function adminSnapshot(s) {
  return {
    ordersToday: s.ordersToday,
    gmvEtb: s.gmvEtb,
    activeCouriers: s.activeCouriers,
    liveOrders: (s.liveOrders || []).map(order),
    merchantApplications: (s.merchantApplications || []).map(merchantApplicationRow),
    ocrQueue: s.ocrQueue || [],
    otpLog: (s.otpLog || []).map(otpLogRow),
    channelStatus: s.channelStatus,
    config: s.config
  };
}

// ---- CEO helpers ----
export function promoRow(p) {
  return {
    id: p.id,
    label: p.label,
    discountPct: p.discountPct,
    maxUses: p.maxUses,
    uses: p.uses,
    active: p.active === true
  };
}

export function ceoDashboard(d) {
  return {
    gmvEtb: d.gmvEtb,
    orders: d.orders,
    codSharePct: d.codSharePct,
    drivers: d.drivers,
    customers: d.customers,
    inflationPct: d.inflationPct,
    feeMultiplier: d.feeMultiplier,
    disputes: (d.disputes || []).map(dispute),
    promotions: (d.promotions || []).map(promoRow)
  };
}

// ---- Foot earnings (client parses only walletBalanceEtb) ----
export function footEarnings(e) {
  return { walletBalanceEtb: e.walletBalanceEtb, bonuses: e.bonuses || [], trips: (e.trips || []).map(order) };
}