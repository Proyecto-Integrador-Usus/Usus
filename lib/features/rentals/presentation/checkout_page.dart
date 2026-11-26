import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../cart/data/cart_controller.dart';
import '../data/rentals_controller.dart';
import '../domain/rental_order.dart';
import 'shipment_tracking_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.cart,
    required this.rentals,
    required this.account,
  });

  final CartController cart;
  final RentalsController rentals;
  final AccountProfile account;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _address = TextEditingController(
    text: widget.account.address.trim().isNotEmpty
        ? widget.account.address.trim()
        : 'Av. Universidad 940, Centro, Aguascalientes',
  );
  final _instructions = TextEditingController();
  String _zonaNodo = 'Zona Centro';

  PaymentMethod _paymentMethod = PaymentMethod.card;
  late final TextEditingController _cardHolder = TextEditingController(
    text: '${widget.account.firstName} ${widget.account.lastName}'.trim(),
  );
  final _cardNumber = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  String _installments = '1 pago de contado';

  final _speiBank = TextEditingController();
  final _speiReference = TextEditingController();
  String _cashOption = 'Pago en OXXO con referencia';

  bool _acceptedTerms = true;
  bool _submitting = false;
  String? _termsError;

  static const _nodos = ['Zona Centro', 'Zona Norte', 'Zona Sur'];

  @override
  void dispose() {
    for (final c in [
      _address,
      _instructions,
      _cardHolder,
      _cardNumber,
      _cardExpiry,
      _cardCvv,
      _speiBank,
      _speiReference,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, [String message = 'Completa este campo.']) =>
      v == null || v.trim().isEmpty ? message : null;

  String? _validateCardNumber(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 15 || digits.length > 16) {
      return 'Ingresa 15 o 16 dígitos de tarjeta.';
    }
    return null;
  }

  String? _validateExpiry(String? v) {
    final text = (v ?? '').trim();
    final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(text);
    if (match == null) return 'Usa formato MM/AA.';
    return null;
  }

  String? _validateCvv(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3 || digits.length > 4) {
      return 'CVV de 3 o 4 dígitos.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final validForm = _form.currentState!.validate();
    if (!_acceptedTerms) {
      setState(() {
        _termsError = 'Acepta los términos de renta y depósito para continuar.';
      });
      return;
    }
    if (!validForm) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _termsError = null;
    });

    final String paymentDetail;
    final String paymentReference;
    switch (_paymentMethod) {
      case PaymentMethod.card:
        final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
        final last4 = digits.length >= 4
            ? digits.substring(digits.length - 4)
            : digits;
        paymentDetail = 'Terminación •••• $last4 ($_installments)';
        paymentReference = 'AUTH-$last4-${DateTime.now().millisecond}';
      case PaymentMethod.transfer:
        paymentDetail = 'SPEI desde ${_speiBank.text.trim()}';
        paymentReference = _speiReference.text.trim();
      case PaymentMethod.cash:
        paymentDetail = _cashOption;
        paymentReference = '9940-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    }

    final order = widget.rentals.createOrder(
      items: widget.cart.items,
      deliveryMethod: widget.cart.deliveryMethod,
      address: _address.text.trim(),
      zonaNodo: _zonaNodo,
      deliveryInstructions: _instructions.text.trim(),
      rentalSubtotal: widget.cart.rentalSubtotal,
      shippingCost: widget.cart.shippingCost,
      depositTotal: widget.cart.depositTotal,
      totalAmount: widget.cart.total,
      paymentMethod: _paymentMethod,
      paymentDetail: paymentDetail,
      paymentReference: paymentReference,
    );

    widget.cart.clear();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => ShipmentTrackingPage(
          rentals: widget.rentals,
          orderId: order.idRenta,
          account: widget.account,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.brandPanel,
        surfaceTintColor: context.brandPanel,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Finalizar y pagar renta',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Volver al inicio',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: AppColors.mustard),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            final horizontalPadding = wide ? 36.0 : 16.0;

            final leftColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeliveryInfoCard(
                  deliveryMethod: cart.deliveryMethod,
                  addressController: _address,
                  instructionsController: _instructions,
                  selectedNodo: _zonaNodo,
                  nodos: _nodos,
                  onNodoChanged: (n) => setState(() => _zonaNodo = n),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                _PaymentSectionCard(
                  selectedMethod: _paymentMethod,
                  onMethodChanged: (m) => setState(() => _paymentMethod = m),
                  cardHolder: _cardHolder,
                  cardNumber: _cardNumber,
                  cardExpiry: _cardExpiry,
                  cardCvv: _cardCvv,
                  installments: _installments,
                  totalAmount: cart.total,
                  onInstallmentsChanged: (v) =>
                      setState(() => _installments = v),
                  speiBank: _speiBank,
                  speiReference: _speiReference,
                  cashOption: _cashOption,
                  onCashOptionChanged: (v) => setState(() => _cashOption = v),
                  validateRequired: _required,
                  validateCardNumber: _validateCardNumber,
                  validateExpiry: _validateExpiry,
                  validateCvv: _validateCvv,
                ),
                const SizedBox(height: 14),
                Material(
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    value: _acceptedTerms,
                    activeColor: AppColors.mustard,
                    checkColor: AppColors.espresso,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Acepto los términos de renta, política de cancelación y el depósito en garantía.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: _termsError != null
                        ? Text(
                            _termsError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          )
                        : null,
                    onChanged: (v) => setState(() {
                      _acceptedTerms = v ?? false;
                      if (_acceptedTerms) _termsError = null;
                    }),
                  ),
                ),
              ],
            );

            final summaryCard = _CheckoutSummaryCard(
              cart: cart,
              submitting: _submitting,
              onConfirm: _submit,
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
                            Expanded(flex: 7, child: leftColumn),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: summaryCard),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            leftColumn,
                            const SizedBox(height: 16),
                            summaryCard,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  const _DeliveryInfoCard({
    required this.deliveryMethod,
    required this.addressController,
    required this.instructionsController,
    required this.selectedNodo,
    required this.nodos,
    required this.onNodoChanged,
    required this.validator,
  });

  final DeliveryMethod deliveryMethod;
  final TextEditingController addressController;
  final TextEditingController instructionsController;
  final String selectedNodo;
  final List<String> nodos;
  final ValueChanged<String> onNodoChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deliveryMethod == DeliveryMethod.pickup
                      ? '1. Punto de recolección'
                      : '1. Dirección de envío',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  deliveryMethod == DeliveryMethod.pickup
                      ? 'Gratis'
                      : pesos(deliveryMethod.baseCost),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Nodo operativo en Aguascalientes',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final nodo in nodos)
                ChoiceChip(
                  label: Text(nodo),
                  selected: selectedNodo == nodo,
                  selectedColor: AppColors.mustard.withValues(alpha: 0.3),
                  backgroundColor: context.colors.surfaceContainerLow,
                  onSelected: (_) => onNodoChanged(nodo),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: addressController,
            validator: validator,
            decoration: InputDecoration(
              labelText: deliveryMethod == DeliveryMethod.pickup
                  ? 'Dirección de referencia'
                  : 'Calle, número, colonia y CP',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: instructionsController,
            decoration: const InputDecoration(
              labelText: 'Indicaciones para entrega o horario (opcional)',
              hintText: 'Ej. Tocar timbre azul, entregar entre 10:00 y 13:00',
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSectionCard extends StatelessWidget {
  const _PaymentSectionCard({
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.cardHolder,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.installments,
    required this.totalAmount,
    required this.onInstallmentsChanged,
    required this.speiBank,
    required this.speiReference,
    required this.cashOption,
    required this.onCashOptionChanged,
    required this.validateRequired,
    required this.validateCardNumber,
    required this.validateExpiry,
    required this.validateCvv,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final TextEditingController cardHolder;
  final TextEditingController cardNumber;
  final TextEditingController cardExpiry;
  final TextEditingController cardCvv;
  final String installments;
  final double totalAmount;
  final ValueChanged<String> onInstallmentsChanged;
  final TextEditingController speiBank;
  final TextEditingController speiReference;
  final String cashOption;
  final ValueChanged<String> onCashOptionChanged;
  final String? Function(String?) validateRequired;
  final String? Function(String?) validateCardNumber;
  final String? Function(String?) validateExpiry;
  final String? Function(String?) validateCvv;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: RadioGroup<PaymentMethod>(
          groupValue: selectedMethod,
          onChanged: (value) {
            if (value != null) onMethodChanged(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '2. Forma de pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final method in PaymentMethod.values) ...[
                RadioListTile<PaymentMethod>(
                  value: method,
                  activeColor: AppColors.mustard,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    method.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    method.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (selectedMethod == method) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: switch (method) {
                      PaymentMethod.card => _CardFields(
                          cardHolder: cardHolder,
                          cardNumber: cardNumber,
                          cardExpiry: cardExpiry,
                          cardCvv: cardCvv,
                          installments: installments,
                          totalAmount: totalAmount,
                          onInstallmentsChanged: onInstallmentsChanged,
                          validateRequired: validateRequired,
                          validateCardNumber: validateCardNumber,
                          validateExpiry: validateExpiry,
                          validateCvv: validateCvv,
                        ),
                      PaymentMethod.transfer => _SpeiFields(
                          speiBank: speiBank,
                          speiReference: speiReference,
                          validateRequired: validateRequired,
                        ),
                      PaymentMethod.cash => _CashFields(
                          cashOption: cashOption,
                          onChanged: onCashOptionChanged,
                        ),
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFields extends StatelessWidget {
  const _CardFields({
    required this.cardHolder,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.installments,
    required this.totalAmount,
    required this.onInstallmentsChanged,
    required this.validateRequired,
    required this.validateCardNumber,
    required this.validateExpiry,
    required this.validateCvv,
  });

  final TextEditingController cardHolder;
  final TextEditingController cardNumber;
  final TextEditingController cardExpiry;
  final TextEditingController cardCvv;
  final String installments;
  final double totalAmount;
  final ValueChanged<String> onInstallmentsChanged;
  final String? Function(String?) validateRequired;
  final String? Function(String?) validateCardNumber;
  final String? Function(String?) validateExpiry;
  final String? Function(String?) validateCvv;

  @override
  Widget build(BuildContext context) {
    final msi3 = pesos(totalAmount / 3);
    final options = [
      '1 pago de contado',
      if (totalAmount >= 500) '3 meses sin intereses ($msi3 / mes)',
    ];
    final currentInstallment =
        options.contains(installments) ? installments : options.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: cardHolder,
            textCapitalization: TextCapitalization.words,
            validator: validateRequired,
            decoration: const InputDecoration(
              labelText: 'Nombre como aparece en la tarjeta',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: cardNumber,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: validateCardNumber,
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              hintText: '16 dígitos',
              prefixIcon: Icon(Icons.credit_card_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: cardExpiry,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [LengthLimitingTextInputFormatter(5)],
                  validator: validateExpiry,
                  decoration: const InputDecoration(
                    labelText: 'Vencimiento',
                    hintText: 'MM/AA',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: cardCvv,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: validateCvv,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '3 o 4 dígitos',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: currentInstallment,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Mensualidades'),
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              if (v != null) onInstallmentsChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SpeiFields extends StatelessWidget {
  const _SpeiFields({
    required this.speiBank,
    required this.speiReference,
    required this.validateRequired,
  });

  final TextEditingController speiBank;
  final TextEditingController speiReference;
  final String? Function(String?) validateRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLABE: 6461 8011 0400 0000 18 · STP (USUS Pagos)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: speiBank,
            validator: validateRequired,
            decoration: const InputDecoration(
              labelText: 'Banco de origen',
              hintText: 'Ej. BBVA, Banorte, Nu',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: speiReference,
            validator: validateRequired,
            decoration: const InputDecoration(
              labelText: 'Clave de rastreo o referencia',
              hintText: 'Ej. SPEI-20261124-001',
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFields extends StatelessWidget {
  const _CashFields({
    required this.cashOption,
    required this.onChanged,
  });

  final String cashOption;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Pago en OXXO con referencia',
      'Pago contra entrega / al recoger',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final opt in options)
            ChoiceChip(
              label: Text(opt),
              selected: cashOption == opt,
              selectedColor: AppColors.mustard.withValues(alpha: 0.3),
              backgroundColor: context.colors.surface,
              onSelected: (_) => onChanged(opt),
            ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({
    required this.cart,
    required this.submitting,
    required this.onConfirm,
  });

  final CartController cart;
  final bool submitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: context.brandPanel,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pago protegido USUS',
                  style: TextStyle(fontSize: 12, color: AppColors.mustard),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in cart.items) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.product.name} (${item.days}d)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pesos(item.subtotal),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Divider(height: 22, color: context.colors.outlineVariant),
                _RowSummary('Renta de artículos', pesos(cart.rentalSubtotal)),
                const SizedBox(height: 8),
                _RowSummary(
                  'Envío',
                  cart.shippingCost == 0 ? 'Gratis' : pesos(cart.shippingCost),
                ),
                const SizedBox(height: 8),
                _RowSummary(
                  'Depósito reembolsable',
                  pesos(cart.depositTotal),
                  muted: true,
                ),
                Divider(height: 24, color: context.colors.outlineVariant),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total a pagar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      pesos(cart.total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: submitting ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mustard,
                    foregroundColor: AppColors.espresso,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    submitting ? 'Procesando…' : 'Confirmar y pagar',
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

class _RowSummary extends StatelessWidget {
  const _RowSummary(this.label, this.value, {this.muted = false});
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: muted ? context.colors.onSurfaceVariant : context.colors.onSurface,
        ),
      ),
    ],
  );
}
