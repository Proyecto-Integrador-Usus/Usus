import 'dart:convert';

import '../domain/rental_product.dart';
import 'catalog_repository.dart';

/// The transport stays injectable so the app can use `http`, Dio, or another
/// platform-aware HTTP client without making the UI depend on that package.
typedef JsonGet = Future<Object?> Function(Uri uri);
typedef JsonPost = Future<Object?> Function(
  Uri uri,
  Map<String, dynamic> body,
);

class RestCatalogRepository implements CatalogRepository {
  RestCatalogRepository({
    required this.baseUrl,
    required this.getJson,
    this.postJson,
  });

  final String baseUrl;
  final JsonGet getJson;
  final JsonPost? postJson;

  @override
  Future<List<RentalProduct>> getProducts() async {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await getJson(Uri.parse('$normalizedBaseUrl/products'));
    final decoded = response is String ? jsonDecode(response) : response;
    final items = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
        ? decoded['items']
        : null;
    if (items is! List) {
      throw const FormatException(
        'La API debe devolver una lista o un objeto con la propiedad "items".',
      );
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(RentalProduct.fromJson)
        .toList(growable: false);
  }

  @override
  Future<RentalProduct> addProduct(RentalProduct product) async {
    final post = postJson;
    if (post == null) {
      throw UnimplementedError(
        'Configura postJson para publicar artículos en la API REST.',
      );
    }
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await post(
      Uri.parse('$normalizedBaseUrl/products'),
      product.toJson(),
    );
    final decoded = response is String ? jsonDecode(response) : response;
    if (decoded is Map<String, dynamic>) {
      return RentalProduct.fromJson(decoded);
    }
    return product;
  }
}
