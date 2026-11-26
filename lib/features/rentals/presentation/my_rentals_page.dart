import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/rentals_controller.dart';
import 'shipment_tracking_page.dart';

class MyRentalsPage extends StatelessWidget {
  const MyRentalsPage({
    super.key,
    required this.rentals,
    required this.account,
  });

  final RentalsController rentals;
  final AccountProfile account;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rentals,
      builder: (context, _) {
        final orders = rentals.orders;
        return Scaffold(
          backgroundColor: context.canvas,
          appBar: AppBar(
            backgroundColor: context.brandPanel,
            surfaceTintColor: context.brandPanel,
            foregroundColor: AppColors.white,
            elevation: 0,
            titleSpacing: 0,
            title: const Text(
              'Mis rentas y envíos',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
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
          body: orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 36,
                            color: context.colors.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes rentas activas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cuando confirmes una renta desde el carrito podrás seguir su envío, calificarla o levantar reportes aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Material(
                      color: context.colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: context.colors.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShipmentTrackingPage(
                              rentals: rentals,
                              orderId: order.idRenta,
                              account: account,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: context.colors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: context.colors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${order.idRenta} · ${order.estadoRenta}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${order.totalUnits} ${order.totalUnits == 1 ? 'unidad' : 'unidades'} · ${order.shipment.codigoSeguimiento}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    pesos(order.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ver envío →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.colors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
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
