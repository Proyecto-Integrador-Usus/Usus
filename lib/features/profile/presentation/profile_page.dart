import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/domain/rental_product.dart';
import '../../rentals/data/rentals_controller.dart';
import '../../rentals/presentation/shipment_tracking_page.dart';

enum _Section {
  profile('Mi perfil', Icons.person_outline_rounded),
  favorites('Favoritos', Icons.favorite_border_rounded),
  history('Historial', Icons.history_rounded),
  coupons('Cupones', Icons.confirmation_number_outlined),
  billing('Facturación', Icons.receipt_long_outlined),
  settings('Configuración', Icons.tune_rounded),
  help('Ayuda', Icons.support_agent_rounded),
  faq('Preguntas frecuentes', Icons.quiz_outlined),
  terms('Términos y condiciones', Icons.description_outlined),
  about('Acerca de', Icons.info_outline_rounded);

  const _Section(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.account,
    required this.settings,
    required this.rentals,
    required this.products,
    required this.favorites,
    required this.onRemoveFavorite,
    required this.onOpenProduct,
    required this.onSortChanged,
  });

  final AccountProfile account;
  final AppSettings settings;
  final RentalsController rentals;
  final List<RentalProduct> products;
  final Set<String> favorites;
  final ValueChanged<RentalProduct> onRemoveFavorite;
  final ValueChanged<RentalProduct> onOpenProduct;
  final ValueChanged<String> onSortChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _Section _section = _Section.profile;

  void _select(_Section section) => setState(() => _section = section);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final menu = _ProfileMenu(
      selected: _section,
      onSelect: (section) {
        if (!wide) Navigator.pop(context);
        _select(section);
      },
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.brandPanel,
        foregroundColor: AppColors.white,
        leading: wide
            ? const BackButton()
            : Builder(
                builder: (context) => IconButton(
                  tooltip: 'Menú del perfil',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: const Text(
          'Mi cuenta',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Volver al inicio',
            color: AppColors.mustard,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: menu)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide) ...[
                  SizedBox(width: 248, child: menu),
                  VerticalDivider(
                    width: 1,
                    color: context.colors.outlineVariant,
                  ),
                ],
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.settings,
                      widget.rentals,
                    ]),
                    builder: (context, _) => ListView(
                      key: ValueKey(_section),
                      padding: EdgeInsets.all(wide ? 32 : 16),
                      children: [
                        if (_section == _Section.profile)
                          _identity(context)
                        else
                          Text(
                            _section.label,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        const SizedBox(height: 20),
                        _sectionBody(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity(BuildContext context) {
    final account = widget.account;
    final initials = [account.firstName, account.lastName]
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim().characters.first.toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.brandPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: AppColors.mustard,
            foregroundColor: AppColors.espresso,
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MI PERFIL',
                  style: TextStyle(
                    color: AppColors.mustard,
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${account.firstName} ${account.lastName}',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody(BuildContext context) {
    final account = widget.account;
    final orders = widget.rentals.orders;
    switch (_section) {
      case _Section.profile:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Panel(
              title: 'Datos de contacto',
              children: [
                ListTile(
                  leading: const Icon(Icons.alternate_email_rounded),
                  title: const Text('Correo electrónico'),
                  subtitle: SelectableText(account.email),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Dirección registrada'),
                  subtitle: SelectableText(account.address),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Mi actividad',
              children: [
                _link(
                  _Section.favorites,
                  widget.favorites.length == 1
                      ? '1 artículo guardado'
                      : '${widget.favorites.length} artículos guardados',
                ),
                _link(
                  _Section.history,
                  orders.length == 1
                      ? '1 renta registrada'
                      : '${orders.length} rentas registradas',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        );
      case _Section.favorites:
        final products = widget.products
            .where((p) => widget.favorites.contains(p.id))
            .toList();
        if (products.isEmpty) {
          return const _Empty(
            Icons.favorite_border_rounded,
            'Aún no tienes favoritos',
            'Toca el corazón de un artículo en el catálogo para guardarlo aquí.',
          );
        }
        return _Panel(
          children: [
            for (final product in products)
              ListTile(
                leading: Icon(product.imageIcon),
                title: Text(product.name),
                subtitle: Text('${pesos(product.pricePerDay)} por día'),
                onTap: () => widget.onOpenProduct(product),
                trailing: IconButton(
                  tooltip: 'Quitar de favoritos',
                  icon: const Icon(Icons.favorite_rounded),
                  onPressed: () =>
                      setState(() => widget.onRemoveFavorite(product)),
                ),
              ),
          ],
        );
      case _Section.history:
        if (orders.isEmpty) {
          return const _Empty(
            Icons.history_rounded,
            'Tu historial de rentas está vacío',
            'Aquí podrás consultar cada renta y seguir su entrega.',
          );
        }
        return _Panel(
          children: [
            for (final order in orders)
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(
                  order.items.map((item) => item.product.name).join(', '),
                ),
                subtitle: Text(
                  '${order.idRenta} · ${order.estadoRenta}\n${pesos(order.totalAmount)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShipmentTrackingPage(
                      rentals: widget.rentals,
                      orderId: order.idRenta,
                      account: account,
                    ),
                  ),
                ),
              ),
          ],
        );
      case _Section.coupons:
        return const _Empty(
          Icons.confirmation_number_outlined,
          'Sin cupones disponibles',
          'Actualmente no hay promociones activas para tu cuenta.',
        );
      case _Section.billing:
        if (orders.isEmpty) {
          return const _Empty(
            Icons.receipt_long_outlined,
            'Aún no tienes comprobantes',
            'Cuando confirmes una renta, podrás consultar su desglose de pago aquí.',
          );
        }
        return _Panel(
          title: 'Comprobantes de la demo',
          children: [
            for (final order in orders)
              ExpansionTile(
                title: Text(order.idRenta),
                subtitle: Text(
                  '${pesos(order.totalAmount)} · ${order.payment.estado}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(order.payment.fechaPago),
                  ),
                  Text(
                    'Pago ${order.payment.idPago} · ${order.payment.metodoPago.label}',
                  ),
                  Text('Renta · ${pesos(order.rentalSubtotal)}'),
                  Text('Envío · ${pesos(order.shippingCost)}'),
                  Text(
                    'Depósito reembolsable por separado · ${pesos(order.depositTotal)}',
                  ),
                ],
              ),
          ],
        );
      case _Section.settings:
        final settings = widget.settings;
        return _Panel(
          title: 'Preferencias de este dispositivo',
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Tema oscuro'),
              subtitle: const Text('Usar un fondo negro en toda la app.'),
              value: settings.darkMode,
              onChanged: settings.setDarkMode,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                initialValue: settings.catalogSort,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Orden del catálogo',
                ),
                items: [
                  for (final sort in AppSettings.sortOptions)
                    DropdownMenuItem(value: sort, child: Text(sort)),
                ],
                onChanged: (value) {
                  if (value != null) widget.onSortChanged(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<DeliveryMethod>(
                initialValue: settings.preferredDelivery,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Entrega para nuevos carritos',
                ),
                items: [
                  for (final method in DeliveryMethod.values)
                    DropdownMenuItem(value: method, child: Text(method.label)),
                ],
                onChanged: (value) {
                  if (value != null) settings.setPreferredDelivery(value);
                },
              ),
            ),
          ],
        );
      case _Section.help:
        return _Panel(
          children: [
            _link(
              _Section.history,
              'Selecciona una renta para rastrear su envío o reportar un problema.',
            ),
            _link(
              _Section.faq,
              'Consulta cómo rentar, guardar artículos y elegir la entrega.',
            ),
            _link(
              _Section.billing,
              'Revisa importes y formas de pago de tus rentas.',
            ),
          ],
        );
      case _Section.faq:
        return const _Panel(
          children: [
            _Question(
              '¿Cómo elijo las fechas de renta?',
              'Abre el artículo en el catálogo, elige el primer y el último día y agrégalo al carrito. El periodo incluye ambos días.',
            ),
            _Question(
              '¿Dónde encuentro mis artículos guardados?',
              'Toca el corazón en la tarjeta del artículo. Puedes volver a abrirlo o quitarlo desde Favoritos en tu perfil.',
            ),
            _Question(
              '¿Puedo recoger mi pedido?',
              'Sí. En el carrito elige recoger con el arrendador. También puedes guardar esa opción en Configuración para tus próximas rentas.',
            ),
            _Question(
              '¿Cómo reporto un problema?',
              'En Historial, abre la renta correspondiente y selecciona Reportar en la pantalla de seguimiento.',
            ),
          ],
        );
      case _Section.terms:
        return const _Panel(
          title: 'Uso de la demostración',
          children: [
            ListTile(
              title: Text('Datos de prueba'),
              subtitle: Text(
                'Usa información ficticia para registrar tu cuenta y probar el pago. Las cuentas y rentas se conservan mientras la aplicación está abierta.',
              ),
            ),
            ListTile(
              title: Text('Rentas y pagos simulados'),
              subtitle: Text(
                'Las fechas, importes y estados de envío sirven para probar el proceso de renta. Los comprobantes son de demostración y carecen de validez fiscal.',
              ),
            ),
          ],
        );
      case _Section.about:
        return const _Panel(
          title: 'Acerca de Usus',
          children: [
            ListTile(
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text('Usus'),
              subtitle: Text(
                'Encuentra herramientas y equipo cerca de ti, publica artículos que quieras compartir y administra tus rentas desde una sola cuenta.',
              ),
            ),
          ],
        );
    }
  }

  Widget _link(_Section section, String description) => ListTile(
    leading: Icon(section.icon),
    title: Text(section.label),
    subtitle: Text(description),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => _select(section),
  );
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.selected, required this.onSelect});
  final _Section selected;
  final ValueChanged<_Section> onSelect;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      children: [
        for (final section in _Section.values) ...[
          if (section == _Section.help || section == _Section.terms)
            Divider(height: 24, color: context.colors.outlineVariant),
          ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            selected: selected == section,
            selectedTileColor: AppColors.mustard.withValues(alpha: .18),
            selectedColor: context.colors.onSurface,
            leading: Icon(section.icon, size: 20),
            title: Text(
              section.label,
              style: TextStyle(
                fontWeight: selected == section
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            onTap: () => onSelect(section),
          ),
        ],
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: context.colors.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ...children,
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.icon, this.title, this.detail);
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => _Panel(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: context.colors.surfaceContainerLow,
              child: Icon(icon, color: context.colors.secondary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    ],
  );
}

class _Question extends StatelessWidget {
  const _Question(this.question, this.answer);
  final String question;
  final String answer;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(question),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    expandedAlignment: Alignment.centerLeft,
    children: [Text(answer)],
  );
}
