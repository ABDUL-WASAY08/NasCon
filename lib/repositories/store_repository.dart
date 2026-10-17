import '../models/product.dart';
import 'repository_types.dart';

/// Club store catalogue.
abstract interface class StoreRepository {
  Future<Cached<List<Product>>> products({
    String? category,
    String? query,
    bool forceRefresh = false,
  });

  Future<Cached<Product>> product(String productId);

  /// Distinct categories the backend advertises, for the filter row.
  Future<List<String>> categories();
}
