import 'package:addis_bites/core/order_status_machine.dart';
import 'package:addis_bites/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatusMachine valid transitions (spec §3.4 lifecycle)', () {
    test('applies the full happy-path chain in order', () {
      var s = OrderStatus.placed;
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.merchantAck);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.preparing);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.courierAssigned);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.pickedUp);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.enRoute);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.arrived);
      s = OrderStatusMachine.advance(s)!;
      expect(s, OrderStatus.delivered);
      expect(OrderStatusMachine.advance(OrderStatus.delivered), isNull);
    });

    test('cancelled is terminal and cannot advance', () {
      expect(OrderStatusMachine.advance(OrderStatus.cancelled), isNull);
    });

    test('cancelled can be reached from active states', () {
      expect(OrderStatusMachine.allows(OrderStatus.preparing, OrderStatus.cancelled), isTrue);
      expect(OrderStatusMachine.allows(OrderStatus.placed, OrderStatus.cancelled), isTrue);
    });

    test('courier assigned cannot jump straight to delivered (must pass pickup/enRoute)', () {
      expect(OrderStatusMachine.allows(OrderStatus.courierAssigned, OrderStatus.delivered), isFalse);
      expect(OrderStatusMachine.allows(OrderStatus.enRoute, OrderStatus.delivered), isFalse);
    });

    test('delivered cannot go back to preparing (no regression)', () {
      expect(OrderStatusMachine.allows(OrderStatus.delivered, OrderStatus.preparing), isFalse);
    });
  });
}