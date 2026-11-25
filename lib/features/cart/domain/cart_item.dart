import 'dart:convert';

import '../../rentals/domain/rental_period.dart';
import '../../catalog/domain/rental_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
    int days = 1,
    this.period,
  }) : _days = days;

  final RentalProduct product;
  final int quantity;
  final int _days;
  final RentalPeriod? period;
  int get days => period?.days ?? _days;
  String get lineId =>
      period == null ? product.id : jsonEncode([product.id, period!.toJson()]);

  double get subtotal => product.pricePerDay * quantity * days;

  CartItem copyWith({RentalProduct? product, int? quantity, int? days}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      days: days ?? this.days,
      period: period,
    );
  }
}
