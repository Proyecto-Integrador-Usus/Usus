import '../../catalog/domain/rental_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
    this.days = 1,
  });

  final RentalProduct product;
  final int quantity;
  final int days;

  double get subtotal => product.pricePerDay * quantity * days;

  CartItem copyWith({
    RentalProduct? product,
    int? quantity,
    int? days,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      days: days ?? this.days,
    );
  }
}
