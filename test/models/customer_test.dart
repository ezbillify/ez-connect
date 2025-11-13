import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/customer.dart';

void main() {
  group('Customer Model', () {
    test('fromJson creates Customer correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'product_id': 'product-id',
        'status': 'lead',
        'acquisition_source': 'Website',
        'owner': 'Jane Smith',
        'is_archived': false,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final customer = Customer.fromJson(json);

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.email, 'john@example.com');
      expect(customer.phone, '+1234567890');
      expect(customer.status, 'lead');
      expect(customer.isArchived, false);
    });

    test('toJson converts Customer correctly', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        productId: 'product-id',
        status: 'lead',
        acquisitionSource: 'Website',
        owner: 'Jane Smith',
        isArchived: false,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = customer.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['status'], 'lead');
      expect(json['is_archived'], false);
    });

    test('copyWith creates new instance with updated fields', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        email: 'john@example.com',
        status: 'lead',
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated =
          customer.copyWith(status: 'qualified', email: 'newemail@example.com');

      expect(updated.id, customer.id);
      expect(updated.name, customer.name);
      expect(updated.status, 'qualified');
      expect(updated.email, 'newemail@example.com');
    });
  });
}
