import '../../cart/data/cart_controller.dart';
import '../../cart/domain/cart_item.dart';

enum PaymentMethod {
  card('Tarjeta de crédito o débito', 'Acreditación inmediata'),
  transfer('Transferencia SPEI', 'Genera referencia bancaria única'),
  cash('Efectivo en OXXO o contra entrega', 'Paga con folio o al recibir');

  const PaymentMethod(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

class RentalPayment {
  const RentalPayment({
    required this.idPago,
    required this.monto,
    required this.metodoPago,
    required this.fechaPago,
    required this.estado,
    required this.detalleResumen,
    this.referencia = '',
  });

  final String idPago;
  final double monto;
  final PaymentMethod metodoPago;
  final DateTime fechaPago;
  final String estado;
  final String detalleResumen;
  final String referencia;
}

enum ShipmentStage {
  preparing('Preparando pedido', 'El arrendador alista tus artículos'),
  inTransit('En camino', 'Tu pedido salió del nodo hacia tu dirección'),
  delivered('Entregado', 'Artículos entregados al arrendatario'),
  completed('Renta finalizada', 'Artículos devueltos y renta concluida');

  const ShipmentStage(this.label, this.description);
  final String label;
  final String description;
}

class ShipmentEvent {
  const ShipmentEvent({
    required this.title,
    required this.detail,
    required this.timestamp,
  });

  final String title;
  final String detail;
  final DateTime timestamp;
}

class RentalShipment {
  const RentalShipment({
    required this.idEnvio,
    required this.deliveryMethod,
    required this.direccion,
    required this.costo,
    required this.fechaEnvio,
    required this.fechaEntregaEstimada,
    required this.stage,
    required this.codigoSeguimiento,
    required this.zonaNodo,
    required this.repartidor,
    required this.deliveryInstructions,
    required this.timeline,
  });

  final String idEnvio;
  final DeliveryMethod deliveryMethod;
  final String direccion;
  final double costo;
  final DateTime fechaEnvio;
  final DateTime fechaEntregaEstimada;
  final ShipmentStage stage;
  final String codigoSeguimiento;
  final String zonaNodo;
  final String repartidor;
  final String deliveryInstructions;
  final List<ShipmentEvent> timeline;

  RentalShipment copyWith({
    ShipmentStage? stage,
    List<ShipmentEvent>? timeline,
  }) {
    return RentalShipment(
      idEnvio: idEnvio,
      deliveryMethod: deliveryMethod,
      direccion: direccion,
      costo: costo,
      fechaEnvio: fechaEnvio,
      fechaEntregaEstimada: fechaEntregaEstimada,
      stage: stage ?? this.stage,
      codigoSeguimiento: codigoSeguimiento,
      zonaNodo: zonaNodo,
      repartidor: repartidor,
      deliveryInstructions: deliveryInstructions,
      timeline: timeline ?? this.timeline,
    );
  }
}

class RentalReview {
  const RentalReview({
    required this.idResena,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
  });

  final String idResena;
  final int calificacion;
  final String comentario;
  final DateTime fecha;
}

class RentalReport {
  const RentalReport({
    required this.idReporte,
    required this.idUsuario,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    required this.estado,
  });

  final String idReporte;
  final String idUsuario;
  final String tipo;
  final String descripcion;
  final DateTime fecha;
  final String estado;
}

class RentalOrder {
  const RentalOrder({
    required this.idRenta,
    required this.createdAt,
    required this.items,
    required this.rentalSubtotal,
    required this.shippingCost,
    required this.depositTotal,
    required this.totalAmount,
    required this.payment,
    required this.shipment,
    this.review,
    this.reports = const [],
  });

  final String idRenta;
  final DateTime createdAt;
  final List<CartItem> items;
  final double rentalSubtotal;
  final double shippingCost;
  final double depositTotal;
  final double totalAmount;
  final RentalPayment payment;
  final RentalShipment shipment;
  final RentalReview? review;
  final List<RentalReport> reports;

  bool get isFinalized => shipment.stage == ShipmentStage.completed;

  int get totalUnits =>
      items.fold(0, (sum, item) => sum + item.quantity);

  String get estadoRenta {
    if (reports.isNotEmpty && !isFinalized) return 'Con reporte';
    return switch (shipment.stage) {
      ShipmentStage.preparing => 'Confirmada',
      ShipmentStage.inTransit => 'En camino',
      ShipmentStage.delivered => 'En uso',
      ShipmentStage.completed => 'Finalizada',
    };
  }

  RentalOrder copyWith({
    RentalShipment? shipment,
    RentalReview? review,
    List<RentalReport>? reports,
  }) {
    return RentalOrder(
      idRenta: idRenta,
      createdAt: createdAt,
      items: items,
      rentalSubtotal: rentalSubtotal,
      shippingCost: shippingCost,
      depositTotal: depositTotal,
      totalAmount: totalAmount,
      payment: payment,
      shipment: shipment ?? this.shipment,
      review: review ?? this.review,
      reports: reports ?? this.reports,
    );
  }
}
