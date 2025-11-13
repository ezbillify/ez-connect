import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crm_app/repositories/product_repository.dart';
import 'package:crm_app/models/product.dart';
import 'package:crm_app/core/errors/app_error.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'product_repository_test.mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late ProductRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = ProductRepository(client: mockClient);
  });

  group('ProductRepository', () {
    final testProduct = Product(
      id: 'test-id',
      name: 'Test Product',
      description: 'Test Description',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('getProducts returns list of products on success', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      final mockFilter = MockPostgrestFilterBuilder();
      
      when(mockClient.from('products')).thenReturn(mockQuery);
      when(mockQuery.select()).thenReturn(mockFilter);
      when(mockFilter.order('created_at', ascending: false)).thenAnswer(
        (_) async => [testProduct.toJson()],
      );

      final result = await repository.getProducts();

      expect(result.isSuccess, true);
      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.length, 1);
      expect(result.dataOrNull!.first.name, 'Test Product');
    });

    test('getProducts returns error on failure', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      
      when(mockClient.from('products')).thenReturn(mockQuery);
      when(mockQuery.select()).thenThrow(Exception('Database error'));

      final result = await repository.getProducts();

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<DatabaseError>());
    });

    test('createProduct validates max active products', () async {
      final activeProduct = testProduct.copyWith(isActive: true);
      
      final mockQuery = MockSupabaseQueryBuilder();
      final mockFilter = MockPostgrestFilterBuilder();
      
      when(mockClient.from('products')).thenReturn(mockQuery);
      when(mockQuery.select('id', any)).thenReturn(mockFilter);
      when(mockFilter.eq('is_active', true)).thenAnswer(
        (_) async => MockPostgrestResponse(count: 3),
      );

      final result = await repository.createProduct(activeProduct);

      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<MaxProductsError>());
    });
  });
}

class MockPostgrestResponse {
  final int count;
  MockPostgrestResponse({required this.count});
}
