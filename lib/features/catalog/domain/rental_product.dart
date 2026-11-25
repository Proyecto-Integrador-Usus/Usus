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
    return RentalProduct(
      id: id.toString(),
      name: json['name'] as String? ?? 'Artículo en renta',
      category: category,
      pricePerDay: price is num ? price.toDouble() : 0,
      location: json['location'] as String? ?? 'Ubicación por confirmar',
      rating: rating is num ? rating.toDouble() : 0,
      imageUrl: json['image_url'] as String? ?? '',
      imageIcon: category.icon,
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }
}
