import 'package:flutter/foundation.dart';

import '../../catalog/domain/rental_product.dart';
import '../domain/cart_item.dart';

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
  int get distinctCount => _items.length;
  int get totalUnits =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  DeliveryMethod get deliveryMethod => _deliveryMethod;

  double get rentalSubtotal =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  double get shippingCost =>
      _items.isEmpty ? 0 : _deliveryMethod.baseCost;

  double get total => rentalSubtotal + shippingCost;

  void addProduct(RentalProduct product) {
    final existing = _items[product.id];
    if (existing != null) {
      _items[product.id] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final existing = _items[productId];
    if (existing == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void updateDays(String productId, int days) {
    final existing = _items[productId];
    if (existing == null || days < 1) return;
    _items[productId] = existing.copyWith(days: days);
    notifyListeners();
  }

  void removeProduct(String productId) {
    if (_items.remove(productId) != null) {
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
