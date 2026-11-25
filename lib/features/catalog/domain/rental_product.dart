import 'package:flutter/material.dart';

enum RentalCategory {
  all('Todo', Icons.grid_view_rounded),
  party('Fiestas y eventos', Icons.celebration_outlined),
  construction('Construcción', Icons.construction_outlined),
  plumbing('Plomería', Icons.plumbing_outlined),
  gardening('Jardinería', Icons.yard_outlined),
  audio('Audio y video', Icons.speaker_outlined),
  tools('Herramientas', Icons.handyman_outlined);

  const RentalCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class RentalProduct {
  const RentalProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.location,
    required this.rating,
    required this.imageUrl,
    required this.imageIcon,
    this.isPopular = false,
    this.description = '',
    this.deposit = 0,
    this.condition = 'Buen estado',
    this.isAvailable = true,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final RentalCategory category;
  final double pricePerDay;
  final String location;
  final double rating;
  final String imageUrl;
  final IconData imageIcon;
  final bool isPopular;
  final String description;
  final double deposit;
  final String condition;
  final bool isAvailable;
  final List<String> imageUrls;

  List<String> get gallery => imageUrls.isNotEmpty
      ? imageUrls
      : (imageUrl.isNotEmpty ? [imageUrl] : const []);

  factory RentalProduct.fromJson(Map<String, dynamic> json) {
    final categoryName = (json['category'] as String? ?? '').toLowerCase();
    final category = switch (categoryName) {
      'party' || 'fiestas' || 'eventos' => RentalCategory.party,
      'construction' ||
      'construccion' ||
      'construcción' => RentalCategory.construction,
      'plumbing' || 'plomeria' || 'plomería' => RentalCategory.plumbing,
      'gardening' || 'jardineria' || 'jardinería' => RentalCategory.gardening,
      'audio' || 'audio_video' => RentalCategory.audio,
      'tools' || 'herramientas' => RentalCategory.tools,
      _ => RentalCategory.all,
    };
    final id = json['id'];
    final price = json['price_per_day'];
    final rating = json['rating'];
    final deposit = json['deposit'];
    final rawUrls = json['image_urls'];
    final parsedUrls = rawUrls is List
        ? rawUrls.whereType<String>().where((u) => u.isNotEmpty).toList()
        : const <String>[];
    final coverUrl = json['image_url'] as String? ??
        (parsedUrls.isNotEmpty ? parsedUrls.first : '');
    return RentalProduct(
      id: id.toString(),
      name: json['name'] as String? ?? 'Artículo en renta',
      category: category,
      pricePerDay: price is num ? price.toDouble() : 0,
      location: json['location'] as String? ?? 'Ubicación por confirmar',
      rating: rating is num ? rating.toDouble() : 0,
      imageUrl: coverUrl,
      imageIcon: category.icon,
      isPopular: json['is_popular'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      deposit: deposit is num ? deposit.toDouble() : 0,
      condition: json['condition'] as String? ?? 'Buen estado',
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrls: parsedUrls,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'price_per_day': pricePerDay,
    'location': location,
    'rating': rating,
    'image_url': imageUrl,
    'image_urls': gallery,
    'is_popular': isPopular,
    'description': description,
    'deposit': deposit,
    'condition': condition,
    'is_available': isAvailable,
  };
}
