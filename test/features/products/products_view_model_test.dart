import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/products/view_models/products_view_model.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/models/product.dart';
import 'package:app/core/utils/result.dart';

@GenerateMocks([ProductRepository])
import 'products_view_model_test.mocks.dart';

void main() {
  late MockProductRepository mockRepository;
  late ProductsViewModel viewModel;

  setUp(() {
    mockRepository = MockProductRepository();
    when(mockRepository.watchProducts()).thenAnswer((_) => Stream.value([]));
    viewModel = ProductsViewModel(mockRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('ProductsViewModel', () {
    final testProduct = Product(
      id: 'test-id',
      name: 'Test Product',
      description: 'Test Description',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('loadProducts updates products list on success', () async {
      when(mockRepository.getProducts()).thenAnswer(
        (_) async => Success([testProduct]),
      );

      await viewModel.loadProducts();

      expect(viewModel.products.length, 1);
      expect(viewModel.products.first.name, 'Test Product');
      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
    });

    test('createProduct returns true on success', () async {
      when(mockRepository.createProduct(any)).thenAnswer(
        (_) async => Success(testProduct),
      );

      final result = await viewModel.createProduct(testProduct);

      expect(result, true);
      verify(mockRepository.createProduct(testProduct)).called(1);
    });

    test('updateProduct performs optimistic update', () async {
      when(mockRepository.getProducts()).thenAnswer(
        (_) async => Success([testProduct]),
      );
      await viewModel.loadProducts();

      final updatedProduct = testProduct.copyWith(name: 'Updated Product');
      when(mockRepository.updateProduct(any)).thenAnswer(
        (_) async => Success(updatedProduct),
      );

      final result = await viewModel.updateProduct(updatedProduct);

      expect(result, true);
      verify(mockRepository.updateProduct(updatedProduct)).called(1);
    });

    test('activeProducts returns only active products', () async {
      final products = [
        testProduct.copyWith(id: '1', isActive: true),
        testProduct.copyWith(id: '2', isActive: false),
        testProduct.copyWith(id: '3', isActive: true),
      ];

      when(mockRepository.getProducts()).thenAnswer(
        (_) async => Success(products),
      );

      await viewModel.loadProducts();

      expect(viewModel.activeProducts.length, 2);
      expect(viewModel.activeProducts.every((p) => p.isActive), true);
    });
  });
}
