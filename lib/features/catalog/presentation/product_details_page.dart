import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../rentals/domain/rental_period.dart';
import '../domain/rental_product.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.signedIn,
    required this.signIn,
  });

  final RentalProduct product;
  final bool signedIn;
  final Future<bool> Function() signIn;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _photo = 0;
  DateTime? _start;
  DateTime? _end;
  RentalPeriod? get _period =>
      _start == null || _end == null ? null : RentalPeriod(_start!, _end!);
  bool _continuing = false;
  RentalProduct get product => widget.product;

  Future<void> _chooseDate({required bool start}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final earliest = start || _start == null || _start!.isBefore(today)
        ? today
        : _start!;
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: DateTime(9999, 12, 31),
      initialDate: current == null || current.isBefore(earliest)
          ? earliest
          : current,
      helpText: start ? 'Primer día de renta' : 'Último día de renta',
      confirmText: 'Elegir',
      cancelText: 'Cancelar',
    );
    if (!mounted || date == null) return;
    setState(() {
      if (start) {
        _start = date;
        if (_end?.isBefore(date) == true) _end = null;
      } else {
        _end = date;
      }
    });
  }

  Future<void> _continue() async {
    if (_continuing || _period == null || !product.isAvailable) return;
    setState(() => _continuing = true);
    try {
      if (!widget.signedIn && !await widget.signIn()) return;
      if (mounted) Navigator.pop(context, _period);
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  Widget _photoFallback() =>
      Center(child: Icon(product.imageIcon, size: 72, color: AppColors.tan));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final photos = product.gallery;
    final overview = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mustard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(product.category.icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.category.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (product.rating > 0) ...[
                const Icon(Icons.star_rounded, size: 18),
                const SizedBox(width: 3),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(product.name, style: theme.headlineLarge),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: AppColors.ivory,
              child: AspectRatio(
                aspectRatio: 1.65,
                child: photos.isEmpty
                    ? _photoFallback()
                    : Image.network(
                        photos[_photo],
                        fit: BoxFit.cover,
                        semanticLabel: 'Foto ${_photo + 1} de ${product.name}',
                        errorBuilder: (_, _, _) => _photoFallback(),
                      ),
              ),
            ),
          ),
          if (photos.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Foto anterior',
                  onPressed: _photo == 0
                      ? null
                      : () => setState(() => _photo--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_photo + 1} de ${photos.length}'),
                IconButton(
                  tooltip: 'Foto siguiente',
                  onPressed: _photo + 1 >= photos.length
                      ? null
                      : () => setState(() => _photo++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _ProductFact(
                icon: Icons.handyman_outlined,
                label: 'Estado físico',
                value: product.condition,
              ),
              _ProductFact(
                icon: Icons.place_outlined,
                label: 'Zona de entrega',
                value: product.location,
              ),
            ],
          ),
          if (product.description.trim().isNotEmpty) ...[
            const Divider(height: 32, color: Color(0x453B2F2F)),
            Text('Descripción y qué incluye', style: theme.titleLarge),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ],
      ),
    );
    final period = _period;
    final enabled = product.isAvailable && !_continuing;
    final rental = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123B2F2F),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.espresso,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Renta por día',
                    style: TextStyle(color: AppColors.ivory),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesos(product.pricePerDay),
                    style: theme.headlineLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Fechas de renta', style: theme.titleLarge),
                const SizedBox(height: 10),
                _DateField(
                  label: 'Fecha de inicio',
                  date: _start,
                  hint: 'Elegir primer día',
                  onTap: enabled ? () => _chooseDate(start: true) : null,
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: 'Último día de renta',
                  date: _end,
                  hint: _start == null
                      ? 'Elige primero el inicio'
                      : 'Elegir último día',
                  onTap: enabled && _start != null
                      ? () => _chooseDate(start: false)
                      : null,
                ),
                if (enabled && _start != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final days in [1, 3, 7])
                        ChoiceChip(
                          label: Text(days == 1 ? '1 día' : '$days días'),
                          selected: period?.days == days,
                          onSelected: (_) => setState(() {
                            final start = _start!;
                            _end = DateTime(
                              start.year,
                              start.month,
                              start.day + days - 1,
                            );
                          }),
                        ),
                    ],
                  ),
                ],
                if (!product.isAvailable)
                  const Text('Artículo no disponible para renta.'),
                const Divider(height: 30, color: AppColors.border),
                if (period != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Renta por ${period.days} ${period.days == 1 ? 'día' : 'días'}: ${pesos(period.days * product.pricePerDay)}',
                      style: theme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  product.deposit > 0
                      ? 'Depósito reembolsable por separado: ${pesos(product.deposit)}'
                      : 'Sin depósito en garantía',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: enabled && period != null ? _continue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mustard,
                    foregroundColor: AppColors.espresso,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    widget.signedIn
                        ? 'Agregar al carrito'
                        : 'Iniciar sesión para rentar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.espresso,
        foregroundColor: AppColors.white,
        title: const Text('Detalles del artículo'),
        actions: [
          IconButton(
            tooltip: 'Volver al inicio',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: AppColors.mustard),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  if (bounds.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [overview, const SizedBox(height: 22), rental],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: overview),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: rental),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductFact extends StatelessWidget {
  const _ProductFact({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.hint,
    required this.onTap,
  });
  final String label;
  final DateTime? date;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = date == null
        ? hint
        : MaterialLocalizations.of(context).formatFullDate(date!);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.espresso,
        disabledForegroundColor: AppColors.muted,
        backgroundColor: onTap == null ? AppColors.canvas : AppColors.ivory,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded),
        ],
      ),
    );
  }
}
