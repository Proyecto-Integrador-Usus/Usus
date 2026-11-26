import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/rentals_controller.dart';
import '../domain/rental_order.dart';

class ShipmentTrackingPage extends StatefulWidget {
  const ShipmentTrackingPage({
    super.key,
    required this.rentals,
    required this.orderId,
    required this.account,
  });

  final RentalsController rentals;
  final String orderId;
  final AccountProfile account;

  @override
  State<ShipmentTrackingPage> createState() => _ShipmentTrackingPageState();
}

class _ShipmentTrackingPageState extends State<ShipmentTrackingPage> {
  int _selectedRating = 5;
  final _reviewController = TextEditingController();
  String? _reviewError;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} · $h:$min';
  }

  Future<void> _openReportDialog(RentalOrder order) async {
    final result = await showDialog<({String type, String description})>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );

    if (result != null && mounted) {
      widget.rentals.submitReport(
        idRenta: order.idRenta,
        idUsuario: widget.account.email,
        tipo: result.type,
        descripcion: result.description,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte registrado. Nuestro equipo lo revisará.'),
        ),
      );
    }
  }

  void _submitReview(RentalOrder order) {
    final comment = _reviewController.text.trim();
    if (comment.length < 4) {
      setState(() {
        _reviewError = 'Escribe un comentario breve (mín. 4 caracteres).';
      });
      return;
    }
    setState(() => _reviewError = null);
    widget.rentals.submitReview(
      idRenta: order.idRenta,
      calificacion: _selectedRating,
      comentario: comment,
    );
    _reviewController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Gracias por tu reseña!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.rentals,
      builder: (context, _) {
        final order = widget.rentals.byId(widget.orderId);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Seguimiento de envío')),
            body: const Center(child: Text('No se encontró la renta.')),
          );
        }

        return Scaffold(
          backgroundColor: context.canvas,
          appBar: AppBar(
            backgroundColor: context.brandPanel,
            surfaceTintColor: context.brandPanel,
            foregroundColor: AppColors.white,
            elevation: 0,
            titleSpacing: 0,
            title: Text(
              'Envío y renta · ${order.idRenta}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actions: [
              IconButton(
                tooltip: 'Volver al inicio',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.mustard,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;
              final horizontalPadding = wide ? 36.0 : 16.0;

              final trackingSection = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ShipmentHeroCard(
                    order: order,
                    formattedEta: _formatDateTime(
                      order.shipment.fechaEntregaEstimada,
                    ),
                    onAdvance: order.isFinalized
                        ? null
                        : () => widget.rentals.advanceShipment(order.idRenta),
                  ),
                  const SizedBox(height: 16),
                  _TimelineCard(
                    shipment: order.shipment,
                    formatTime: _formatDateTime,
                  ),
                  const SizedBox(height: 16),
                  _ShipmentDetailsCard(shipment: order.shipment),
                ],
              );

              final summaryAndFeedback = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderPaymentCard(
                    order: order,
                    formatTime: _formatDateTime,
                  ),
                  const SizedBox(height: 16),
                  _ReviewCard(
                    order: order,
                    selectedRating: _selectedRating,
                    controller: _reviewController,
                    errorText: _reviewError,
                    onRatingChanged: (r) =>
                        setState(() => _selectedRating = r),
                    onSubmit: () => _submitReview(order),
                    formatTime: _formatDateTime,
                  ),
                  const SizedBox(height: 16),
                  _ReportsCard(
                    order: order,
                    onCreateReport: () => _openReportDialog(order),
                    formatTime: _formatDateTime,
                  ),
                ],
              );

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: trackingSection),
                              const SizedBox(width: 24),
                              Expanded(flex: 5, child: summaryAndFeedback),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              trackingSection,
                              const SizedBox(height: 16),
                              summaryAndFeedback,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ShipmentHeroCard extends StatelessWidget {
  const _ShipmentHeroCard({
    required this.order,
    required this.formattedEta,
    required this.onAdvance,
  });

  final RentalOrder order;
  final String formattedEta;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    final stage = order.shipment.stage;
    final progress = switch (stage) {
      ShipmentStage.preparing => 0.25,
      ShipmentStage.inTransit => 0.55,
      ShipmentStage.delivered => 0.80,
      ShipmentStage.completed => 1.0,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.brandPanel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mustard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stage.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              Text(
                'Guía: ${order.shipment.codigoSeguimiento}',
                style: const TextStyle(
                  color: AppColors.ivory,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            stage.description,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.isFinalized
                ? 'Renta concluida · ${order.shipment.zonaNodo}'
                : 'Entrega estimada: $formattedEta · ${order.shipment.zonaNodo}',
            style: const TextStyle(color: AppColors.ivory, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.mustard,
              ),
            ),
          ),
          if (onAdvance != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdvance,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mustard,
                side: const BorderSide(color: AppColors.mustard),
              ),
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label: const Text('Avanzar estado del envío (Demo)'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.shipment,
    required this.formatTime,
  });

  final RentalShipment shipment;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final events = shipment.timeline.reversed.toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seguimiento paso a paso',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < events.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.mustard : context.colors.outlineVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == 0 ? AppColors.espresso : context.colors.onSurfaceVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    if (i < events.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: context.colors.outlineVariant,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              i == 0 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        events[i].detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTime(events[i].timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < events.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ShipmentDetailsCard extends StatelessWidget {
  const _ShipmentDetailsCard({required this.shipment});
  final RentalShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del envío',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.local_shipping_outlined,
            label: 'Modalidad',
            value: shipment.deliveryMethod.label,
          ),
          _InfoLine(
            icon: Icons.place_outlined,
            label: 'Dirección',
            value: shipment.direccion,
          ),
          _InfoLine(
            icon: Icons.person_pin_circle_outlined,
            label: 'Responsable / unidad',
            value: shipment.repartidor,
          ),
          if (shipment.deliveryInstructions.isNotEmpty)
            _InfoLine(
              icon: Icons.notes_rounded,
              label: 'Indicaciones',
              value: shipment.deliveryInstructions,
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPaymentCard extends StatelessWidget {
  const _OrderPaymentCard({
    required this.order,
    required this.formatTime,
  });

  final RentalOrder order;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final p = order.payment;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Resumen de artículos y pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.estado,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in order.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}× ${item.product.name} (${item.days}d)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pesos(item.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Divider(height: 22, color: context.colors.outlineVariant),
          Text(
            '${p.metodoPago.label} · ${p.detalleResumen}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            'Folio ${p.idPago} · Ref: ${p.referencia} · ${formatTime(p.fechaPago)}',
            style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total pagado / pactado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pesos(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.order,
    required this.selectedRating,
    required this.controller,
    required this.errorText,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.formatTime,
  });

  final RentalOrder order;
  final int selectedRating;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final review = order.review;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reseña de tu renta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (!order.isFinalized)
            Text(
              'Podrás calificar y escribir una reseña cuando la renta esté finalizada (usa "Avanzar estado del envío" arriba para probarlo).',
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            )
          else if (review != null) ...[
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= review.calificacion
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.mustard,
                    size: 22,
                  ),
                const SizedBox(width: 8),
                Text(
                  review.idResena,
                  style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comentario, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              'Publicada el ${formatTime(review.fecha)}',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
            ),
          ] else ...[
            Text(
              '¿Qué tal estuvo el servicio y el estado de los artículos?',
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star estrellas',
                    onPressed: () => onRatingChanged(star),
                    icon: Icon(
                      star <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.mustard,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Tu reseña',
                hintText: 'Ej. Todo llegó puntual y en excelente estado.',
                errorText: errorText,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mustard,
                foregroundColor: AppColors.espresso,
                elevation: 0,
              ),
              child: const Text('Enviar reseña'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard({
    required this.order,
    required this.onCreateReport,
    required this.formatTime,
  });

  final RentalOrder order;
  final VoidCallback onCreateReport;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '¿Hubo algún problema?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCreateReport,
                icon: const Icon(Icons.flag_outlined, size: 17),
                label: const Text('Reportar'),
              ),
            ],
          ),
          if (order.reports.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Si recibiste un artículo dañado, incompleto o con retraso, puedes levantar un reporte.',
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (final rep in order.reports) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rep.tipo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${rep.idReporte} · ${rep.estado}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rep.descripcion,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatTime(rep.fecha),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _types = [
    'Artículo dañado o defectuoso',
    'Retraso en entrega',
    'Artículo incompleto',
    'Problema con el pago',
    'Otro',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _selectedType = _types.first;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Levantar reporte',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de reporte',
                  ),
                  items: [
                    for (final t in _types)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del problema',
                    hintText: 'Cuéntanos qué ocurrió para darle seguimiento.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'Describe el problema (mín. 8 caracteres).'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              type: _selectedType,
              description: _descController.text,
            ));
          },
          style: FilledButton.styleFrom(
            backgroundColor: context.brandPanel,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Enviar reporte'),
        ),
      ],
    );
  }
}
