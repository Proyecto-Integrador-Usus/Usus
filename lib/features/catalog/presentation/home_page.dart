import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/account_page.dart';
import '../../cart/data/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../rentals/data/rentals_controller.dart';
import '../../rentals/domain/rental_period.dart';
import '../../rentals/presentation/my_rentals_page.dart';
import '../data/catalog_repository.dart';
import '../domain/rental_product.dart';
import 'product_details_page.dart';
import 'publish_product_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.auth,
    required this.settings,
  });

  final CatalogRepository repository;
  final AuthRepository auth;
  final AppSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  RentalCategory _category = RentalCategory.all;
  RangeValues _priceRange = const RangeValues(0, 1000);
  String? _sortOverride;
  String get _sort => _sortOverride ?? widget.settings.catalogSort;
  AccountProfile? _account;
  bool _loading = true;
  String? _catalogError;
  final _cart = CartController();
  final _accountRentals = <String?, RentalsController>{};
  String? get _accountKey => _account?.email.trim().toLowerCase();
  RentalsController get _rentals =>
      _accountRentals.putIfAbsent(_accountKey, RentalsController.new);
  List<RentalProduct> _products = [];
  final _accountFavorites = <String, Set<String>>{};
  final _guestFavorites = <String>{};
  Set<String> get _favorites => _accountKey == null
      ? _guestFavorites
      : _accountFavorites.putIfAbsent(_accountKey!, () => <String>{});

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_loading && mounted) {
      setState(() {
        _loading = true;
        _catalogError = null;
      });
    }
    try {
      final products = await widget.repository.getProducts();
      if (mounted) setState(() => _products = products);
    } catch (_) {
      if (mounted) {
        setState(
          () => _catalogError =
              'No fue posible cargar el catálogo. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cart.dispose();
    for (final rentals in _accountRentals.values) {
      rentals.dispose();
    }
    super.dispose();
  }

  List<RentalProduct> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    final products = _products.where((product) {
      if (!product.isAvailable) return false;
      final matchesCategory =
          _category == RentalCategory.all || product.category == _category;
      final matchesPrice =
          product.pricePerDay >= _priceRange.start &&
          product.pricePerDay <= _priceRange.end;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.label.toLowerCase().contains(query) ||
          product.location.toLowerCase().contains(query);
      return matchesCategory && matchesPrice && matchesQuery;
    }).toList();
    if (_sort == 'Menor precio') {
      products.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (_sort == 'Mejor valorados') {
      products.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return products;
  }

  void _selectCategory(RentalCategory category) {
    setState(() => _category = category);
    Scaffold.maybeOf(context)?.closeDrawer();
  }

  Future<void> _openAccount(AccountMode mode) async {
    final account = await Navigator.of(context).push<AccountProfile>(
      MaterialPageRoute(
        builder: (_) => AccountPage(repository: widget.auth, initialMode: mode),
      ),
    );
    if (mounted && account != null) {
      setState(() {
        _account = account;
        _favorites.addAll(_guestFavorites);
        _guestFavorites.clear();
      });
    }
  }

  Future<void> _openProfile() async {
    final account = _account;
    if (account == null) return;
    final signOut = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          account: account,
          settings: widget.settings,
          rentals: _rentals,
          products: _products,
          favorites: _favorites,
          onRemoveFavorite: (product) =>
              setState(() => _favorites.remove(product.id)),
          onOpenProduct: _openDetails,
          onSortChanged: (value) {
            widget.settings.setCatalogSort(value);
            setState(() => _sortOverride = null);
          },
        ),
      ),
    );
    if (mounted && signOut == true) {
      setState(() {
        _account = null;
        _cart.clear();
      });
    }
  }

  Future<void> _openCart() async {
    final account = _account;
    if (account == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CartPage(
          cart: _cart,
          account: account,
          rentals: _rentals,
        ),
      ),
    );
  }

  Future<void> _openMyRentals() async {
    final account = _account;
    if (account == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyRentalsPage(
          rentals: _rentals,
          account: account,
        ),
      ),
    );
  }

  Future<void> _openPublishProduct() async {
    final account = _account;
    if (account == null) return;
    final created = await Navigator.of(context).push<RentalProduct>(
      MaterialPageRoute(
        builder: (_) => PublishProductPage(
          repository: widget.repository,
          account: account,
        ),
      ),
    );
    if (!mounted || created == null) return;
    await _loadProducts();
    if (mounted) {
      _showMessage('${created.name} publicado en el catálogo');
    }
  }

  Future<void> _openDetails(RentalProduct product) async {
    final period = await Navigator.of(context).push<RentalPeriod>(
      MaterialPageRoute(builder: (_) => ProductDetailsPage(
        product: product,
        signedIn: _account != null,
        signIn: () async {
          await _openAccount(AccountMode.login);
          return mounted && _account != null;
        },
      )),
    );
    if (mounted && period != null && _account != null) {
      _addToCart(product, period: period);
    }
  }

  void _addToCart(RentalProduct product, {RentalPeriod? period}) {
    if (_cart.isEmpty) {
      _cart.setDeliveryMethod(widget.settings.preferredDelivery);
    }
    _cart.addProduct(product, period: period);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado al carrito'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: _openCart,
          ),
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1060;
        final tablet = constraints.maxWidth >= 680;
        final products = _visibleProducts;

        return Scaffold(
          drawer: wide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: _CategorySidebar(
                      selected: _category,
                      priceRange: _priceRange,
                      onCategorySelected: _selectCategory,
                      onPriceChanged: (value) =>
                          setState(() => _priceRange = value),
                    ),
                  ),
                ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: Listenable.merge([_cart, _rentals]),
                  builder: (context, _) => _TopBar(
                    wide: wide,
                    tablet: tablet,
                    cartCount: _cart.totalUnits,
                    rentalsCount: _rentals.orders.length,
                    searchController: _searchController,
                    onSearchChanged: (_) => setState(() {}),
                    account: _account,
                    onAccountTap: () => _openAccount(AccountMode.login),
                    onRegister: () => _openAccount(AccountMode.register),
                    onProfileTap: _openProfile,
                    onCartTap: _openCart,
                    onRentalsTap: _openMyRentals,
                    onAddProduct: _openPublishProduct,
                  ),
                ),
                if (!wide)
                  _MobileSearch(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: wide
                                ? 36
                                : tablet
                                ? 24
                                : 16,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1420),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  _HeroBanner(
                                    onExplore: () =>
                                        _selectCategory(RentalCategory.all),
                                  ),
                                  const SizedBox(height: 28),
                                  if (!wide)
                                    _CategoryChips(
                                      selected: _category,
                                      onSelected: (category) =>
                                          setState(() => _category = category),
                                    ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (wide) ...[
                                        SizedBox(
                                          width: 224,
                                          child: _CategorySidebar(
                                            selected: _category,
                                            priceRange: _priceRange,
                                            onCategorySelected: _selectCategory,
                                            onPriceChanged: (value) => setState(
                                              () => _priceRange = value,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                      ],
                                      Expanded(
                                        child: _CatalogSection(
                                          products: products,
                                          loading: _loading,
                                          errorMessage: _catalogError,
                                          onRetry: _loadProducts,
                                          category: _category,
                                          sort: _sort,
                                          favorites: _favorites,
                                          signedIn: _account != null,
                                          onSortChanged: (value) =>
                                              setState(() => _sortOverride = value),
                                          onClearFilters: () => setState(() {
                                            _category = RentalCategory.all;
                                            _priceRange = const RangeValues(
                                              0,
                                              1000,
                                            );
                                            _searchController.clear();
                                            _sortOverride = null;
                                          }),
                                          onFavorite: (product) => setState(() {
                                            if (!_favorites.add(product.id)) {
                                              _favorites.remove(product.id);
                                            }
                                          }),
                                          onAddToCart: _addToCart,
                                          onDetails: _openDetails,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _Footer(
                          onCategorySelected: _selectCategory,
                          horizontalPadding: wide
                              ? 36
                              : tablet
                              ? 24
                              : 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.wide,
    required this.tablet,
    required this.cartCount,
    required this.rentalsCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAccountTap,
    required this.account,
    required this.onRegister,
    required this.onProfileTap,
    required this.onCartTap,
    required this.onRentalsTap,
    required this.onAddProduct,
  });

  final bool wide;
  final bool tablet;
  final int cartCount;
  final int rentalsCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAccountTap;
  final AccountProfile? account;
  final VoidCallback onRegister;
  final VoidCallback onProfileTap;
  final VoidCallback onCartTap;
  final VoidCallback onRentalsTap;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: wide
            ? 36
            : tablet
            ? 24
            : 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (!wide)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Categorías',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu_rounded, color: context.colors.onSurface),
              ),
            ),
          _Brand(),
          if (wide) ...[
            const SizedBox(width: 42),
            Expanded(
              child: _SearchField(
                controller: searchController,
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 22),
          ] else
            const Spacer(),
          if (account != null) ...[
            if (wide)
              TextButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                label: const Text('Publicar artículo'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                ),
              )
            else
              IconButton(
                tooltip: 'Publicar artículo',
                visualDensity: VisualDensity.compact,
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            if (wide) const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Mis rentas',
                  visualDensity: wide ? null : VisualDensity.compact,
                  onPressed: onRentalsTap,
                  icon: const Icon(Icons.local_shipping_outlined),
                ),
                if (rentalsCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: context.brandPanel,
                      child: Text(
                        '$rentalsCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Carrito',
                  visualDensity: wide ? null : VisualDensity.compact,
                  onPressed: onCartTap,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.mustard,
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.espresso,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'Mi perfil',
              onPressed: onProfileTap,
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: context.colors.surfaceContainerLow,
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ] else ...[
            if (tablet)
              TextButton(
                onPressed: onAccountTap,
                child: const Text('Iniciar sesión'),
              )
            else
              IconButton(
                tooltip: 'Iniciar sesión',
                onPressed: onAccountTap,
                icon: const Icon(Icons.person_outline_rounded),
              ),
            FilledButton(
              onPressed: onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mustard,
                foregroundColor: AppColors.espresso,
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? 18 : 13,
                  vertical: 13,
                ),
              ),
              child: Text(tablet ? 'Crear cuenta' : 'Crear'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.mustard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.espresso,
          size: 25,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'usus',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.3,
        ),
      ),
    ],
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: '¿Qué necesitas rentar?',
      prefixIcon: Icon(Icons.search_rounded, color: context.colors.onSurface),
      suffixIcon: Icon(
        Icons.tune_rounded,
        size: 20,
        color: context.colors.secondary,
      ),
    ),
  );
}

class _MobileSearch extends StatelessWidget {
  const _MobileSearch({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: _SearchField(controller: controller, onChanged: onChanged),
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 224),
    decoration: BoxDecoration(
      color: context.goldPanel,
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        colors: [
          context.colors.brightness == Brightness.dark
              ? const Color(0xFF483B20)
              : const Color(0xFFD9B944),
          context.goldPanel,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 36,
          top: -24,
          child: Icon(
            Icons.handyman_rounded,
            size: 210,
            color: AppColors.espresso.withValues(alpha: .08),
          ),
        ),
        Positioned(
          right: 172,
          bottom: 28,
          child: Icon(
            Icons.celebration_rounded,
            size: 72,
            color: AppColors.white.withValues(alpha: .38),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 28, 26, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.espresso.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: const Text(
                    'MENOS COMPRAS, MÁS POSIBILIDADES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Lo necesitas.\nLo rentas.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: MediaQuery.sizeOf(context).width < 500 ? 31 : 38,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Encuentra herramientas y equipo cerca de ti.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  label: const Text('Explorar artículos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.selected,
    required this.priceRange,
    required this.onCategorySelected,
    required this.onPriceChanged,
  });
  final RentalCategory selected;
  final RangeValues priceRange;
  final ValueChanged<RentalCategory> onCategorySelected;
  final ValueChanged<RangeValues> onPriceChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Categorías',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      const SizedBox(height: 12),
      for (final category in RentalCategory.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onCategorySelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: category == selected
                    ? AppColors.mustard.withValues(alpha: .2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 19,
                    color: category == selected
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: category == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (category == selected)
                    const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 20),
      Divider(color: context.colors.outlineVariant),
      const SizedBox(height: 12),
      const Text(
        'Precio por día',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      RangeSlider(
        values: priceRange,
        min: 0,
        max: 1000,
        divisions: 20,
        activeColor: AppColors.mustard,
        labels: RangeLabels(
          '\$${priceRange.start.round()}',
          '\$${priceRange.end.round()}',
        ),
        onChanged: onPriceChanged,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${priceRange.start.round()}',
            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            '\$${priceRange.end.round()} MXN',
            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, size: 20, color: context.colors.secondary),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Renta cerca, ahorra y comparte con tu comunidad.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});
  final RentalCategory selected;
  final ValueChanged<RentalCategory> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: RentalCategory.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = RentalCategory.values[index];
        final active = category == selected;
        return ChoiceChip(
          label: Text(category.label),
          avatar: Icon(
            category.icon,
            size: 16,
            color: active ? context.colors.onSurface : context.colors.onSurfaceVariant,
          ),
          selected: active,
          onSelected: (_) => onSelected(category),
          selectedColor: AppColors.mustard.withValues(alpha: .3),
          backgroundColor: context.colors.surface,
          side: BorderSide(
            color: active ? AppColors.mustard : context.colors.outlineVariant,
          ),
          labelStyle: TextStyle(
            color: context.colors.onSurface,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        );
      },
    ),
  );
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.products,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.category,
    required this.sort,
    required this.favorites,
    required this.signedIn,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onDetails,
  });
  final List<RentalProduct> products;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final RentalCategory category;
  final String sort;
  final Set<String> favorites;
  final bool signedIn;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<RentalProduct> onFavorite;
  final ValueChanged<RentalProduct> onAddToCart;
  final ValueChanged<RentalProduct> onDetails;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == RentalCategory.all
                      ? 'Artículos para rentar'
                      : category.label,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 5),
                Text(
                  loading
                      ? 'Cargando catálogo…'
                      : '${products.length} artículos disponibles cerca de ti',
                  style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sort,
              borderRadius: BorderRadius.circular(14),
              items: [
                for (final option in AppSettings.sortOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      if (loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(52),
            child: CircularProgressIndicator(color: AppColors.mustard),
          ),
        )
      else if (errorMessage != null)
        _CatalogError(message: errorMessage!, onRetry: onRetry)
      else if (products.isEmpty)
        _EmptyResults(onClear: onClearFilters)
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1060
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            return GridView.builder(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 342,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(
                  product: product,
                  isFavorite: favorites.contains(product.id),
                  signedIn: signedIn,
                  onFavorite: () => onFavorite(product),
                  onAddToCart: () => onAddToCart(product),
                  onDetails: () => onDetails(product),
                );
              },
            );
          },
        ),
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.signedIn,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onDetails,
  });
  final RentalProduct product;
  final bool isFavorite;
  final bool signedIn;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onDetails,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.outlineVariant.withValues(alpha: .8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B3B2F2F),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 178,
                  width: double.infinity,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ProductPlaceholder(
                      icon: product.imageIcon,
                      category: product.category,
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : _ProductPlaceholder(
                            icon: product.imageIcon,
                            category: product.category,
                          ),
                  ),
                ),
                if (product.isPopular)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mustard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(color: AppColors.espresso,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Material(
                    color: context.colors.surface,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: isFavorite
                          ? 'Quitar de favoritos'
                          : 'Guardar en favoritos',
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 19,
                        color: isFavorite
                            ? Colors.redAccent
                            : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.category.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: .8,
                              color: context.colors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: AppColors.mustard,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${product.pricePerDay.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: context.colors.onSurface,
                          ),
                        ),
                        Text(
                          ' / día',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 37,
                      child: signedIn
                          ? OutlinedButton.icon(
                              onPressed: onAddToCart,
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                              ),
                              label: const Text('Agregar al carrito'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.colors.onSurface,
                                side: BorderSide(color: context.colors.outlineVariant),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: onDetails,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.colors.onSurface,
                                side: BorderSide(color: context.colors.outlineVariant),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text('Ver artículo'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.icon, required this.category});
  final IconData icon;
  final RentalCategory category;
  @override
  Widget build(BuildContext context) => Container(
    color: context.colors.surfaceContainerLow,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: 82, color: context.colors.secondary.withValues(alpha: .65)),
        Positioned(
          left: 12,
          bottom: 10,
          child: Text(
            category.label,
            style: TextStyle(
              fontSize: 11,
              color: context.colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: context.colors.secondary),
          const SizedBox(height: 12),
          const Text(
            'No encontramos artículos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Prueba otra búsqueda o ajusta tus filtros.',
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Ver recomendaciones'),
          ),
        ],
      ),
    ),
  );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 42, color: context.colors.secondary),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onCategorySelected,
    required this.horizontalPadding,
  });
  final ValueChanged<RentalCategory> onCategorySelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: context.brandPanel,
    padding: EdgeInsets.fromLTRB(
      horizontalPadding,
      32,
      horizontalPadding,
      24,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 700;
            final brand = _FooterBrand();
            final explore = _FooterLinkGroup(
              title: 'Explora',
              links: [
                _FooterLink(
                  'Fiestas y eventos',
                  () => onCategorySelected(RentalCategory.party),
                ),
                _FooterLink(
                  'Construcción',
                  () => onCategorySelected(RentalCategory.construction),
                ),
                _FooterLink(
                  'Herramientas',
                  () => onCategorySelected(RentalCategory.tools),
                ),
              ],
            );
            const about = _FooterLinkGroup(
              title: 'Usus',
              links: [
                _FooterLink('Renta cerca de ti', null),
                _FooterLink('Comparte lo que tienes', null),
                _FooterLink('Hecho para la comunidad', null),
              ],
            );
            const help = _FooterLinkGroup(
              title: 'Información',
              links: [
                _FooterLink('Cómo funciona', null),
                _FooterLink('Ayuda y contacto', null),
                _FooterLink('Privacidad y términos', null),
              ],
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  const SizedBox(height: 28),
                  explore,
                  const SizedBox(height: 22),
                  about,
                  const SizedBox(height: 22),
                  help,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: brand),
                Expanded(child: explore),
                const Expanded(child: about),
                const Expanded(child: help),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const Divider(color: Color(0x554A3E3E), height: 1),
        const SizedBox(height: 15),
        Text(
          '© ${DateTime.now().year} Usus. Todos los derechos reservados.',
          style: const TextStyle(color: Color(0xFFC9BFB4), fontSize: 11),
        ),
      ],
        ),
      ),
    ),
  );
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.mustard,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.espresso,
              size: 23,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'usus',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Renta lo que necesitas.\nComparte lo que ya tienes.',
        style: TextStyle(color: Color(0xFFD2C8BC), fontSize: 13, height: 1.5),
      ),
    ],
  );
}

class _FooterLink {
  const _FooterLink(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;
}

class _FooterLinkGroup extends StatelessWidget {
  const _FooterLinkGroup({required this.title, required this.links});
  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      for (final link in links)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: link.onTap == null
              ? Text(
                  link.label,
                  style: const TextStyle(
                    color: Color(0xFFC9BFB4),
                    fontSize: 12,
                  ),
                )
              : InkWell(
                  onTap: link.onTap,
                  child: Text(
                    link.label,
                    style: const TextStyle(
                      color: Color(0xFFC9BFB4),
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
    ],
  );
}
