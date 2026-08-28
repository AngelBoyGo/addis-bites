import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/menu.dart';

/// Local-only cart (editable fully offline). Line key = item + injera + spice.
final cartProvider = StateNotifierProvider<CartNotifier, Cart>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart());

  void add(MenuItem item, {int qty = 1, int injeraCount = 0, int spice = 0}) {
    state = state.withLine(CartLine(
      item: item,
      qty: qty,
      injeraCount: injeraCount,
      spice: spice,
    ));
  }

  void setQty(String lineKey, int qty) => state = state.setQty(lineKey, qty);

  void setBand(DeliveryBand band) => state = state.copyWith(band: band);

  void setMeetPoint(bool v) => state = state.copyWith(meetPoint: v, pickup: v ? false : state.pickup);
  void setPickup(bool v) => state = state.copyWith(pickup: v, meetPoint: v ? false : state.meetPoint);
  void setScheduleAhead(bool v) => state = state.copyWith(scheduleAhead: v);
  void setRound(String? id) => state = state.copyWith(roundId: id);
  void setDigitalPay(bool v) => state = state.copyWith(digitalPayDiscount: v);

  void clear() => state = state.clear();
}