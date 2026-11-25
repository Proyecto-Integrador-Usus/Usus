import 'package:flutter/foundation.dart';

import '../../catalog/domain/rental_product.dart';
import '../domain/cart_item.dart';
import '../../rentals/domain/rental_period.dart';

enum DeliveryMethod {
  pickup('Recoger con el arrendador', 0),
  delivery('Envío a domicilio', 120);

  const DeliveryMethod(this.label, this.baseCost);
  final String label;
  final double baseCost;
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;

  List<CartItem> get items => _items.values.toList(growable: false);
  bool get isEmpty => _items.isEmpty;
  int get distinctCount => _items.values.map((item) => item.product.id).toSet().length;
  int get totalUnits =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  DeliveryMethod get deliveryMethod => _deliveryMethod;

  double get rentalSubtotal =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  double get depositTotal => _items.values.fold(
    0, (sum, item) => sum + item.product.deposit * item.quantity,
  );

  double get shippingCost =>
      _items.isEmpty ? 0 : _deliveryMethod.baseCost;

  double get total => rentalSubtotal + shippingCost;

  void addProduct(RentalProduct product, {RentalPeriod? period}) {
    final line = CartItem(product: product, period: period);
    final existing = _items[line.lineId];
    if (existing != null) {
      _items[line.lineId] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      _items[line.lineId] = line;
    }
    notifyListeners();
  }

  void updateQuantity(String lineId, int quantity) {
    final existing = _items[lineId];
    if (existing == null) return;
    if (quantity <= 0) {
      _items.remove(lineId);
    } else {
      _items[lineId] = existing.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void updateDays(String lineId, int days) {
    final existing = _items[lineId];
    if (existing == null || existing.period != null || days < 1) return;
    _items[lineId] = existing.copyWith(days: days);
    notifyListeners();
  }

  void removeProduct(String lineId) {
    if (_items.remove(lineId) != null) {
      notifyListeners();
    }
  }

  void setDeliveryMethod(DeliveryMethod method) {
    if (_deliveryMethod == method) return;
    _deliveryMethod = method;
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty && _deliveryMethod == DeliveryMethod.pickup) return;
    _items.clear();
    _deliveryMethod = DeliveryMethod.pickup;
    notifyListeners();
  }
}
