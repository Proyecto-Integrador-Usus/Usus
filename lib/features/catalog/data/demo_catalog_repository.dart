import 'package:flutter/material.dart';

import '../domain/rental_product.dart';
import 'catalog_repository.dart';

class DemoCatalogRepository implements CatalogRepository {
  @override
  Future<List<RentalProduct>> getProducts() async => demoProducts;
}

const demoProducts = <RentalProduct>[
  RentalProduct(
    id: 'p-001',
    name: 'Taladro percutor profesional',
    category: RentalCategory.construction,
    pricePerDay: 180,
    location: 'Roma Norte, CDMX',
    rating: 4.9,
    imageUrl: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.handyman_rounded,
    isPopular: true,
  ),
  RentalProduct(
    id: 'p-002',
    name: 'Carpa para evento · 6 × 3 m',
    category: RentalCategory.party,
    pricePerDay: 850,
    location: 'Del Valle, CDMX',
    rating: 5.0,
    imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.celebration_rounded,
    isPopular: true,
  ),
  RentalProduct(
    id: 'p-003',
    name: 'Hidrolavadora de alta presión',
    category: RentalCategory.plumbing,
    pricePerDay: 320,
    location: 'Coyoacán, CDMX',
    rating: 4.8,
    imageUrl: 'https://images.unsplash.com/photo-1607400201515-c2c41c07d307?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.water_drop_rounded,
  ),
  RentalProduct(
    id: 'p-004',
    name: 'Bocina amplificada con micrófono',
    category: RentalCategory.audio,
    pricePerDay: 490,
    location: 'Narvarte, CDMX',
    rating: 4.9,
    imageUrl: 'https://images.unsplash.com/photo-1593078166034-9e3b6b8a7c35?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.speaker_rounded,
  ),
  RentalProduct(
    id: 'p-005',
    name: 'Rotomartillo SDS Plus',
    category: RentalCategory.construction,
    pricePerDay: 240,
    location: 'Condesa, CDMX',
    rating: 4.7,
    imageUrl: 'https://images.unsplash.com/photo-1581147036324-c1c89c2c8a4d?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.construction_rounded,
  ),
  RentalProduct(
    id: 'p-006',
    name: 'Juego de mesas y sillas (10 personas)',
    category: RentalCategory.party,
    pricePerDay: 560,
    location: 'Escandón, CDMX',
    rating: 4.8,
    imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.chair_alt_rounded,
  ),
  RentalProduct(
    id: 'p-007',
    name: 'Desbrozadora para jardín',
    category: RentalCategory.gardening,
    pricePerDay: 390,
    location: 'San Ángel, CDMX',
    rating: 4.6,
    imageUrl: 'https://images.unsplash.com/photo-1599685315640-7ec6f22d4a5b?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.yard_rounded,
  ),
  RentalProduct(
    id: 'p-008',
    name: 'Escalera de extensión de 7 m',
    category: RentalCategory.tools,
    pricePerDay: 210,
    location: 'Portales, CDMX',
    rating: 4.9,
    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=900&q=80',
    imageIcon: Icons.hardware_rounded,
  ),
];
