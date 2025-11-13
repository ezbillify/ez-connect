import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:app/features/products/screens/products_list_screen.dart';
import 'package:app/features/products/view_models/products_view_model.dart';
import 'package:app/models/product.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/core/utils/result.dart';

@GenerateMocks([ProductRepository])
import 'products_list_screen_golden_test.mocks.dart';

void main() {
  group('ProductsListScreen Golden Tests', () {
    late MockProductRepository mockRepository;

    setUp(() {
      mockRepository = MockProductRepository();
      when(mockRepository.watchProducts()).thenAnswer((_) => Stream.value([]));
    });

    testGoldens('shows empty state', (tester) async {
      when(mockRepository.getProducts()).thenAnswer(
        (_) async => const Success([]),
      );

      final viewModel = ProductsViewModel(mockRepository);

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const ProductsListScreen(),
        ),
        surfaceSize: const Size(400, 600),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'products_list_empty');

      viewModel.dispose();
    });

    testGoldens('shows product list', (tester) async {
      final products = [
        Product(
          id: '1',
          name: 'Product 1',
          description: 'Description 1',
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Product(
          id: '2',
          name: 'Product 2',
          description: 'Description 2',
          isActive: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      when(mockRepository.getProducts()).thenAnswer(
        (_) async => Success(products),
      );

      final viewModel = ProductsViewModel(mockRepository);

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const ProductsListScreen(),
        ),
        surfaceSize: const Size(400, 600),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'products_list_with_items');

      viewModel.dispose();
    });
  });
}
