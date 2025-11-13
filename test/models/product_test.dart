import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/product.dart';

void main() {
  group('Product Model', () {
    test('fromJson creates Product correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Product',
        'description': 'Test Description',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final product = Product.fromJson(json);

      expect(product.id, 'test-id');
      expect(product.name, 'Test Product');
      expect(product.description, 'Test Description');
      expect(product.isActive, true);
    });

    test('toJson converts Product correctly', () {
      final product = Product(
        id: 'test-id',
        name: 'Test Product',
        description: 'Test Description',
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = product.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Product');
      expect(json['description'], 'Test Description');
      expect(json['is_active'], true);
    });

    test('copyWith creates new instance with updated fields', () {
      final product = Product(
        id: 'test-id',
        name: 'Test Product',
        description: 'Test Description',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = product.copyWith(name: 'Updated Product', isActive: false);

      expect(updated.id, product.id);
      expect(updated.name, 'Updated Product');
      expect(updated.isActive, false);
      expect(updated.description, product.description);
    });
  });
}
