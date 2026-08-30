import 'menu.dart';

/// A configured cart line. The "line key" = itemId + injeraCount + spice, so the
/// same item with different configuration splits into separate lines (per spec).
class CartLine {
  const CartLine({
    required this.item,
    required this.qty,
    this.injeraCount = 0,
    this.spice = 0,
  });

  final MenuItem item;
  final int qty;
  final int injeraCount;
  final int spice;

  CartLine copyWith({int? qty, int? injeraCount, int? spice}) => CartLine(
    item: item,
    qty: qty ?? this.qty,
    injeraCount: injeraCount ?? this.injeraCount,
    spice: spice ?? this.spice,
  );

  String get key => '${item.id}|$injeraCount|$spice';
  int get lineTotal => qty * item.priceEtb;
}

enum DeliveryBand { foot, under2, mid5, far8 }

extension DeliveryBandX on DeliveryBand {
  String get id => switch (this) {
    DeliveryBand.foot => 'foot',
    DeliveryBand.under2 => '0-2',
    DeliveryBand.mid5 => '2-5',
    DeliveryBand.far8 => '5-8',
  };
}

class Cart {
  const Cart({
    this.lines = const [],
    this.merchantId,
    this.band = DeliveryBand.under2,
    this.isBuna = false,
    this.meetPoint = false,
    this.pickup = false,
    this.scheduleAhead = false,
    this.roundId,
    this.digitalPayDiscount = false,
  });

  final List<CartLine> lines;
  final String? merchantId; // a cart is pinned to one restaurant in this model
  final DeliveryBand band;
  final bool isBuna;
  final bool meetPoint; // meet courier at hub landmark → save 10-15 ETB
  final bool pickup; // 0 ETB delivery, skip-the-line QR
  final bool scheduleAhead; // order ≥60 min ahead → reduced fee
  final String? roundId; // join a Sefer Round (batch) → fee split
  final bool digitalPayDiscount; // Chapa/Telebirr → −8 ETB

  int get subtotal => lines.fold(0, (s, l) => s + l.lineTotal);
  int get totalQty => lines.fold(0, (s, l) => s + l.qty);
  bool get isEmpty => lines.isEmpty;

  Cart withLine(CartLine line) {
    final exists = lines.indexWhere((l) => l.key == line.key);
    final newLines = [...lines];
    if (exists >= 0) {
      newLines[exists] = newLines[exists].copyWith(qty: newLines[exists].qty + line.qty);
    } else {
      newLines.add(line);
    }
    return Cart(
      lines: newLines,
      merchantId: merchantId ?? line.item.merchantId,
      band: band,
      isBuna: isBuna,
      meetPoint: meetPoint,
      pickup: pickup,
      scheduleAhead: scheduleAhead,
      roundId: roundId,
      digitalPayDiscount: digitalPayDiscount,
    );
  }

  Cart setQty(String key, int qty) => Cart(
    lines: [
      for (final l in lines)
        if (l.key == key)
          if (qty <= 0) ...<CartLine>[] else l.copyWith(qty: qty)
        else
          l,
    ],
    merchantId: merchantId,
    band: band,
    isBuna: isBuna,
    meetPoint: meetPoint,
    pickup: pickup,
    scheduleAhead: scheduleAhead,
    roundId: roundId,
    digitalPayDiscount: digitalPayDiscount,
  );

  Cart clear() => const Cart();

  Cart copyWith({
    List<CartLine>? lines,
    String? merchantId,
    DeliveryBand? band,
    bool? isBuna,
    bool? meetPoint,
    bool? pickup,
    bool? scheduleAhead,
    String? roundId,
    bool? digitalPayDiscount,
  }) =>
      Cart(
        lines: lines ?? this.lines,
        merchantId: merchantId ?? this.merchantId,
        band: band ?? this.band,
        isBuna: isBuna ?? this.isBuna,
        meetPoint: meetPoint ?? this.meetPoint,
        pickup: pickup ?? this.pickup,
        scheduleAhead: scheduleAhead ?? this.scheduleAhead,
        roundId: roundId ?? this.roundId,
        digitalPayDiscount: digitalPayDiscount ?? this.digitalPayDiscount,
      );
}