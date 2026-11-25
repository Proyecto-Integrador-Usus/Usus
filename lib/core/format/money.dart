String pesos(double amount) {
  final digits = amount == amount.roundToDouble() ? 0 : 2;
  return '\$${amount.toStringAsFixed(digits)} MXN';
}
