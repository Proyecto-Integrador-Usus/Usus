import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/cart_controller.dart';
import '../domain/cart_item.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.cart,
    required this.account,
  });

  final CartController cart;
  final AccountProfile account;

  Future<void> _confirmRental(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Resumen preliminar de renta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A nombre de ${account.firstName} ${account.lastName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '• ${cart.totalUnits} ${cart.totalUnits == 1 ? 'unidad' : 'unidades'} seleccionadas\n'
              '• Modalidad: ${cart.deliveryMethod.label}\n'
              '• Total estimado: ${pesos(cart.total)}',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'El total estimado incluye la renta y la modalidad de entrega seleccionada.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Resumen de renta preparado.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mustard,
              foregroundColor: AppColors.espresso,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final items = cart.items;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            foregroundColor: AppColors.espresso,
            elevation: 0,
            titleSpacing: 0,
            title: const Text(
              'Carrito de rentas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            actions: [
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: cart.clear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Vaciar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          body: items.isEmpty
              ? _EmptyCart(onExplore: () => Navigator.of(context).pop())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 960;
                    final horizontalPadding = wide ? 36.0 : 16.0;

                    final itemsSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(
                          title: 'Artículos seleccionados',
                          subtitle:
                              '${cart.totalUnits} ${cart.totalUnits == 1 ? 'unidad' : 'unidades'} en ${cart.distinctCount} ${cart.distinctCount == 1 ? 'producto' : 'productos'}',
                        ),
                        const SizedBox(height: 14),
                        for (final item in items) ...[
                          _CartItemCard(
                            item: item,
                            onQuantityChanged: (q) =>
                                cart.updateQuantity(item.lineId, q),
                            onDaysChanged: (d) =>
                                cart.updateDays(item.lineId, d),
                            onRemove: () =>
                                cart.removeProduct(item.lineId),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        _DeliveryCard(
                          selected: cart.deliveryMethod,
                          address: account.address,
                          onChanged: cart.setDeliveryMethod,
                        ),
                      ],
                    );

                    final summarySection = _OrderSummaryCard(
                      cart: cart,
                      onContinue: () => _confirmRental(context),
                    );

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: itemsSection),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 4, child: summarySection),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    itemsSection,
                                    const SizedBox(height: 16),
                                    summarySection,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onDaysChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final thumb = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: compact ? 76 : 96,
              height: compact ? 76 : 96,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _ThumbPlaceholder(item: item),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _ThumbPlaceholder(item: item),
              ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.tan,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar del carrito',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${product.location} · ${pesos(product.pricePerDay)} / día',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _StepperControl(
                    label: 'Cantidad',
                    valueText: '${item.quantity}',
                    onDecrement: () => onQuantityChanged(item.quantity - 1),
                    onIncrement: () => onQuantityChanged(item.quantity + 1),
                  ),
                  if (item.period != null)
                    Text('${item.period!.label} · ${item.days} ${item.days == 1 ? 'día' : 'días'}')
                  else _StepperControl(
                    label: 'Días',
                    valueText: '${item.days} ${item.days == 1 ? 'día' : 'días'}',
                    onDecrement: item.days > 1
                        ? () => onDaysChanged(item.days - 1)
                        : null,
                    onIncrement: () => onDaysChanged(item.days + 1),
                  ),
                  Text(
                    pesos(item.subtotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
            ],
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 14),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ivory,
      alignment: Alignment.center,
      child: Icon(
        item.product.imageIcon,
        size: 34,
        color: AppColors.tan,
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  const _StepperControl({
    required this.label,
    required this.valueText,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String valueText;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(width: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Disminuir $label',
                onPressed: onDecrement,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_rounded, size: 16),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar $label',
                onPressed: onIncrement,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_rounded, size: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.selected,
    required this.address,
    required this.onChanged,
  });

  final DeliveryMethod selected;
  final String address;
  final ValueChanged<DeliveryMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RadioGroup<DeliveryMethod>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrega y recolección',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 10),
              for (final method in DeliveryMethod.values)
                RadioListTile<DeliveryMethod>(
                  value: method,
                  activeColor: AppColors.mustard,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    method.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: method == DeliveryMethod.delivery
                      ? Text(
                          address.isEmpty
                              ? 'Dirección registrada en tu cuenta'
                              : address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        )
                      : const Text(
                          'Sin costo adicional · Se coordina punto de entrega',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                  secondary: Text(
                    method.baseCost == 0
                        ? 'Gratis'
                        : pesos(method.baseCost),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.cart,
    required this.onContinue,
  });

  final CartController cart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen de renta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label:
                'Artículos (${cart.totalUnits} ${cart.totalUnits == 1 ? 'unidad' : 'unidades'})',
            value: pesos(cart.rentalSubtotal),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Envío',
            value: cart.shippingCost == 0
                ? 'Gratis'
                : pesos(cart.shippingCost),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Depósito (por separado)',
            value: pesos(cart.depositTotal),
            mutedValue: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total estimado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pesos(cart.total),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mustard,
              foregroundColor: AppColors.espresso,
              elevation: 0,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Continuar renta'),
          ),
          const SizedBox(height: 12),
          const Text(
            'El depósito en garantía se consulta en los detalles de cada artículo.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: mutedValue ? AppColors.muted : AppColors.espresso,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 38,
                color: AppColors.tan,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tu carrito de rentas está vacío',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega herramientas, mobiliario o equipo desde el catálogo para armar tu renta.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mustard,
                foregroundColor: AppColors.espresso,
                elevation: 0,
              ),
              child: const Text('Explorar catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
