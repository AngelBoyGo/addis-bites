enum OrderStatus {
  placed,
  merchantAck,
  preparing,
  courierAssigned,
  pickedUp,
  enRoute,
  arrived,
  delivered,
  cancelled;

  static OrderStatus fromWire(String? s) => OrderStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => OrderStatus.placed,
  );

  /// §4 wire value (matches `status` in the API).
  String get wire => name;

  /// User-facing progress index (spec order stepper): received → kitchen →
  /// rider en route → arrived → delivered. cancelled short-circuits.
  int get stepIndex {
    switch (this) {
      case OrderStatus.placed:
      case OrderStatus.merchantAck:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.courierAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.enRoute:
        return 2;
      case OrderStatus.arrived:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

enum PaymentStatus { pending, confirmed, failed, refunded, codPending }

extension PaymentStatusX on PaymentStatus {
  /// §4 wire value (matches `paymentStatus` in the API).
  String get wire => switch (this) {
    PaymentStatus.pending => 'pending',
    PaymentStatus.confirmed => 'confirmed',
    PaymentStatus.failed => 'failed',
    PaymentStatus.refunded => 'refunded',
    PaymentStatus.codPending => 'cod_pending',
  };
}

class OrderItemLine {
  const OrderItemLine({
    required this.nameEn,
    required this.nameAm,
    required this.qty,
    required this.price,
    this.injera = 0,
    this.spice = 0,
  });

  final String nameEn;
  final String nameAm;
  final int qty;
  final int price;
  final int injera;
  final int spice;

  int get lineTotal => qty * price;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) => OrderItemLine(
    nameEn: json['nameEn'] as String? ?? '',
    nameAm: json['nameAm'] as String? ?? '',
    qty: (json['qty'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toInt() ?? 0,
    injera: (json['injera'] as num?)?.toInt() ?? 0,
    spice: (json['spice'] as num?)?.toInt() ?? 0,
  );

  /// §4 wire serialization for an order line item.
  Map<String, dynamic> toJson() => {
    'nameEn': nameEn,
    'nameAm': nameAm,
    'qty': qty,
    'price': price,
    'injera': injera,
    'spice': spice,
  };
}

class Order {
  const Order({
    required this.id,
    required this.merchantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.surge,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentRef,
    required this.status,
    required this.createdAt,
    this.phone = '',
    this.courierName,
    this.courierPhone,
    this.courierVehicle,
    this.ackDeadlineAt,
    this.smsFallbackSent = false,
    this.landmarkText = '',
    this.plusCode = '',
    this.subCity = '',
    this.sefer = '',
    this.lat,
    this.lng,
    this.settlementBatch = '',
  });

  final String id;
  final String merchantName;
  final List<OrderItemLine> items;
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final int surge;
  final int total;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentRef;
  final OrderStatus status;
  final DateTime? createdAt;
  final String phone;
  final String? courierName;
  final String? courierPhone;
  final String? courierVehicle;
  final DateTime? ackDeadlineAt;
  final bool smsFallbackSent;
  final String landmarkText;
  final String plusCode;
  final String subCity;
  final String sefer;
  final double? lat;
  final double? lng;
  final String settlementBatch;

  bool get isCancelled => status == OrderStatus.cancelled;

  Order copyWith({
    OrderStatus? status,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
    DateTime? ackDeadlineAt,
    bool? smsFallbackSent,
  }) => Order(
    id: id,
    merchantName: merchantName,
    items: items,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    serviceFee: serviceFee,
    surge: surge,
    total: total,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    paymentRef: paymentRef,
    status: status ?? this.status,
    createdAt: createdAt,
    phone: phone,
    courierName: courierName ?? this.courierName,
    courierPhone: courierPhone ?? this.courierPhone,
    courierVehicle: courierVehicle ?? this.courierVehicle,
    ackDeadlineAt: ackDeadlineAt ?? this.ackDeadlineAt,
    smsFallbackSent: smsFallbackSent ?? this.smsFallbackSent,
    landmarkText: landmarkText,
    plusCode: plusCode,
    subCity: subCity,
    sefer: sefer,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    settlementBatch: settlementBatch,
  );

  Order copyWithCourier({String? name, String? phone, String? vehicle}) =>
      copyWith(courierName: name, courierPhone: phone, courierVehicle: vehicle);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String? ?? '',
    merchantName: json['merchantName'] as String? ?? '',
    items: ((json['items'] as List?) ?? const [])
        .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
    serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
    surge: (json['surge'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    paymentMethod: json['paymentMethod'] as String? ?? 'cod',
    paymentStatus: switch (json['paymentStatus'] as String?) {
      'confirmed' => PaymentStatus.confirmed,
      'refunded' => PaymentStatus.refunded,
      'failed' => PaymentStatus.failed,
      'cod_pending' => PaymentStatus.codPending,
      _ => PaymentStatus.pending,
    },
    paymentRef: json['paymentRef'] as String?,
    status: OrderStatus.fromWire(json['status'] as String?),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    phone: json['phone'] as String? ?? '',
    courierName: json['courierName'] as String?,
    courierPhone: json['courierPhone'] as String?,
    courierVehicle: json['courierVehicle'] as String?,
    ackDeadlineAt: DateTime.tryParse(json['ackDeadlineAt'] as String? ?? ''),
    smsFallbackSent: json['smsFallbackSent'] as bool? ?? false,
    landmarkText: json['landmarkText'] as String? ?? '',
    plusCode: json['plusCode'] as String? ?? '',
    subCity: json['subCity'] as String? ?? '',
    sefer: json['sefer'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    settlementBatch: json['settlementBatch'] as String? ?? '',
  );

  /// §4 wire serialization (keys match the server contract exactly).
  Map<String, dynamic> toJson() => {
    'id': id,
    'merchantName': merchantName,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'serviceFee': serviceFee,
    'surge': surge,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus.wire,
    if (paymentRef != null) 'paymentRef': paymentRef,
    'status': status.wire,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'phone': phone,
    if (courierName != null) 'courierName': courierName,
    if (courierPhone != null) 'courierPhone': courierPhone,
    if (courierVehicle != null) 'courierVehicle': courierVehicle,
    if (ackDeadlineAt != null) 'ackDeadlineAt': ackDeadlineAt!.toIso8601String(),
    'smsFallbackSent': smsFallbackSent,
    'landmarkText': landmarkText,
    'plusCode': plusCode,
    'subCity': subCity,
    'sefer': sefer,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    'settlementBatch': settlementBatch,
  };
}