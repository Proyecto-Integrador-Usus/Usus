import '../domain/rental_product.dart';

/// Contrato del catálogo. La implementación de demo se puede sustituir por un
/// cliente REST sin acoplar la interfaz al backend ni a la base de datos.
abstract interface class CatalogRepository {
  Future<List<RentalProduct>> getProducts();
}
