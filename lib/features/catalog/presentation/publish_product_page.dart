import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/catalog_repository.dart';
import '../domain/rental_product.dart';

class PublishProductPage extends StatefulWidget {
  const PublishProductPage({
    super.key,
    required this.repository,
    required this.account,
  });

  final CatalogRepository repository;
  final AccountProfile account;

  @override
  State<PublishProductPage> createState() => _PublishProductPageState();
}

class _PublishProductPageState extends State<PublishProductPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _deposit = TextEditingController(text: '0');
  late final TextEditingController _location = TextEditingController(
    text: widget.account.address.trim().isNotEmpty
        ? widget.account.address.trim()
        : 'Zona Centro, Aguascalientes',
  );
  final _imageUrlInput = TextEditingController();

  RentalCategory _category = RentalCategory.party;
  String _condition = 'Como nuevo';
  bool _isAvailable = true;
  bool _submitting = false;
  String? _imageError;
  String? _submitError;
  final List<String> _imageUrls = [];

  static const _conditions = [
    'Nuevo',
    'Como nuevo',
    'Buen estado',
    'Uso normal',
  ];

  static const _zones = [
    'Zona Centro, Aguascalientes',
    'Zona Norte, Aguascalientes',
    'Zona Sur, Aguascalientes',
  ];

  static const _sampleByCategory = <RentalCategory, String>{
    RentalCategory.party:
        'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=900&q=80',
    RentalCategory.construction:
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=900&q=80',
    RentalCategory.plumbing:
        'https://images.unsplash.com/photo-1607400201515-c2c41c07d307?auto=format&fit=crop&w=900&q=80',
    RentalCategory.gardening:
        'https://images.unsplash.com/photo-1599685315640-7ec6f22d4a5b?auto=format&fit=crop&w=900&q=80',
    RentalCategory.audio:
        'https://images.unsplash.com/photo-1593078166034-9e3b6b8a7c35?auto=format&fit=crop&w=900&q=80',
    RentalCategory.tools:
        'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=900&q=80',
  };

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _price,
      _deposit,
      _location,
      _imageUrlInput,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageUrl() {
    final raw = _imageUrlInput.text.trim();
    final uri = Uri.tryParse(raw);
    final validWeb = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final validAsset = raw.startsWith('assets/');

    if (!validWeb && !validAsset) {
      setState(() {
        _imageError =
            'Ingresa una URL válida (https://...) o ruta de asset.';
      });
      return;
    }
    if (_imageUrls.contains(raw)) {
      setState(() => _imageError = 'Esa imagen ya está agregada.');
      return;
    }
    setState(() {
      _imageUrls.add(raw);
      _imageUrlInput.clear();
      _imageError = null;
    });
  }

  void _addSampleImage() {
    final sample = _sampleByCategory[_category];
    if (sample == null || _imageUrls.contains(sample)) return;
    setState(() {
      _imageUrls.add(sample);
      _imageError = null;
    });
  }

  void _setAsCover(int index) {
    if (index <= 0 || index >= _imageUrls.length) return;
    setState(() {
      final selected = _imageUrls.removeAt(index);
      _imageUrls.insert(0, selected);
    });
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  String? _validateRequired(String? value, {int minLength = 1}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Completa este campo.';
    if (text.length < minLength) {
      return 'Escribe al menos $minLength caracteres.';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un precio por día mayor a 0.';
    }
    return null;
  }

  String? _validateDeposit(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) {
      return 'Ingresa un depósito válido (0 o mayor).';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final pricePerDay = double.parse(_price.text.trim());
    final deposit = double.tryParse(_deposit.text.trim()) ?? 0;
    final newProduct = RentalProduct(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      pricePerDay: pricePerDay,
      location: _location.text.trim(),
      rating: 5.0,
      imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : '',
      imageIcon: _category.icon,
      description: _description.text.trim(),
      deposit: deposit,
      condition: _condition,
      isAvailable: _isAvailable,
      imageUrls: List.unmodifiable(_imageUrls),
    );

    try {
      final created = await widget.repository.addProduct(newProduct);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError =
              'No se pudo publicar el artículo. Intenta de nuevo.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = RentalCategory.values
        .where((c) => c != RentalCategory.all)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Publicar artículo en renta',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final horizontalPadding = wide ? 36.0 : 16.0;

          final photosCard = _PhotosSection(
            imageUrls: _imageUrls,
            category: _category,
            imageUrlController: _imageUrlInput,
            imageError: _imageError,
            onAddUrl: _addImageUrl,
            onAddSample: _addSampleImage,
            onSetCover: _setAsCover,
            onRemove: _removeImage,
          );

          final previewCard = _ListingPreviewCard(
            name: _name.text.trim().isEmpty
                ? 'Nombre de tu artículo'
                : _name.text.trim(),
            category: _category,
            pricePerDay: double.tryParse(_price.text.trim()) ?? 0,
            location: _location.text.trim().isEmpty
                ? 'Zona por definir'
                : _location.text.trim(),
            condition: _condition,
            coverUrl: _imageUrls.isNotEmpty ? _imageUrls.first : '',
            ownerName: '${widget.account.firstName} ${widget.account.lastName}',
          );

          final detailsCard = _FormDetailsCard(
            categories: categories,
            selectedCategory: _category,
            selectedCondition: _condition,
            conditions: _conditions,
            zones: _zones,
            isAvailable: _isAvailable,
            nameController: _name,
            descriptionController: _description,
            priceController: _price,
            depositController: _deposit,
            locationController: _location,
            submitting: _submitting,
            submitError: _submitError,
            onCategoryChanged: (c) => setState(() => _category = c),
            onConditionChanged: (cond) => setState(() => _condition = cond),
            onZoneSelected: (zone) => setState(() => _location.text = zone),
            onAvailableChanged: (val) => setState(() => _isAvailable = val),
            onFieldChanged: () => setState(() {}),
            validateRequired: _validateRequired,
            validatePrice: _validatePrice,
            validateDeposit: _validateDeposit,
            onSubmit: _submit,
          );

          return Form(
            key: _form,
            child: SingleChildScrollView(
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
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  photosCard,
                                  const SizedBox(height: 16),
                                  previewCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 7, child: detailsCard),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            photosCard,
                            const SizedBox(height: 16),
                            detailsCard,
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.imageUrls,
    required this.category,
    required this.imageUrlController,
    required this.imageError,
    required this.onAddUrl,
    required this.onAddSample,
    required this.onSetCover,
    required this.onRemove,
  });

  final List<String> imageUrls;
  final RentalCategory category;
  final TextEditingController imageUrlController;
  final String? imageError;
  final VoidCallback onAddUrl;
  final VoidCallback onAddSample;
  final ValueChanged<int> onSetCover;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotos del artículo',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega imágenes reales del estado del artículo. La primera será la portada.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (imageUrls.isEmpty)
            Container(
              height: 132,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: 38,
                    color: AppColors.tan,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aún no agregas fotos (opcional para pruebas)',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  final isCover = index == 0;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 126,
                          height: 126,
                          child: url.startsWith('assets/')
                              ? Image.asset(url, fit: BoxFit.cover)
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.ivory,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      category.icon,
                                      color: AppColors.tan,
                                      size: 34,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (isCover)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mustard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Portada',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Material(
                            color: AppColors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => onSetCover(index),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Usar portada',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Material(
                          color: AppColors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Quitar foto',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => onRemove(index),
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: imageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL de imagen',
                    hintText: 'https://...',
                    errorText: imageError,
                  ),
                  onFieldSubmitted: (_) => onAddUrl(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAddUrl,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: const Text('Usar foto de ejemplo'),
                onPressed: onAddSample,
              ),
              ActionChip(
                avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Cámara / galería (próximamente)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La subida directa desde cámara o galería se habilitará al conectar almacenamiento.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingPreviewCard extends StatelessWidget {
  const _ListingPreviewCard({
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.location,
    required this.condition,
    required this.coverUrl,
    required this.ownerName,
  });

  final String name;
  final RentalCategory category;
  final double pricePerDay;
  final String location;
  final String condition;
  final String coverUrl;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa en catálogo',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.ivory,
                        alignment: Alignment.center,
                        child: Icon(
                          category.icon,
                          size: 46,
                          color: AppColors.tan,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.ivory,
                      alignment: Alignment.center,
                      child: Icon(
                        category.icon,
                        size: 46,
                        color: AppColors.tan,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${category.label.toUpperCase()} · $condition',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: AppColors.tan,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$location · Por $ownerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              Text(
                '\$${pricePerDay.toStringAsFixed(0)} / día',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormDetailsCard extends StatelessWidget {
  const _FormDetailsCard({
    required this.categories,
    required this.selectedCategory,
    required this.selectedCondition,
    required this.conditions,
    required this.zones,
    required this.isAvailable,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.depositController,
    required this.locationController,
    required this.submitting,
    required this.submitError,
    required this.onCategoryChanged,
    required this.onConditionChanged,
    required this.onZoneSelected,
    required this.onAvailableChanged,
    required this.onFieldChanged,
    required this.validateRequired,
    required this.validatePrice,
    required this.validateDeposit,
    required this.onSubmit,
  });

  final List<RentalCategory> categories;
  final RentalCategory selectedCategory;
  final String selectedCondition;
  final List<String> conditions;
  final List<String> zones;
  final bool isAvailable;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController depositController;
  final TextEditingController locationController;
  final bool submitting;
  final String? submitError;
  final ValueChanged<RentalCategory> onCategoryChanged;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<String> onZoneSelected;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onFieldChanged;
  final String? Function(String?, {int minLength}) validateRequired;
  final String? Function(String?) validatePrice;
  final String? Function(String?) validateDeposit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Detalles del producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Completa la información para que los clientes puedan cotizar y rentar con claridad.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título del artículo',
                hintText: 'Ej. Juego de 10 sillas plegables reforzadas',
              ),
              validator: (v) => validateRequired(v, minLength: 3),
              onChanged: (_) => onFieldChanged(),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RentalCategory>(
              initialValue: selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 18, color: AppColors.espresso),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Estado físico',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final condition in conditions)
                  ChoiceChip(
                    label: Text(condition),
                    selected: selectedCondition == condition,
                    selectedColor: AppColors.mustard.withValues(alpha: 0.3),
                    backgroundColor: AppColors.ivory,
                    onSelected: (_) => onConditionChanged(condition),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción y qué incluye',
                hintText:
                    'Describe medidas, accesorios incluidos, requisitos de uso o cuidados.',
                alignLabelWithHint: true,
              ),
              validator: (v) => validateRequired(v, minLength: 10),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 460;
                final priceField = TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio por día (MXN)',
                    prefixText: '\$ ',
                  ),
                  validator: validatePrice,
                  onChanged: (_) => onFieldChanged(),
                );
                final depositField = TextFormField(
                  controller: depositController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Depósito en garantía (MXN)',
                    prefixText: '\$ ',
                    helperText: 'Reembolsable al devolver en buen estado',
                  ),
                  validator: validateDeposit,
                );
                if (narrow) {
                  return Column(
                    children: [
                      priceField,
                      const SizedBox(height: 14),
                      depositField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: priceField),
                    const SizedBox(width: 12),
                    Expanded(child: depositField),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Zona operativa / Ubicación de entrega',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final zone in zones)
                  ActionChip(
                    label: Text(zone.replaceAll(', Aguascalientes', '')),
                    onPressed: () => onZoneSelected(zone),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación o zona',
                hintText: 'Ej. Zona Centro, Aguascalientes',
              ),
              validator: (v) => validateRequired(v, minLength: 3),
              onChanged: (_) => onFieldChanged(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isAvailable,
              activeThumbColor: AppColors.mustard,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Disponible para rentar de inmediato',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Si lo desactivas, quedará guardado pero oculto para rentas.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              onChanged: onAvailableChanged,
            ),
            if (submitError != null) ...[
              const SizedBox(height: 8),
              Text(
                submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mustard,
                foregroundColor: AppColors.espresso,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.publish_rounded, size: 19),
              label: Text(
                submitting ? 'Publicando…' : 'Publicar artículo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
