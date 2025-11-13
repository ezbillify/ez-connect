import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/products/widgets/product_list_item.dart';
import 'package:app/models/product.dart';

void main() {
  group('ProductListItem Widget', () {
    final testProduct = Product(
      id: 'test-id',
      name: 'Test Product',
      description: 'Test Description',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('displays product information correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductListItem(
              product: testProduct,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('shows inactive status for inactive products', (tester) async {
      final inactiveProduct = testProduct.copyWith(isActive: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductListItem(
              product: inactiveProduct,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('handles empty description', (tester) async {
      final productWithoutDescription = testProduct.copyWith(description: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductListItem(
              product: productWithoutDescription,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('No description'), findsOneWidget);
    });
  });
}
