import 'package:flutter/foundation.dart';

import '../../cart/data/cart_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/rental_order.dart';

class RentalsController extends ChangeNotifier {
  final List<RentalOrder> _orders = [];

  List<RentalOrder> get orders => List.unmodifiable(_orders);

  RentalOrder? byId(String idRenta) {
    for (final order in _orders) {
      if (order.idRenta == idRenta) return order;
    }
    return null;
  }

  RentalOrder createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    required String address,
    required String zonaNodo,
    required String deliveryInstructions,
    required double rentalSubtotal,
    required double shippingCost,
    required double depositTotal,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required String paymentDetail,
    required String paymentReference,
  }) {
    final now = DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    final idRenta = 'RNT-$suffix';

    final payment = RentalPayment(
      idPago: 'PAG-$suffix',
      monto: totalAmount,
      metodoPago: paymentMethod,
      fechaPago: now,
      estado: paymentMethod == PaymentMethod.cash
          ? 'Pendiente de pago'
          : 'Completado',
      detalleResumen: paymentDetail,
      referencia: paymentReference,
    );

    final isPickup = deliveryMethod == DeliveryMethod.pickup;
    final shipment = RentalShipment(
      idEnvio: 'ENV-$suffix',
      deliveryMethod: deliveryMethod,
      direccion: address,
      costo: shippingCost,
      fechaEnvio: now,
      fechaEntregaEstimada: now.add(Duration(hours: isPickup ? 2 : 5)),
      stage: ShipmentStage.preparing,
      codigoSeguimiento: 'USUS-AGS-$suffix',
      zonaNodo: zonaNodo,
      repartidor: isPickup
          ? 'Entrega directa en punto ($zonaNodo)'
          : 'Carlos Mendoza · Camioneta Nissan NP300',
      deliveryInstructions: deliveryInstructions,
      timeline: [
        ShipmentEvent(
          title: 'Pago registrado (${payment.estado})',
          detail: '${paymentMethod.label} · $paymentDetail',
          timestamp: now,
        ),
        ShipmentEvent(
          title: ShipmentStage.preparing.label,
          detail: isPickup
              ? 'El arrendador prepara tu pedido en $zonaNodo.'
              : 'Asignado al nodo $zonaNodo para revisión y carga.',
          timestamp: now,
        ),
      ],
    );

    final order = RentalOrder(
      idRenta: idRenta,
      createdAt: now,
      items: List.unmodifiable(items),
      rentalSubtotal: rentalSubtotal,
      shippingCost: shippingCost,
      depositTotal: depositTotal,
      totalAmount: totalAmount,
      payment: payment,
      shipment: shipment,
    );

    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  void advanceShipment(String idRenta) {
    final index = _orders.indexWhere((o) => o.idRenta == idRenta);
    if (index == -1) return;
    final order = _orders[index];
    final current = order.shipment.stage;
    final next = switch (current) {
      ShipmentStage.preparing => ShipmentStage.inTransit,
      ShipmentStage.inTransit => ShipmentStage.delivered,
      ShipmentStage.delivered => ShipmentStage.completed,
      ShipmentStage.completed => null,
    };
    if (next == null) return;

    final now = DateTime.now();
    final eventDetail = switch (next) {
      ShipmentStage.inTransit => order.shipment.deliveryMethod ==
              DeliveryMethod.pickup
          ? 'Listo para recolección en ${order.shipment.zonaNodo}.'
          : '${order.shipment.repartidor} va rumbo a ${order.shipment.direccion}.',
      ShipmentStage.delivered =>
        'Entregado conforme en ${order.shipment.direccion}.',
      ShipmentStage.completed =>
        'Artículos devueltos sin novedad. Ya puedes dejar tu reseña.',
      ShipmentStage.preparing => next.description,
    };

    final updatedShipment = order.shipment.copyWith(
      stage: next,
      timeline: [
        ...order.shipment.timeline,
        ShipmentEvent(
          title: next.label,
          detail: eventDetail,
          timestamp: now,
        ),
      ],
    );
    _orders[index] = order.copyWith(shipment: updatedShipment);
    notifyListeners();
  }

  void submitReview({
    required String idRenta,
    required int calificacion,
    required String comentario,
  }) {
    final index = _orders.indexWhere((o) => o.idRenta == idRenta);
    if (index == -1) return;
    final order = _orders[index];
    if (!order.isFinalized) return;

    final now = DateTime.now();
    final review = RentalReview(
      idResena: 'RES-${now.millisecondsSinceEpoch % 100000}',
      calificacion: calificacion.clamp(1, 5),
      comentario: comentario.trim(),
      fecha: now,
    );
    _orders[index] = order.copyWith(review: review);
    notifyListeners();
  }

  void submitReport({
    required String idRenta,
    required String idUsuario,
    required String tipo,
    required String descripcion,
  }) {
    final index = _orders.indexWhere((o) => o.idRenta == idRenta);
    if (index == -1) return;
    final order = _orders[index];

    final now = DateTime.now();
    final report = RentalReport(
      idReporte: 'REP-${now.millisecondsSinceEpoch % 100000}',
      idUsuario: idUsuario,
      tipo: tipo,
      descripcion: descripcion.trim(),
      fecha: now,
      estado: 'Pendiente',
    );
    _orders[index] = order.copyWith(
      reports: [report, ...order.reports],
    );
    notifyListeners();
  }

  void clear() {
    if (_orders.isEmpty) return;
    _orders.clear();
    notifyListeners();
  }
}
