import 'package:flutter/material.dart';
import '../../../models/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: product.isActive ? Colors.green : Colors.grey,
          child: Icon(
            Icons.inventory_2,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          product.description.isEmpty
              ? 'No description'
              : product.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(
            product.isActive ? 'Active' : 'Inactive',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: product.isActive ? Colors.green[100] : Colors.grey[300],
          labelStyle: TextStyle(
            color: product.isActive ? Colors.green[900] : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
